# Environment Variables

Set these in Easypanel under the service's **Environment** tab. Values in `docker-compose.yml` are read via `${VARIABLE}`.

## Required

| Variable | Example | Description |
|----------|---------|-------------|
| `OPENAI_BASE_URL` | `https://api.example.com/v1` | OpenAI-compatible endpoint |
| `OPENAI_API_KEY` | `sk-...` or `dummy` | API key (must be set even if the endpoint doesn't require auth) |
| `HERMES_MODEL` | `gpt-4o` | Default model — persists across refreshes |

## Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PORT` | `9119` | External port in Easypanel |
| `OPENROUTER_API_KEY` | — | Alternative: OpenRouter instead of `OPENAI_BASE_URL` |

## Local model (Ollama on host)

```
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
HERMES_MODEL=llama3.2
```
