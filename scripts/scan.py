from pathlib import Path
import re
import sys


def scan(decompiled_dir: str) -> None:
    api_key = None
    user_agent = None
    base_url = None
    stream_endpoints = []

    for path in Path(decompiled_dir).rglob("*.java"):
        content = path.read_text(errors="ignore")

        if "ApiKeyInterceptor" in path.name and "_" not in path.stem:
            match = re.search(r'"([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})"', content)
            if match:
                api_key = match.group(1)

        if "UseAgentInterceptor" in path.name and "_" not in path.stem:
            match = re.search(r'"(Twickets/[\d.]+ \(Android/)', content)
            if match:
                user_agent = match.group(1) + "16)"  # hardcoded android version

        if 'authority("www.twickets.live")' in content:
            base_url = "https://www.twickets.live"

        for m in re.finditer(r'(?:appendEncodedPath|\.appendPath)\("([^"]+)"\)', content):
            segment = m.group(1).rstrip("/")
            if segment in ("services/", "services"):
                base_url = f"https://www.twickets.live/{segment}/"

        for m in re.finditer(r'@(?:nt\.)?([fobp])\("([^"]+)"\)', content):
            code = m.group(1)
            endpoint_path = m.group(2)
            method = {"f": "GET", "o": "POST", "b": "DELETE", "p": "PUT"}.get(code, "?")
            if "catalogue" in endpoint_path.lower() or "catalog" in endpoint_path.lower():
                stream_endpoints.append((method, endpoint_path))

    if stream_endpoints:
        for method, endpoint in stream_endpoints:
            if "g2/catalogue" in endpoint:
                url = f"{base_url}{endpoint}"
                print(f"URL: {url}")
                print(f"API Key: {api_key}")
                print(f"User-Agent: {user_agent}")
                print()
                print(f'curl -H "User-Agent: {user_agent}" "{url}?countryCode=GB&limit=10&api_key={api_key}"')
                break


if __name__ == "__main__":
    scan(sys.argv[1])