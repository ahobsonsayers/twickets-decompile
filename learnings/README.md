# Twickets API Documentation

Reverse-engineered from the Twickets Android app (`co.twickets.droid`, v3.19 /
versionCode 182) via APK decompilation, plus live HTTP verification against the
real backend.

## Sections

- [Config](config.md) — where each key lives in the APK, header formats, base URLs
- [Authentication](keys.md) — the three static keys + the dynamic JWE integrity token
- [Catalogue](catalogue.md) — ticket search endpoints (legacy `catalogue` and `g2/catalogue`)
- [Prosopo Protection](prosopo-protection.md) — bot-guard flow, session cookie, Play Integrity
- [Rate Limiting](rate-limiting.md) — bot detection, error handling

## Quick reference

**Base URL:** `https://www.twickets.live/services/` (see [config.md](config.md) for all URLs)

**Auth model:** no user accounts — requests are authorised by the three static
keys in [config.md](config.md) (`api_key` header, `User-Agent` header,
`x-prosopo-site-key` header). Most catalogue requests additionally require a
fresh `x-prosopo-android-integrity-token` JWE minted by the app at launch.

## Status legend

Note: fields marked in each doc as confirmed = verified with a live HTTP request
in v3.19. Source = found in decompiled Java, params inferred, not confirmed live.