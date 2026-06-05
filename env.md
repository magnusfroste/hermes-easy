# Environment Variables

Sätts i Easypanel under respektive service.

## Snabbstart — OpenAI-kompatibel endpoint

Kopiera dessa rakt in i gateway-servicens env i Easypanel:

```
HERMES_MODEL=<modellnamn>
OPENAI_BASE_URL=<din-endpoint>/v1
OPENAI_API_KEY=<din-nyckel-eller-dummy>
```

> Kräver endpointen ingen API-nyckel måste `OPENAI_API_KEY` ändå vara satt till något icke-tomt värde, t.ex. `dummy`.

---

## Hermes (gateway + dashboard)

| Variabel | Default | Beskrivning |
|----------|---------|-------------|
| `HERMES_UID` | `10000` | UID som containern kör som |
| `HERMES_GID` | `10000` | GID som containern kör som |
| `HERMES_MODEL` | `autoversio` | Standardmodell — sätts permanent, ändras inte vid refresh |

## Dashboard

| Variabel | Default | Beskrivning |
|----------|---------|-------------|
| `APP_BIND` | `127.0.0.1` | Bind-adress för dashboarden |
| `APP_PORT` | `9119` | Extern port som Easypanel mappar till 9119 |

## LLM-providers

Sätt en av dessa i **gateway**-servicen.

| Variabel | Provider |
|----------|----------|
| `OPENAI_BASE_URL` + `OPENAI_API_KEY` | Valfri OpenAI-kompatibel endpoint |
| `OPENROUTER_API_KEY` | OpenRouter (ger tillgång till alla modeller) |
| `GOOGLE_API_KEY` | Google AI Studio / Gemini |
| `GROQ_API_KEY` | Groq |
| `NOVITA_API_KEY` | NovitaAI |
| `OLLAMA_API_KEY` | Ollama Cloud |

## Lokal / privat modell

Containern kan nå tjänster på hosten via `host.docker.internal` (redan konfigurerat i compose).

### Ollama (på hosten)
```
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
```
Välj modell i dashboarden, t.ex. `llama3.2` eller `qwen2.5-coder`.

### LM Studio (på hosten)
```
LM_BASE_URL=http://host.docker.internal:1234/v1
LM_API_KEY=<bearer-token-om-auth-aktiverat>
```
Välj `provider: lmstudio` i dashboarden.

### Privat OpenAI-kompatibel endpoint
```
OPENAI_BASE_URL=<din-endpoint>/v1
OPENAI_API_KEY=<din-nyckel>
```

---

## API-server (valfritt)

Aktiverar en OpenAI-kompatibel API-endpoint. Avkommentera i `docker-compose.yml`.

| Variabel | Beskrivning |
|----------|-------------|
| `API_SERVER_HOST` | Sätt till `0.0.0.0` för att exponera utanför localhost |
| `API_SERVER_KEY` | Obligatorisk auth-nyckel när `API_SERVER_HOST` är satt |
