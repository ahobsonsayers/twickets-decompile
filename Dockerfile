# Stage 1: build — install gplaydl and jadx.
FROM python:3.12-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Install gplaydl (latest). Downloading authenticates via the GPLAYDL_CONFIG
# config JSON; see README.
RUN pip install --no-cache-dir uv && \
    uv tool install gplaydl && \
    ln -s /root/.local/bin/gplaydl /usr/local/bin/gplaydl

# Install jadx. Its launcher resolves APP_HOME from its own path, so it must
# stay in /opt/jadx/bin and be reached via PATH, not a symlink.
RUN curl -fsSL -o /tmp/jadx.zip \
      "https://github.com/skylot/jadx/releases/download/v1.5.6/jadx-1.5.6.zip" && \
    unzip -q /tmp/jadx.zip -d /opt/jadx && \
    chmod +x /opt/jadx/bin/jadx && \
    rm -f /tmp/jadx.zip

# Stage 2: runtime — slim, only what the entrypoint needs.
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless jq && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin/gplaydl /usr/local/bin/gplaydl
COPY --from=build /root/.local /root/.local
COPY --from=build /opt/jadx /opt/jadx
ENV PATH="/opt/jadx/bin:${PATH}"

COPY scripts/ /usr/local/bin/scripts/
RUN chmod +x /usr/local/bin/scripts/*.sh

ENTRYPOINT ["sh", "-c", "/usr/local/bin/scripts/01-download.sh apk && /usr/local/bin/scripts/02-decompile.sh apk/twickets.apk decompiled && /usr/local/bin/scripts/03-extract.sh decompiled/sources"]