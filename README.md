# Twickets Reverse Engineering

Decompile the Twickets Android app, extract the static keys needed to use its
API, and document how that API works.

The repo has two parts:

1. **[Learnings](learnings/)** — reverse-engineered documentation of the Twickets
   API, built from decompiling the APK and live HTTP verification: keys and
   headers, catalogue endpoints, the Prosopo bot-protection flow, rate limiting.
2. **[Scripts](scripts/)** — a repeatable extraction pipeline. Downloads the APK,
   decompiles it, and pulls out the three static keys (`api_key`,
   `user_agent`, `site_key`) so you don't have to hard-code or guess them.

## Extracting keys

The Twickets app's `api_key`, `User-Agent` prefix, and Prosopo `site_key` are
embedded in the APK. Publishing them is a liability, so this repo extracts them
for you in one command — no local toolchain required.

### Docker (recommended) — no install

Works anywhere Docker runs. No local tools needed.

**1. Get a gplaydl key** (one-time, ~2 minutes)

The image downloads the APK via `gplaydl`, which needs a key linked to a Google
account:

1. Install the **gplaydl Authenticator** app on any Android phone from
   <https://dispenser.gplaydl.com>.
2. Sign in with a **spare Google account**, open **Link gplaydl**, and note the
   one-time pairing code.
3. On any machine with `uv`, link it:
   ```bash
   uv run gplaydl link    # enter the pairing code when prompted
   ```
   This writes `~/.config/gplaydl/config.json`.

> [!WARNING]
> Google may flag, lock, or restrict accounts used with unofficial clients.
> Use a separate account and continue at your own risk.

**2. Run the image** with `GPLAYDL_CONFIG` set to the contents of that file:

```bash
docker run --rm -e GPLAYDL_CONFIG="$(cat ~/.config/gplaydl/config.json)" \
  ghcr.io/ahobsonsayers/twickets-decompile:latest
```

Output:

```json
{
  "api_key": "00000000-0000-0000-0000-000000000000",
  "user_agent": "Twickets/3.19 (Android/16)",
  "site_key": "00000000"
}
```

### Local — you need the tools

Only choose this if you want to run the extraction on your own machine. Install
the toolchain:

```bash
brew install go-task jadx uv
```

Then set `GPLAYDL_CONFIG` in `.env` and run the pipeline:

```bash
task download    # download the APK via gplaydl
task decompile   # decompile with jadx
task extract     # extract the static keys
```

> [!NOTE]
> `task decompile` may finish with errors — this is normal for obfuscated Android
> APKs and the decompiled output is still usable.

Each step is also a standalone script in `scripts/` (`01-download.sh`,
`02-decompile.sh`, `03-extract.sh`) that you can run directly.

## Using the API

The three static keys are not enough on their own. Most catalogue requests
additionally require `x-prosopo-android-integrity-token` — an encrypted JWE
minted from a Play Integrity verdict each time the app launches, which cannot
be reproduced statically. Without it the API returns
`403 Android integrity verification failed`.

To get a live token you must run the app on a rooted emulator with Play
Integrity bypasses — the
[twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)
repo automates exactly that and outputs all four keys (`api_key`, `user_agent`,
`site_key`, `x-prosopo-android-integrity-token`). Use that repo for live API
access; use this repo for the API documentation and static key extraction.

See the [learnings](learnings/README.md) for full API documentation — auth
header quirks, endpoints, the Prosopo flow, and rate limiting.

## Contributing

Never commit any API keys, client IDs, tokens, or secrets to this repo. If you
accidentally commit one, tell the maintainers so it can be scrubbed from
history.