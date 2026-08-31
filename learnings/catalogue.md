# Catalogue

Ticket search endpoints. Both require the full auth set from [keys.md](keys.md)
(static keys + `x-prosopo-android-integrity-token` header).

## g2/catalogue (current)

**Confirmed live** (v3.19): `GET https://www.twickets.live/services/g2/catalogue`

Sent by the app with the `api_key` header (not query param) plus the Prosopo
headers.

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

Source: Retrofit interface `l9/a.java` (`@f("g2/catalogue")`); params confirmed
against live responses.

## catalogue (legacy)

**Source-only**: `GET https://www.twickets.live/services/catalogue`

Older public-documented endpoint. Still routes, but returns an HTML 403 without
a valid integrity token (verified live).

| Param | Type |
|---|---|
| `minTime` | epoch ms |
| `maxTime` | epoch ms |
| `count` | int |
| `q` | string (e.g. `countryCode%3DGB`) |

Source: Retrofit interface `l9/a.java` (`@f("catalogue")`).

## Media

**Source-only**: `GET https://www.twickets.live/services/media/{id}/{w}/{h}`

Event image endpoint; takes `api_key` as a **query param** (in addition to the
`api_key` header the interceptors add). Source: `vc0/e.java`.