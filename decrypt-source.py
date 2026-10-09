import os, pathlib, hashlib, tarfile, io, json
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
payload = pathlib.Path("source.enc").read_bytes()
raw = AESGCM(bytes.fromhex(os.environ["SOURCE_ARCHIVE_KEY"])).decrypt(payload[:12], payload[12:], b"config-reviewer-source-v1")
if hashlib.sha256(raw).hexdigest() != os.environ["SOURCE_ARCHIVE_SHA256"]:
    raise SystemExit("Source checksum mismatch")
pathlib.Path("project").mkdir()
with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
    source_commit = archive.pax_headers.get("comment", "unknown")
    archive.extractall("project", filter="data")
pathlib.Path("project/.build-source.json").write_text(json.dumps({"source_commit": source_commit, "source_archive_sha256": hashlib.sha256(raw).hexdigest()}))
print("Encrypted source verified and extracted")
