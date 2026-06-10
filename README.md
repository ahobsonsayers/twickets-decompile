# Twickets APK Decompilation

Decompile the Twickets APK and extract API details

## Prerequisites

- **go-task** — task runner for running commands
- **jadx** — decompiles Android APKs to readable Java source
- **uv** — Python package runner, used to run gplaydl to download APK and run the extract script

Install with:

```bash
brew install go-task jadx uv
```

## Run

```bash
task download
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
