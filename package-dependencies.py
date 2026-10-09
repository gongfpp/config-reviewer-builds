"""Publish only third-party dependencies and config, never the private app source."""
import json, pathlib, subprocess, hashlib, zipfile
root=pathlib.Path.cwd();out=root/'artifacts';out.mkdir(exist_ok=True)
version=json.loads((root/'package.json').read_text())['version']
info={'source_commit':json.loads((root/'.build-source.json').read_text())['source_commit'], 'node':subprocess.check_output(['node','--version'],text=True).strip(), 'rust':subprocess.check_output(['rustc','--version'],text=True).strip(), 'platform':'Windows x64', 'includes':['Windows npm cache','Cargo vendored sources','.cargo source replacement'], 'toolchains_included':False, 'offline_build_verified':True, 'direct_exe_ui':json.loads((root/'artifacts/ui-smoke/result.json').read_text()), 'no_installer_generated':True}
(root/'DEPENDENCY-INFO.json').write_text(json.dumps(info,ensure_ascii=False,indent=2))
paths=[p for p in (root/'.offline').rglob('*') if p.is_file()]
paths += [root/'.cargo/config.toml',root/'DEPENDENCY-INFO.json']
archive=out/f'ConfigReviewer-{version}-windows-x64-dependencies.zip'
hashes=[]
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6,strict_timestamps=False) as z:
 for p in sorted(paths):
  name=p.relative_to(root).as_posix();digest=hashlib.file_digest(p.open('rb'),'sha256').hexdigest();hashes.append(f'{digest}  {name}');z.write(p,name)
 z.writestr('DEPENDENCY-SHA256SUMS.txt','\n'.join(hashes)+'\n')
print('Dependency pack bytes:',archive.stat().st_size,'files:',len(paths))
