#!/usr/bin/env bash
# End-to-end local update pipeline (no device): build APK, serve manifest, verify download + SHA.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Building release APK (1.0.0+1)"
flutter build apk --release --dart-define=UPDATE_BASE_URL=http://127.0.0.1:8765

APK="build/app/outputs/flutter-apk/app-release.apk"
PORT="${PORT:-8765}"
python3 tool/local_update_server.py "$APK" --version-name 1.0.1 --version-code 2 --port "$PORT" &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  if curl -sf "http://127.0.0.1:$PORT/linkvault-update.json" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "==> Fetching manifest"
MANIFEST=$(curl -sf "http://127.0.0.1:$PORT/linkvault-update.json")
echo "$MANIFEST" | grep -q '"versionName": "1.0.1"'
echo "$MANIFEST" | grep -q '"versionCode": 2'

APK_NAME=$(echo "$MANIFEST" | python3 -c "import sys,json; print(json.load(sys.stdin)['apkFileName'])")
SHA_EXPECTED=$(echo "$MANIFEST" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha256'])")

echo "==> Downloading $APK_NAME"
curl -sf "http://127.0.0.1:$PORT/$APK_NAME" -o /tmp/linkvault-test.apk
SHA_ACTUAL=$(shasum -a 256 /tmp/linkvault-test.apk | awk '{print $1}')
test "$SHA_EXPECTED" = "$SHA_ACTUAL"

echo "Local update server test OK"
