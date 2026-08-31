# Rate Limiting & Bot Detection

Bot detection is enforced by the Prosopo layer — see
[prosopo-protection.md](prosopo-protection.md). Requests with static keys but a
stale/missing integrity token fail fast with 403.

## Observed responses

| Response | Meaning |
|---|---|
| `403 {"error":"Access denied"}` | Missing/invalid `api_key` header |
| `403 {"error":"Android integrity verification failed"}` | Missing/stale `x-prosopo-android-integrity-token` (static keys alone) |
| `403` HTML | Legacy `/services/catalogue` without a valid integrity token |

## Best practices

- **Add random delays** between requests (1-2 seconds)
- **Stop on 403** — it means your integrity token expired; re-extract rather
  than retrying
- **429 / 5xx** — stop immediately and retry later
- The JWE is minted per app launch and expires (~24h TTL) — plan re-extraction
  cycles, see [twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)