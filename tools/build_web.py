#!/usr/bin/env python3
"""Export the single-threaded Web preset and package an itch.io-ready ZIP."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
default_binary = shutil.which("godot") or shutil.which("godot4") or str(Path.home() / "Downloads/Godot_v4.7.2-stable_linux.x86_64")
parser = argparse.ArgumentParser()
parser.add_argument("--godot", default=os.environ.get("GODOT_BINARY", default_binary))
args = parser.parse_args()
output = root / "builds/web"
output.mkdir(parents=True, exist_ok=True)
(output.parent / ".gdignore").touch()
environment = dict(os.environ, XDG_CONFIG_HOME=str(output.parent / "godot-config"), XDG_DATA_HOME=str(output.parent / "godot-data"))
subprocess.run([args.godot, "--headless", "--path", str(root), "--export-release", "Web", str(output / "index.html"), "--log-file", str(output.parent / "export.log")], env=environment, check=True)
shutil.copyfile(root / "CREDITS.md", output / "CREDITS.md")
shutil.copyfile(root / "Assets/fonts/Caveat-OFL.txt", output / "Caveat-OFL.txt")
shutil.copyfile(root / "Assets/fonts/DejaVu-LICENSE.txt", output / "DejaVu-LICENSE.txt")
archive = output.parent / "the-right-angle-web.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
    for file in sorted(output.iterdir()):
        if file.is_file() and not file.name.endswith(".import"):
            bundle.write(file, file.name)
with zipfile.ZipFile(archive) as bundle:
    assert bundle.testzip() is None
    assert "index.html" in bundle.namelist()
print(f"Upload {archive} ({archive.stat().st_size / 1024 / 1024:.1f} MiB)")
