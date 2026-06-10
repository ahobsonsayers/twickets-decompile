# Twickets APK Decompilation

Decompile the Twickets APK and extract API details

## Prerequisites

```bash
brew install go-task jadx
```

Place the APK at `apk/twickets.apk`.

## Run

```bash
task decompile
task extract
```

## Example Output

```
Ticket Feed:
URL: https://www.twickets.live/services/g2/catalogue
API Key: 00000000-0000-0000-0000-000000000000
User-Agent: Twickets/3.16 (Android/16)

Example:
curl -H "User-Agent: Twickets/3.16 (Android/16)" "https://www.twickets.live/services/g2/catalogue?countryCode=GB&limit=10&api_key=00000000-0000-0000-0000-000000000000"
```
