# Ollama + Open WebUI + SearXNG (single container)

One Docker container running **Ollama**, **Open WebUI**, and **SearXNG** via Supervisor.

**Prerequisites:** Docker installed and running.

---

## Setup

From the project directory:

```bash
docker build -t ollama-openwebui-searxng .
```

---

## Run

```bash
docker run -d --name ollama-stack -p 11434:11434 -p 8080:8080 -p 8081:8081 ollama-openwebui-searxng
```

### Optional .env setup:

Create `.env` from the template:

```bash
cp .env.template .env
```

Then run with it:

```bash
docker run -d --name ollama-stack -p 11434:11434 -p 8080:8080 -p 8081:8081 --env-file .env ollama-openwebui-searxng
```

To keep Ollama models across container restarts, add a volume:

```bash
docker run -d --name ollama-stack -p 11434:11434 -p 8080:8080 -p 8081:8081 -v ollama-models:/root/.ollama --env-file .env ollama-openwebui-searxng
```

To keep Open WebUI user accounts, chats, and settings across container recreation, add a volume:

```bash
docker run -d --name ollama-stack -p 11434:11434 -p 8080:8080 -p 8081:8081 -v ollama-models:/root/.ollama -v openwebui-data:/data/openwebui --env-file .env ollama-openwebui-searxng
```

---

## Pull Ollama models (Option A)

After the container is running, pull models from the host:

```bash
docker exec -it ollama-stack ollama pull llama3.2
docker exec -it ollama-stack ollama pull phi3
```

List installed models:

```bash
docker exec -it ollama-stack ollama list
```

---

## URLs

| Service     | URL                    |
|------------|------------------------|
| Open WebUI | http://localhost:8080  |
| SearXNG    | http://localhost:8081  |
| Ollama API | http://localhost:11434 |

---

## Configure Open WebUI Web Search (SearXNG)

### Option A (recommended): configure at container creation time

1. Copy `.env.template` to `.env` and set:
   - `ENABLE_RAG_WEB_SEARCH=True`
   - `RAG_WEB_SEARCH_ENGINE=searxng`
   - `SEARXNG_QUERY_URL=http://127.0.0.1:8081/search?q=<query>&format=json`
2. Start the container with `--env-file .env` (examples above).

### Option B: configure via Admin UI

1. Open Open WebUI at `http://localhost:8080` and sign in.
2. Go to Admin Settings → Web Search.
3. Select provider **SearXNG**.
4. Set **SearXNG Query URL** to:

`http://127.0.0.1:8081/search?q=<query>&format=json`

Notes:
- Use the literal placeholder `<query>` (Open WebUI replaces it).
- This image enables SearXNG JSON output (required for the SearXNG provider).

---

## Using Ollama from other projects

The API is reachable on the host at **http://localhost:11434**. From another machine on your network use **http://\<host-ip\>:11434**.

```bash
curl http://localhost:11434/api/tags
curl http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"Hi","stream":false}'
```

Set your client’s base URL to `http://localhost:11434` (or the host IP when calling from elsewhere). No extra Docker config needed.

---

## Stop / remove

```bash
docker stop ollama-stack
docker rm ollama-stack
```

If you used the volume, models stay in the `ollama-models` volume. To remove it:

```bash
docker volume rm ollama-models
```

Open WebUI data lives in the `openwebui-data` volume. To remove it (deletes accounts/chats):

```bash
docker volume rm openwebui-data
```

## Sources
Ollama: https://ollama.com/

Open WebUI: https://openwebui.com/

SearXNG: https://docs.searxng.org/
