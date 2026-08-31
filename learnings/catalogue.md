# Catalogue

Ticket search endpoints. Both require the full auth set from [keys.md](keys.md)
(static keys + a **fresh** `x-prosopo-android-integrity-token` header).

## catalogue (legacy) — the working one

**Confirmed live** (v3.19, all four keys → HTTP 200 with listing data;
replayed in
[twickets-key-extractor](https://github.com/ahobsonsayers/twickets-key-extractor)):
`GET https://www.twickets.live/services/catalogue`

`api_key` goes in the **query string** here. The current app sends it as a
header via interceptors, but on this endpoint the query param is what works.

```sh
curl 'https://www.twickets.live/services/catalogue?count=10&q=countryCode%3DGB&api_key=<api_key>' \
  -H 'User-Agent: <user_agent>' \
  -H 'x-prosopo-site-key: <site_key>' \
  -H 'x-prosopo-android-integrity-token: <JWE>'
```

| Param | Type |
|---|---|
| `minTime` | epoch ms |
| `maxTime` | epoch ms |
| `count` | int |
| `q` | string (e.g. `countryCode%3DGB`) |

**Verified live** (v3.19): 200 JSON `{"responseData":[...catalogue blocks...]}`.

Missing `api_key` → `403 {"error":"Access denied"}`. Static keys with a
stale/missing JWE → `403` (HTML for this endpoint).

## g2/catalogue (current app)

**Source-only and currently broken server-side**: 
`GET https://www.twickets.live/services/g2/catalogue`

Verified live with all four valid keys (header and query-param `api_key`,
multiple param shapes incl. empty optionals): always **502 Bad Gateway** from
the CDN — an origin error, not auth. The endpoint exists but doesn't respond
to outside replay. Omitting the Prosopo headers → 403 instead.

Sent by the app with the `api_key` **header** (not query param).

| Param | Type | Notes |
|---|---|---|
| `countryCode` | string | e.g. `GB` |
| `regionCodes` | string | comma-separated region codes |
| `categoryIds` | string | comma-separated category IDs |
| `fromEventDate` | date | ISO date |
| `toEventDate` | date | ISO date |
| `sortBy` | string | sort field |
| `sortDirection` | string | e.g. `asc` / `desc` |
| `limit` | int | page size |
| `cursor` | string | pagination cursor from a previous response |

Source: Retrofit interface `l9/a.java` (`@f("g2/catalogue")`); params
source-inferred.

## Media

**Partially verified**: `GET https://www.twickets.live/services/media/{id}/{w}/{h}`

Takes `api_key` as a **query param** (in addition to the `api_key` header the
interceptors add — the app sends both). With static keys only → `500` (not
403/404, so the route exists); a working 200 response was not obtained with a
valid JWE either, so treat as unresolved. Source: `vc0/e.java`.