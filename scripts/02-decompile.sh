#!/usr/bin/env bash
# 02-decompile.sh — Decompile the Twickets APK with jadx (+ optional Hermes disasm)
set -euo pipefail

APK="${1:-apk/twickets.apk}"
OUT_DIR="${2:-decompiled}"

# jadx may error on obfuscated APKs; partial output is still usable.
jadx -d "$OUT_DIR" "$APK" >/dev/null 2>&1 || true

# Optional: disassemble the Hermes bytecode bundle if the tool is available.
BUNDLE="$OUT_DIR/resources/assets/index.android.bundle"
if [ -f "$BUNDLE" ] && command -v hbc-disassembler >/dev/null 2>&1; then
  hbc-disassembler "$BUNDLE" "$OUT_DIR/hermes.hasm" || true
fi

echo "Decompiled to: $OUT_DIR"