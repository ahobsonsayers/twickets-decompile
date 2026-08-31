#!/usr/bin/env bash
# 01-download.sh — Download the Twickets APK via gplaydl
set -euo pipefail

PACKAGE="co.twickets.droid"
APK_NAME="twickets"
OUT_DIR="${1:-apk}"

if [ -z "${GPLAYDL_CONFIG:-}" ]; then
  echo "ERROR: GPLAYDL_CONFIG is not set. See README." >&2
  exit 1
fi

CONFIG_FILE="$HOME/.config/gplaydl/config.json"
mkdir -p "$(dirname "$CONFIG_FILE")"
cat >"$CONFIG_FILE" <<EOF
$GPLAYDL_CONFIG
EOF
chmod 600 "$CONFIG_FILE"

mkdir -p "$OUT_DIR"

# Dispenser may be rate-limited; retry with backoff.
for attempt in 1 2 3 4 5; do
  if gplaydl download "$PACKAGE" --no-splits --no-extras -o "$OUT_DIR"; then
    break
  fi
  echo "gplaydl download failed (attempt $attempt/5); waiting 30s" >&2
  sleep 30
done

apks=("$OUT_DIR"/"$PACKAGE"-*.apk)
if [ ! -e "${apks[0]}" ]; then
  echo "ERROR: no APK downloaded after 5 attempts" >&2
  exit 1
fi
mv "${apks[0]}" "$OUT_DIR/$APK_NAME.apk"
echo "Downloaded: $OUT_DIR/$APK_NAME.apk"