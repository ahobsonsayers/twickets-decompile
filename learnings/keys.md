# Authentication & Keys

The Twickets Android API has no user login. Authorisation is a combination of
three static, app-embedded keys plus one dynamic per-launch token. All requests
observed in the app send all of them.

## Static keys

Extractable from the APK (run `task extract` for current values):

| Key | HTTP location | Source |
|---|---|---|
| `api_key` | Header `api_key` | Hardcoded UUID in `ApiKeyInterceptor` (v3.19). The current app sends it as a header on every request; but every verified working replay has used the **query param** instead (legacy `catalogue`, `media`) — see [catalogue.md](catalogue.md) |
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
  verdict.
- Stored in SharedPreferences under `prosopo_protect/integrity_token`; the app
  refreshes it when older than ~24h (86400000 ms TTL check). **Server-side it
  dies much faster** — a JWE that returned 200 on a catalogue call returned 403
  minutes later (verified live). The 24h value is only the client-side re-mint
  timer; plan re-extraction per session, not per day.
- The OkHttp interceptor `w50.i` (v3.19) attaches it to every request, waiting
  up to 10s on first request for the token to become available.
- Cannot be obtained from the APK — it requires running the app on a rooted
  emulator with Play Integrity bypasses. See the
  [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)
  repo for a live extraction pipeline.

## Prosopo session cookie

Optionally, a `Cookie: prosopo_session=jti|jwt` pair is set from the guard's
`/api/protect/init` response (see [prosopo-protection.md](prosopo-protection.md)).
Catalogue replay captured from a live app works without the cookie.