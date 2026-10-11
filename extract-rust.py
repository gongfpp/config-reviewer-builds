"""Merge the official standalone toolchain components; no rustup/network needed."""
import pathlib, shutil, tarfile
root = pathlib.Path.cwd()
with tarfile.open(root/'downloads/rust.tar.xz','r:xz') as archive:
    archive.extractall(root/'downloads/rust-extracted',filter='data')
bundle = next((root/'downloads/rust-extracted').iterdir())
target = root/'tools/rust'
target.mkdir(parents=True,exist_ok=True)
components = (bundle/'components').read_text().splitlines()
for component in components:
    if component.startswith(('rust-docs','rust-analysis','rust-src')):
        continue
    folder = bundle/component
    for entry in folder.iterdir():
        if entry.name == 'manifest.in':
            continue
        destination = target/entry.name
        if entry.is_dir():
            shutil.copytree(entry,destination,dirs_exist_ok=True)
        else:
            shutil.copy2(entry,destination)
for entry in bundle.iterdir():
    if entry.is_file():
        shutil.copy2(entry,target/entry.name)
for file in ['bin/rustc.exe','bin/cargo.exe','lib/rustlib/x86_64-pc-windows-msvc/lib']:
    assert (target/file).exists(),file
print('Standalone Rust components:',components)
