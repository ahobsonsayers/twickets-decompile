# Prosopo Bot Protection (v3.20)

Twickets ships a Prosopo (protect.twickets.live) guard plus a custom Android
integrity layer. Decompiled in v3.20 from `c60/a.java` … `c60/p.java`
(v3.19: `w50/`). v3.20 adds a hardware-backed key attestation layer on top of
the Play Integrity JWE flow.

## High-level flow (v3.20 bytecode)

```
app launch
  │
  ├─► 1. KEY ATTESTATION (new in v3.20, c60/c.java)
  │      GET  protect.twickets.live/api/android/key-challenge   (x-prosopo-site-key)
  │           → {"challenge": "<hex>"}
  │      delete AndroidKeyStore entry "prosopo_attest_key", generate EC
  │      secp256r1 keypair with setAttestationChallenge (StrongBox when
  │      available, else TEE) → cert chain
  │      POST protect.twickets.live/api/android/key-attest
  │           body: {"site_key","cert_chain":[base64 DER],"challenge",
  │                  "policy":"strongbox"|"tee"}
  │           → {"success":bool,"key_id":"..."}
  │      key_id stored in SharedPreferences prosopo_protect/key_attest_key_id
  │
  ├─► 2. PLAY INTEGRITY (c60/f.java, c60/o.java)
  │      GET  protect.twickets.live/api/android/integrity-nonce   (new in v3.20)
  │           → {"nonce": "..."}
  │      Play Integrity verdict (token) + nonce
  │      POST protect.twickets.live/api/android/integrity
  │           body: {"token","nonce"}
  │           → {"status":"accepted|retry_same|retry_fresh|fatal","reason"}
  │
  ├─► 3. SESSION INIT (unchanged from v3.19)
  │      POST protect.twickets.live/api/protect/init
  │           body: {"visitor_id":"android-placeholder-fp","sr":"android",
  │                  "site_key":"<site_key>","d":""}
  │           → {"jti":"...","jwt_token":"..."}
  │      stored: prosopo_protect/session_jti + session_jwt
  │      cookie prosopo_session=jti|jwt
  │
  ▼
OkHttp interceptor (c60/p.java) attaches to EVERY request:
  header x-prosopo-android-integrity-token: <JWE>
  header x-prosopo-site-key: <site_key>
  header x-prosopo-android-sdk-version: 1.0.2        (new in v3.20)
  cookie prosopo_session=jti|jwt (when present)
  — per-request hardware signature (new in v3.20):
  header x-prosopo-android-key-id:        <key_id>
  header x-prosopo-android-assertion:    base64 ECDSA-SHA256 signature
  header x-prosopo-android-client-data:  base64 {"method","path","challenge","timestamp"}
  header x-prosopo-android-challenge:    <current challenge hex>
  - waits up to 10s (CompletableFuture) on first request
  - challenge from cached x-prosopo-next-challenge response header, else
    GET /api/android/key-challenge; next challenge cached from response
```

## Per-request signing (new in v3.20, `c60/p.java`)

The interceptor signs every outgoing main-API request with the attested private
key from AndroidKeyStore entry `prosopo_attest_key`:

- **client_data** JSON: `{"method": "<GET|POST>", "path": "<request path>",
  "challenge": "<hex>", "timestamp": "yyyy-MM-dd'T'HH:mm:ss'Z' (UTC)"}`,
  base64-encoded into `x-prosopo-android-client-data`.
- **Signature**: SHA256withECDSA over the client_data, Base64 (NO_WRAP) into
  `x-prosopo-android-assertion`.
- **Challenge** source: the previous response's `x-prosopo-next-challenge`
  header (cached), or a fresh `GET /api/android/key-challenge`. Echoed as
  `x-prosopo-android-challenge`.
- This is **not statically reproducible** — the private key never leaves
  AndroidKeyStore/StrongBox, so replay from a non-Android environment cannot
  produce valid signatures.

## Details

- **Key attestation policy** (`c60/a.java`) — StrongBox required when
  SDK ≥ 28 and `hasSystemFeature("android.hardware.strongbox_keystore")`,
  else TEE fallback; sent as `"policy"` in the key-attest body.
- **Token refresh** — the mint loop re-mints the JWE every ~22h (79200000 ms
  in `c60/f.java`); the validity check in `c60/o.java` still uses 24h
  (86400000 ms). Server-side it dies much faster either way (verified live in
  v3.19) — plan re-extraction per session.
- **Integrity response mapping** (`c60/o.java n()`) — JSON
  `{"status": "accepted|retry_same|retry_fresh|fatal", "reason"}`; HTTP
  fallback when the body isn't JSON: 2xx→accepted, ≥500→retry_same,
  400/401→retry_fresh, else fatal. On `retry_same` sleeps 2000 ms and retries
  once; on other failures backoff `30000 << n` capped at 1800000 ms (30 min).
- **Init retry** — `/api/protect/init` is retried every 5000 ms until success.
- **Quota exceeded** — on Play Integrity quota failure the app POSTs
  `/api/android/integrity-quota-exceeded` (empty JSON body).
- **Warm-up** — the JWE is not present on the very first request after launch;
  the interceptor waits (up to 10s) for it to appear.
- **Static site key** — `x-prosopo-site-key` is hardcoded (see
  [config.md](config.md)); extractable statically.
- **SDK version** — `x-prosopo-android-sdk-version: 1.0.2` (new in v3.20) on
  all protect.twickets.live requests and all main-API requests.

## What this means for API use

- The `x-prosopo-android-integrity-token` JWE **cannot be minted statically** —
  it requires running the app on a rooted emulator with Play Integrity bypasses.
- v3.20 adds per-request hardware attestation signatures; if enforced
  server-side, replay requires running the full app stack on a real Android
  environment — a rooted emulator with functioning AndroidKeyStore is now the
  minimum viable extraction setup.
- Catalogue replay captures from a live app work **without** the
  `prosopo_session` cookie; the JWE header is the gating item (verified in
  v3.19; the new attestation headers' enforcement is unverified).
- Live extraction pipeline: see
  [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor).