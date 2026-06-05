# Environment Variables

Sätts i Easypanel under servicens **Environment**-fält. Värdena i `docker-compose.yml` läser dessa via `${VARIABEL}`.

## Obligatoriska

| Variabel | Exempel | Beskrivning |
|----------|---------|-------------|
| `OPENAI_BASE_URL` | `https://api.example.com/v1` | OpenAI-kompatibel endpoint |
| `OPENAI_API_KEY` | `sk-...` eller `dummy` | API-nyckel (måste vara satt, även om endpointen inte kräver auth) |
| `HERMES_MODEL` | `gpt-4o` | Standardmodell — kvarstår vid refresh |

## Valfria

| Variabel | Default | Beskrivning |
|----------|---------|-------------|
| `APP_PORT` | `9119` | Extern port i Easypanel |
| `OPENROUTER_API_KEY` | — | Alternativ: OpenRouter istället för `OPENAI_BASE_URL` |

## Lokal modell (Ollama på hosten)

```
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
HERMES_MODEL=llama3.2
```
