FROM python:3.11-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git build-essential libxml2-dev libxslt1-dev libffi-dev libssl-dev zstd \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install Python tools (Supervisor, etc.)
RUN pip install --no-cache-dir supervisor

WORKDIR /opt

# ---------- Open WebUI (via pip) ----------
# Docs: pip install open-webui ; open-webui serve
RUN pip install --no-cache-dir open-webui

# ---------- SearXNG (from source) ----------
RUN git clone https://github.com/searxng/searxng.git /opt/searxng-src

WORKDIR /opt/searxng-src
RUN python -m venv /opt/searxng-venv && \
    /opt/searxng-venv/bin/pip install --upgrade pip && \
    /opt/searxng-venv/bin/pip install --no-cache-dir msgspec PyYAML && \
    /opt/searxng-venv/bin/pip install --no-cache-dir --no-build-isolation ".[all]"

# Open WebUI persistence
# Use a stable data path so you can mount a Docker volume to keep accounts/chats.
RUN mkdir -p /data/openwebui
ENV DATA_DIR=/data/openwebui

# SearXNG configuration (use upstream default settings.yml)
# We'll override bind/port via env vars at runtime (see supervisord.conf).
RUN mkdir -p /etc/searxng && \
    cp searx/settings.yml /etc/searxng/settings.yml

# Open WebUI's SearXNG provider requires JSON output from SearXNG.
RUN /opt/searxng-venv/bin/python -c "import pathlib, yaml; p=pathlib.Path('/etc/searxng/settings.yml'); d=yaml.safe_load(p.read_text()); s=d.setdefault('search', {}); f=s.setdefault('formats', ['html']); f.append('json') if 'json' not in f else None; p.write_text(yaml.safe_dump(d, sort_keys=False))"

ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml
ENV SEARXNG_BASE_URL=http://localhost:8081/

# reset runtime working dir
WORKDIR /opt

# ---------- Supervisor config ----------
COPY supervisord.conf /etc/supervisord.conf

# Ports:
#  - 11434 : Ollama API
#  - 8080  : Open WebUI
#  - 8081  : SearXNG
EXPOSE 11434 8080 8081

CMD ["supervisord", "-c", "/etc/supervisord.conf"]