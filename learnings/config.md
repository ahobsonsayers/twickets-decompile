# Config Reference

All values are embedded in the decompiled APK. Run `task extract` (from the repo
root) to obtain them — no values are listed here. The placeholder names refer to
the fields in that output (`api_key`, `user_agent`, `site_key`).

## Static keys

| Placeholder | Where it lives in the APK | Sent as |
|---|---|---|
| `api_key` | `co/twickets/droid/networking/interceptor/ApiKeyInterceptor.java` (`API_KEY_HEADER`) | Header `api_key` (v3.19+; older docs incorrectly say query param) |
| `user_agent` | `co/twickets/droid/networking/interceptor/UseAgentInterceptor.java` | Header `User-Agent` — `Twickets/<version> (Android/<os>)`, OS digits from `Build.VERSION.RELEASE` at runtime |
| `site_key` | Obfuscated Prosopo guard class (search sources for `x-prosopo-site-key`) | Header `x-prosopo-site-key` |

The obfuscated class name (`w50/h.java` in v3.19) changes between releases — the
extractor greps for the header literal, not the class name.

## Dynamic keys (NOT extractable statically)

| Placeholder | Source | Notes |
|---|---|---|
| `integrity_token` | Play Integrity verdict wrapped in a JWE by Twickets' backend | Ephemeral per app launch, expires, stored in SharedPreferences `prosopo_protect/integrity_token` (~24h TTL). See [prosopo-protection.md](prosopo-protection.md) |

Live extraction of this token requires a rooted emulator with Play Integrity
bypasses — see the [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)
repo.

## Base URLs

| Service | URL |
|---|---|
| Main API | `https://www.twickets.live/services/` |
| Prosopo guard | `https://protect.twickets.live` |
| Support site | `https://support.twickets.live` |