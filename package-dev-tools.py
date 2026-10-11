import hashlib, pathlib, zipfile
root=pathlib.Path.cwd()
paths=sorted(p for p in (root/'tools').rglob('*') if p.is_file())
with zipfile.ZipFile(root/'ConfigReviewer-windows-x64-tools.zip','w',zipfile.ZIP_DEFLATED,compresslevel=1,strict_timestamps=False) as z:
    hashes=[]
    for p in paths:
        name=p.relative_to(root).as_posix()
        with p.open('rb') as stream:
            digest=hashlib.file_digest(stream,'sha256').hexdigest()
        hashes.append(f'{digest}  {name}')
        z.write(p,name)
    z.writestr('TOOLS-SHA256SUMS.txt','\n'.join(hashes)+'\n')
print('Tool archive bytes:',(root/'ConfigReviewer-windows-x64-tools.zip').stat().st_size,'files:',len(paths))
