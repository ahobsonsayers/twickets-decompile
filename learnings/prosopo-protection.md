# Prosopo Bot Protection (v3.19)

Twickets ships a Prosopo (protect.twickets.live) guard plus a custom Android
integrity layer. Decompiled from `w50/a.java`, `w50/i.java`, `w50/h.java`.

## High-level flow (observed in bytecode)

```
app launch                          ┌──────────────────────────────┐
        │                           │ play integrity verdict (JWE) │
        ▼                           └──────────────┬───────────────┘
POST https://protect.twickets.live/api/protect/init
     body: {"visitor_id":"android-tmp-fp","sr":"android",
            "site_key":"<site_key>","d":"m"}
        │
        ▼
response: {"jti": "...", "jwt_token": "..."}
  → stored as session; sent as Cookie: prosopo_session=jti|jwt
  → integrity_token stored (~24h TTL check, 86400000 ms)
        │
        ▼
OkHttp interceptor (w50.i) attaches to every request:
  header x-prosopo-android-integrity-token: <JWE>
  header x-prosopo-site-key: <site_key>
  cookie prosopo_session=jti|jwt (when present)
  - waits up to 10s (CompletableFuture) on first request
```

## Details

- **Token refresh** — integrity token obtained with retry/backoff
  (100ms≪i capped at 1000ms, up to 5 attempts).
- **Quota exceeded** — on Play Integrity failure the app POSTs
  `/api/android/integrity-quota-exceeded` to protect.twickets.live.
- **Warm-up** — the JWE is not present on the very first request after launch;
  the interceptor waits (up to 10s) for it to appear.
- **Static site key** — `x-prosopo-site-key` is hardcoded (see
  [config.md](config.md)); extractable statically.

## What this means for API use

- The `x-prosopo-android-integrity-token` JWE **cannot be minted statically** —
  it requires running the app on a rooted emulator with Play Integrity bypasses.
- Catalogue replay captures from a live app work **without** the
  `prosopo_session` cookie; the JWE header is the gating item.
- Live extraction pipeline: see
  [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor).