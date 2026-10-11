import hashlib, pathlib, shutil, zipfile
root=pathlib.Path.cwd()
kit=pathlib.Path('C:/ReviewerKit')
shutil.move(root/'project',kit)
for folder,manifest in [('downloaded-tools','TOOLS-SHA256SUMS.txt'),('downloaded-deps','DEPENDENCY-SHA256SUMS.txt')]:
    source=next((root/folder).glob('*.zip'))
    with zipfile.ZipFile(source) as z:
        assert z.testzip() is None
        for line in z.read(manifest).decode('utf-8-sig').splitlines():
            expected,name=line.split('  ',1)
            with z.open(name) as stream:
                assert hashlib.file_digest(stream,'sha256').hexdigest()==expected,name
        for name in z.namelist():
            assert not name.startswith(('/','\\')) and '..' not in pathlib.PurePosixPath(name).parts
        z.extractall(kit)
    source.unlink()
print('Private source and verified third-party tools extracted to a short clean path.')
