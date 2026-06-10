from pathlib import Path
import re
import sys

UUID = re.compile(r'"([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})"')
USER_AGENT_PREFIX = re.compile(r'"(Twickets/[\d.]+ \(Android/)')
SERVICES_PATH = re.compile(r'(?:appendEncodedPath|\.appendPath)\("(services/?)"\)')
ENDPOINT = re.compile(r'@(?:nt\.)?([fobp])\("([^"]+)"\)')


def extract(decompiled_dir: str) -> None:
    api_key = None
    user_agent = None
    base_url = None
    feed_endpoint = None

    for path in Path(decompiled_dir).rglob("*.java"):
        content = path.read_text(errors="ignore")

        if "ApiKeyInterceptor" in path.name and "_" not in path.stem:
            m = UUID.search(content)
            if m:
                api_key = m.group(1)

        if "UseAgentInterceptor" in path.name and "_" not in path.stem:
            m = USER_AGENT_PREFIX.search(content)
            if m:
                user_agent = m.group(1) + "16)"  # hardcoded android version

        if 'authority("www.twickets.live")' in content:
            base_url = "https://www.twickets.live"
            m = SERVICES_PATH.search(content)
            if m:
                base_url = f"https://www.twickets.live/{m.group(1).rstrip('/')}/"

        if feed_endpoint is None:
            for m in ENDPOINT.finditer(content):
                if "g2/catalogue" in m.group(2):
                    feed_endpoint = m.group(2)

    if base_url and feed_endpoint:
        url = f"{base_url}{feed_endpoint}"
        print("Ticket Feed:")
        print(f"URL: {url}")
        print(f"API Key: {api_key}")
        print(f"User-Agent: {user_agent}")
        print()
        print("Example:")
        print(f'curl -H "User-Agent: {user_agent}" "{url}?countryCode=GB&limit=10&api_key={api_key}"')


if __name__ == "__main__":
    extract(sys.argv[1])