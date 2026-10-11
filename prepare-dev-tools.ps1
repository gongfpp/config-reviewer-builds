$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force downloads,tools,preparation-logs | Out-Null
Start-Transcript preparation-logs/download-and-layout.log
function Download([string]$Url,[string]$File) {
  & curl.exe --fail --location --retry 4 --output $File $Url
  if ($LASTEXITCODE -ne 0) { throw "Download failed: $Url" }
}
function Official-Hash([string]$File,[string]$Hash) {
  if ((Get-FileHash $File -Algorithm SHA256).Hash -ne $Hash) { throw "Checksum mismatch: $File" }
}
function Signed-Microsoft([string]$File) {
  $signature = Get-AuthenticodeSignature $File
  if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') { throw "Invalid Microsoft signature: $File" }
}
Download 'https://nodejs.org/dist/v22.23.3/node-v22.23.3-win-x64.zip' 'downloads/node.zip'
Download 'https://nodejs.org/dist/v22.23.3/SHASUMS256.txt' 'downloads/node-SHASUMS256.txt'
$nodeHash = ((Get-Content downloads/node-SHASUMS256.txt | Where-Object { $_ -match '  node-v22.23.3-win-x64.zip$' }) -split '\s+')[0]
if (-not $nodeHash) { throw 'Node official checksum missing' }
Official-Hash 'downloads/node.zip' $nodeHash
Expand-Archive downloads/node.zip downloads/node-extracted
Move-Item downloads/node-extracted/node-v22.23.3-win-x64 tools/node
$rustUrl = 'https://static.rust-lang.org/dist/rust-1.99.0-x86_64-pc-windows-msvc.tar.xz'
Download $rustUrl 'downloads/rust.tar.xz'
Download "$rustUrl.sha256" 'downloads/rust.sha256'
$rustHash = ((Get-Content downloads/rust.sha256) -split '\s+')[0]
Official-Hash 'downloads/rust.tar.xz' $rustHash
python extract-rust.py
if ($LASTEXITCODE -ne 0) { throw 'Cannot unpack standalone Rust' }
Download 'https://aka.ms/vs/17/release/vs_buildtools.exe' 'downloads/vs_buildtools.exe'
Signed-Microsoft downloads/vs_buildtools.exe
$layout = Join-Path $PWD 'tools/vs-layout'
$components = @('Microsoft.VisualStudio.Workload.VCTools','Microsoft.VisualStudio.Component.VC.Tools.x86.x64','Microsoft.VisualStudio.Component.Windows10SDK.19041')
$args = @('--layout',('"{0}"' -f $layout),'--lang','en-US','--quiet','--wait')
foreach ($component in $components) { $args += @('--add',$component) }
$process = Start-Process downloads/vs_buildtools.exe -ArgumentList $args -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "VS layout failed: $($process.ExitCode)" }
$verify = Start-Process downloads/vs_buildtools.exe -ArgumentList @('--layout',('"{0}"' -f $layout),'--verify','--quiet','--wait') -Wait -PassThru
if ($verify.ExitCode -ne 0) { throw "VS layout verification failed: $($verify.ExitCode)" }
New-Item -ItemType Directory -Force tools/installers | Out-Null
Download 'https://go.microsoft.com/fwlink/?linkid=2124701' 'tools/installers/MicrosoftEdgeWebView2RuntimeInstallerX64.exe'
Download 'https://go.microsoft.com/fwlink/?linkid=2088631' 'tools/installers/ndp48-x86-x64-allos-enu.exe'
Download 'https://aka.ms/vs/17/release/vc_redist.x64.exe' 'tools/installers/vc_redist.x64.exe'
foreach ($file in Get-ChildItem tools/installers/*.exe) { Signed-Microsoft $file.FullName }
Download 'https://update.code.visualstudio.com/latest/win32-x64-archive/stable' 'downloads/vscode.zip'
Expand-Archive downloads/vscode.zip tools/editor
New-Item -ItemType Directory -Force tools/editor/data/user-data/User | Out-Null
@{ 'update.mode'='none'; 'extensions.autoUpdate'=$false; 'extensions.autoCheckUpdates'=$false; 'telemetry.telemetryLevel'='off'; 'workbench.enableExperiments'=$false; 'window.restoreWindows'='none'; 'security.workspace.trust.enabled'=$true } | ConvertTo-Json | Set-Content tools/editor/data/user-data/User/settings.json -Encoding utf8
Signed-Microsoft tools/editor/Code.exe
$info = @{ node='22.23.3'; rust='1.99.0'; target='x86_64-pc-windows-msvc'; vs_components=$components; vs_layout_verified=$true; node_official_sha256=$nodeHash; rust_official_sha256=$rustHash; toolchains_included=$true; prepared_on='Windows Server 2022'; windows10_target_tested=$false; official_sources=@('https://nodejs.org/dist/v22.23.3/','https://static.rust-lang.org/dist/','https://aka.ms/vs/17/release/vs_buildtools.exe','https://developer.microsoft.com/en-us/microsoft-edge/webview2/','https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48','https://code.visualstudio.com/') }
$info | ConvertTo-Json -Depth 4 | Set-Content tools/TOOLS-INFO.json -Encoding utf8
Get-ChildItem "$env:TEMP/dd_*" -ErrorAction SilentlyContinue | Copy-Item -Destination preparation-logs -ErrorAction SilentlyContinue
Stop-Transcript
