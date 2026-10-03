#!/usr/bin/env python3
"""Serve the Web build locally; keep the test server on loopback."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import functools

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=8060)
args = parser.parse_args()
folder = Path(__file__).resolve().parents[1] / "builds/web"
handler = functools.partial(SimpleHTTPRequestHandler, directory=str(folder))
print(f"Open http://127.0.0.1:{args.port}/index.html", flush=True)
ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
