# Ollama + Open WebUI + SearXNG Local Stack (Docker Compose)

Self-hosted AI chat interface with local LLM inference (Ollama), UI (Open WebUI), persistent storage (Redis + Postgres), and private web search/RAG via SearXNG — all via Docker Compose.

**Features**
- GPU acceleration for Ollama (NVIDIA CUDA)
- Web search integration in Open WebUI via SearXNG (JSON format enabled)
- Persistent data for models, chats, users via Redis + PostgreSQL
- Easy to start/stop/update with `docker compose`

**Prerequisites**
- Docker & Docker Compose installed
- (Recommended) NVIDIA GPU with drivers installed
- For WSL2 users: NVIDIA drivers on Windows host + WSL2 GPU support

---

## Setup

Clone or download this repository, then from the project directory:

```bash
docker compose pull
```

## Run

Start all services in the background:

```bash
docker compose up -d
```

View logs:

```bash
docker compose logs -f
# Or for a specific service:
docker compose logs -f open-webui
```

---

## Pull Ollama Models

After the stack is running, pull models into Ollama:

```bash
docker exec -it ollama ollama pull qwen3.5:9b
docker exec -it ollama ollama pull llama3.2
```

List installed models:

```bash
docker exec -it ollama ollama list
```

---


## Enable GPU Acceleration for Ollama (NVIDIA CUDA)
### On Linux Host (Ubuntu/Debian etc.)
### Install NVIDIA Container Toolkit:
```
# Prerequisites
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg

# Add repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Verify GPU access:
```
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## URLs

| Service     | URL                    |
|-------------|------------------------|
| Open WebUI  | http://localhost:8080  |
| SearXNG     | http://localhost:8081  |
| Ollama API  | http://localhost:11434 |

---

## Services

| Service     | Image                              | Purpose                        |
|-------------|------------------------------------|--------------------------------|
| `ollama`    | `ollama/ollama`                    | LLM inference (GPU-accelerated)|
| `open-webui`| `ghcr.io/open-webui/open-webui`    | Chat UI                        |
| `redis`     | `redis:7`                          | Session / caching              |
| `postgres`  | `postgres:16`                      | Persistent chat & user storage |
| `searxng`   | `searxng/searxng`                  | Private web search for RAG     |

---

## Web Search (SearXNG) Configuration

Web search is pre-configured via environment variables in `docker-compose.yml`:

```
ENABLE_RAG_WEB_SEARCH=true
RAG_WEB_SEARCH_ENGINE=searxng
SEARXNG_QUERY_URL=http://searxng:8081/search?q=<query>&format=json
```

No additional setup is required. To verify or adjust, go to **Admin Settings → Web Search** in Open WebUI.

> **Note:** The `SEARXNG_QUERY_URL` uses the internal Docker service name `searxng`, not `localhost`. Do not change this to a host address.

---

## Persistent Data

All data is stored under `./data/` in the project directory:

| Path                   | Service    | Contents                     |
|------------------------|------------|------------------------------|
| `./data/ollama`        | Ollama     | Downloaded models            |
| `./data/openwebui`     | Open WebUI | User data, settings          |
| `./data/redis`         | Redis      | Session cache                |
| `./data/postgres`      | Postgres   | Chats, users, accounts       |
| `./searxng/settings.yml` | SearXNG  | Search engine configuration  |

Data persists across container restarts and recreations.

---

## Using the Ollama API from Other Projects

The Ollama API is exposed on the host at **http://localhost:11434**. From another machine on your network, use **http://\<host-ip\>:11434**.

```bash
curl http://localhost:11434/api/tags
curl http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"Hi","stream":false}'
```

---

## Stop / Restart

Stop all services (data is preserved):

```bash
docker compose down
```

Stop and remove all volumes (**deletes all data**):

```bash
docker compose down -v
```

Restart a single service:

```bash
docker compose restart open-webui
```

Update images and recreate containers:

```bash
docker compose pull
docker compose up -d
```

---

## Sources

- Ollama: https://ollama.com/
- Open WebUI: https://openwebui.com/
- SearXNG: https://docs.searxng.org/