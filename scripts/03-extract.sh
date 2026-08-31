#!/usr/bin/env bash
# 03-extract.sh — Extract the static API keys from decompiled sources
set -euo pipefail

SRC_DIR="${1:-decompiled/sources}"

api_key="$(find "$SRC_DIR" -name "ApiKeyInterceptor.java" \
  -exec grep -hoE '"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"' {} + 2>/dev/null \
  | cut -d '"' -f 2 | head -1)"

# UA literal is "Twickets/<version> (Android/" + Build.VERSION.RELEASE + ")";
# the runtime OS version is filled with a modern Android release.
ua_prefix="$(find "$SRC_DIR" -name "UseAgentInterceptor.java" \
  -exec grep -hoE '"Twickets/[0-9.]+ \(Android/' {} + 2>/dev/null \
  | head -1 | cut -d '"' -f 2)"
user_agent="${ua_prefix}16)"

# The Prosoco guard class is obfuscated; grep for the header literal itself.
site_key="$(grep -rhoE '"x-prosopo-site-key", "[^"]+"' "$SRC_DIR" 2>/dev/null \
  | head -1 | cut -d '"' -f 4)"

missing=""
[ -z "$api_key" ] && missing="$missing api_key"
[ -z "$user_agent" ] && missing="$missing user_agent"
[ -z "$site_key" ] && missing="$missing site_key"
if [ -n "$missing" ]; then
  echo "ERROR: not found in decompiled sources:$missing" >&2
  exit 1
fi

jq -n --arg api_key "$api_key" --arg user_agent "$user_agent" --arg site_key "$site_key" \
  '{api_key: $api_key, user_agent: $user_agent, site_key: $site_key}'