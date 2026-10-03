#!/usr/bin/env python3
"""Fetch only the Web templates from the official, version-matched archive."""
import io
import pathlib
import urllib.request
import zipfile

VERSION = "4.7.2"
URL = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"
DEST = pathlib.Path(__file__).resolve().parents[1] / ".export-templates"


class RemoteZip(io.RawIOBase):
    def __init__(self):
        response = urllib.request.urlopen(urllib.request.Request(URL, method="HEAD"), timeout=60)
        self.url = response.url
        self.length = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.length) + offset
        return self.position

    def tell(self):
        return self.position

    def read(self, size=-1):
        size = min(self.length - self.position, size if size >= 0 else self.length)
        if size <= 0:
            return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{self.position + size - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError("Server ignored range request; refusing a full archive download")
            data = response.read()
        self.position += len(data)
        return data


if __name__ == "__main__":
    DEST.mkdir(exist_ok=True)
    (DEST / ".gdignore").touch()
    with zipfile.ZipFile(RemoteZip()) as archive:
        for name in ("web_nothreads_release.zip", "web_nothreads_debug.zip"):
            match = next(entry for entry in archive.namelist() if entry.endswith("/" + name))
            output = DEST / name
            output.write_bytes(archive.read(match))
            with zipfile.ZipFile(output) as template:
                template.testzip()
            print(f"Downloaded {name}: {output.stat().st_size / 1024 / 1024:.1f} MiB", flush=True)
