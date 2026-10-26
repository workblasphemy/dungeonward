"""Install only the approved official Godot build, with pinned SHA-512 verification."""
import hashlib
from pathlib import Path
import platform
import urllib.request
import zipfile

ASSETS = {
    "Linux": ("Godot_v4.7.2-stable_linux.x86_64.zip", "9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"),
    "Windows": ("Godot_v4.7.2-stable_win64.exe.zip", "83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993"),
}
if platform.machine().lower() not in ("x86_64", "amd64"):
    raise SystemExit("Only x86_64 runners are supported")
asset, checksum = ASSETS[platform.system()]
target = Path(__file__).resolve().parent.parent / ".tools" / "godot-4.7.2"
target.mkdir(parents=True, exist_ok=True)
archive = target / asset
urllib.request.urlretrieve("https://github.com/godotengine/godot/releases/download/4.7.2-stable/" + asset, archive)
if hashlib.sha512(archive.read_bytes()).hexdigest() != checksum:
    archive.unlink()
    raise SystemExit("Godot checksum mismatch; refusing extraction")
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall(target)
binary = target / asset.removesuffix(".zip")
if platform.system() == "Linux":
    binary.chmod(0o755)
print(binary)
