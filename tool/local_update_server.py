#!/usr/bin/env python3
"""Serve a local linkvault-update.json + APK for on-device update testing.

Usage:
  python3 tool/local_update_server.py build/app/outputs/flutter-apk/app-release.apk

Then run the app with:
  flutter run --dart-define=UPDATE_BASE_URL=http://10.0.2.2:8765

For a physical device:
  adb reverse tcp:8765 tcp:8765
  flutter run --dart-define=UPDATE_BASE_URL=http://127.0.0.1:8765
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 8765
SERVE_DIR = Path(__file__).resolve().parent / ".local_update_serve"


def build_manifest(apk_path: Path, version_name: str, version_code: int) -> dict:
    data = apk_path.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    apk_name = f"linkvault-{version_name}.apk"
    dest = SERVE_DIR / apk_name
    SERVE_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(apk_path, dest)
    manifest = {
        "versionName": version_name,
        "versionCode": version_code,
        "apkFileName": apk_name,
        "sha256": sha,
        "publishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    (SERVE_DIR / "linkvault-update.json").write_text(
        json.dumps(manifest, indent=2) + "\n"
    )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path, help="APK file to serve as the update")
    parser.add_argument("--version-name", default="1.0.1")
    parser.add_argument("--version-code", type=int, default=2)
    parser.add_argument("--port", type=int, default=PORT)
    args = parser.parse_args()

    if not args.apk.is_file():
        print(f"APK not found: {args.apk}", file=sys.stderr)
        return 1

    manifest = build_manifest(args.apk, args.version_name, args.version_code)
    print(f"Serving on http://127.0.0.1:{args.port}/")
    print(json.dumps(manifest, indent=2))

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(SERVE_DIR), **kw)

    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
