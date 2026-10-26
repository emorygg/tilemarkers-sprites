"""Package this fork's runtime only; RSprite and PrettyUI remain external dependencies."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib

root = Path(__file__).resolve().parents[1]
destination = root / "dist/tilemarkers-sprites-dev.zip"
destination.parent.mkdir(exist_ok=True)
files = sorted((root / "src").rglob("*.lua"))
files += [root / name for name in ("main.lua", "plugin.json", "LICENSE", "README.md", "FORK.md")]
with ZipFile(destination, "w", ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, "tilemarkers-sprites/" + path.relative_to(root).as_posix())
print(destination)
print(f"{len(files)} files; SHA-256 {hashlib.sha256(destination.read_bytes()).hexdigest()}")
