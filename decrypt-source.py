import os, pathlib, hashlib, tarfile, io
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
payload = pathlib.Path("source.enc").read_bytes()
raw = AESGCM(bytes.fromhex(os.environ["SOURCE_ARCHIVE_KEY"])).decrypt(payload[:12], payload[12:], b"config-reviewer-source-v1")
if hashlib.sha256(raw).hexdigest() != os.environ["SOURCE_ARCHIVE_SHA256"]:
    raise SystemExit("Source checksum mismatch")
pathlib.Path("project").mkdir()
with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
    archive.extractall("project", filter="data")
print("Encrypted source verified and extracted")
