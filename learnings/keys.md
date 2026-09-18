# Authentication & Keys

The Twickets Android API has no user login. Authorisation is a combination of
three static, app-embedded keys plus dynamic per-launch credentials. All
requests observed in the app send all of them. As of v3.20 there is also a
per-request hardware attestation signature (see
[prosopo-protection.md](prosopo-protection.md)).

## Static keys

Extractable from the APK (run `task extract` for current values):

| Key | HTTP location | Source |
|---|---|---|
| `api_key` | Header `api_key` | Hardcoded UUID in `ApiKeyInterceptor` (v3.19, unchanged v3.20). The current app sends it as a header on every request; but every verified working replay has used the **query param** instead (legacy `catalogue`, `media`) — see [catalogue.md](catalogue.md) |
| `user_agent` | Header `User-Agent` | `Twickets/<version> (Android/<os>)` built in `UseAgentInterceptor`; the OS digits come from `Build.VERSION.RELEASE` at runtime, so replaying `"/16)"` is fine |
| `site_key` | Header `x-prosopo-site-key` | Hardcoded in the obfuscated Prosopo guard class (see [config.md](config.md)) |

The media endpoint (`services/media/...`) additionally takes `api_key` as a
query param (see [catalogue.md](catalogue.md#media)).

Static keys alone are **not sufficient** for catalogue access — the Prosopo
guard rejects requests without a fresh integrity token (403). Both a stale
but format-valid JWE and a missing one return 403; only a young token (minutes
old at most) passes.

## Dynamic key: `x-prosopo-android-integrity-token`

- An encrypted JWE minted during app launch, derived from a Play Integrity
  verdict (as of v3.20, the verdict is submitted together with a nonce from
  `GET /api/android/integrity-nonce`).
- Stored in SharedPreferences under `prosopo_protect/integrity_token`; the app
  re-mints it every ~22h (79200000 ms loop timer in v3.20 `c60/f.java`; the
  validity check is still 24h / 86400000 ms). **Server-side it dies much
  faster** — a JWE that returned 200 on a catalogue call returned 403 minutes
  later (verified live, v3.19). The 22h/24h values are only the client-side
  re-mint timers; plan re-extraction per session, not per day.
- The OkHttp interceptor (v3.20 `c60/p.java`; v3.19 `w50.i`) attaches it to
  every request, waiting up to 10s on first request for the token to become
  available.
- Cannot be obtained from the APK — it requires running the app on a rooted
  emulator with Play Integrity bypasses. See the
  [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)
  repo for a live extraction pipeline.

## Dynamic: hardware attestation signature (new in v3.20)

Every main-API request now carries `x-prosopo-android-key-id`,
`x-prosopo-android-assertion`, `x-prosopo-android-client-data` and
`x-prosopo-android-challenge` — an ECDSA-SHA256 signature made with a key that
lives in AndroidKeyStore/StrongBox and never leaves it. Not reproducible
outside a real Android environment. Details in
[prosopo-protection.md](prosopo-protection.md).

## Prosopo session cookie

Optionally, a `Cookie: prosopo_session=jti|jwt` pair is set from the guard's
`/api/protect/init` response (see [prosopo-protection.md](prosopo-protection.md)).
Catalogue replay captured from a live app works without the cookie.