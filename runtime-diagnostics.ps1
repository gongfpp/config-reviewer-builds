$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force C:/ReviewerRuntime/diagnostics | Out-Null
Start-Transcript C:/ReviewerRuntime/diagnostics/runtime.log
$profiles=@(Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultOutboundAction)
$allow=@(Get-NetFirewallRule -Direction Outbound -Enabled True -Action Allow | Select-Object -ExpandProperty Name)
$agent=@(Get-Process | Where-Object {$_.ProcessName -in @('Runner.Worker','Runner.Listener')} | ForEach-Object {$_.Path} | Select-Object -Unique)
function Probe([string]$label) {
  $env:PATH="$env:WINDIR\System32;$env:WINDIR"
  $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS='--remote-debugging-port=9222'
  $env:WEBVIEW2_USER_DATA_FOLDER="C:/ReviewerRuntime/profile-$label"
  $p=Start-Process C:/ReviewerRuntime/config-reviewer.exe -PassThru -RedirectStandardOutput "C:/ReviewerRuntime/diagnostics/$label-out.txt" -RedirectStandardError "C:/ReviewerRuntime/diagnostics/$label-error.txt"
  try {
    for ($i=0;$i -lt 40;$i++) {
      try { Invoke-WebRequest http://127.0.0.1:9222/json/version -UseBasicParsing -TimeoutSec 1 | Select-Object -ExpandProperty Content | Set-Content "C:/ReviewerRuntime/diagnostics/$label-cdp.json"; Write-Output "$label CDP PASSED"; return }
      catch { Start-Sleep -Milliseconds 500 }
    }
    $p.Refresh(); Write-Output "$label exit=$($p.ExitCode) exited=$($p.HasExited)"
    Get-Process | Where-Object {$_.ProcessName -match 'reviewer|webview'} | Format-Table Id,ProcessName,Path | Out-String | Set-Content "C:/ReviewerRuntime/diagnostics/$label-processes.txt"
    Get-NetTCPConnection -State Listen | Where-Object {$_.LocalPort -eq 9222} | Format-List | Out-String | Set-Content "C:/ReviewerRuntime/diagnostics/$label-listeners.txt"
  } finally { taskkill /pid $p.Id /T /F | Out-Null }
}
try {
  $setup=Get-ChildItem "${env:ProgramFiles(x86)}/Microsoft/EdgeWebView/Application/*/Installer/setup.exe" | Select-Object -First 1
  $p=Start-Process $setup.FullName -ArgumentList '--uninstall --msedgewebview --system-level --force-uninstall --verbose-logging' -Wait -PassThru
  if ($p.ExitCode -notin @(0,19)) { throw 'Runtime removal failed' }
  foreach ($n in $allow) { Disable-NetFirewallRule -Name $n | Out-Null }
  $i=0;foreach ($a in $agent) { New-NetFirewallRule -Name ("RuntimeAgent-"+$i++) -DisplayName RuntimeAgent -Direction Outbound -Action Allow -Program $a -Profile Any | Out-Null }
  Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -DefaultOutboundAction Block
  $p=Start-Process C:/ReviewerRuntime/WebView2.exe -ArgumentList '/silent /install' -Wait -PassThru
  Write-Output "Offline runtime installer exit=$($p.ExitCode)"
  Get-ItemProperty 'HKLM:/SOFTWARE/WOW6432Node/Microsoft/EdgeUpdate/Clients/{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' | Format-List | Out-String | Set-Content C:/ReviewerRuntime/diagnostics/runtime-registry.txt
  Probe 'blocked'
  New-NetFirewallRule -Name RuntimeLoopback -DisplayName RuntimeLoopback -Direction Outbound -Action Allow -RemoteAddress '127.0.0.1','::1' -Profile Any | Out-Null
  Probe 'explicit-loopback'
} finally {
  foreach ($p in $profiles) { Set-NetFirewallProfile -Profile $p.Name -Enabled $p.Enabled -DefaultOutboundAction $p.DefaultOutboundAction }
  foreach ($n in $allow) { Enable-NetFirewallRule -Name $n | Out-Null }
  Get-NetFirewallRule -Name 'RuntimeAgent-*','RuntimeLoopback' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
  Stop-Transcript
}
