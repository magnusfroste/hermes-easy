# Environment Variables

Set these in Easypanel under the service's **Environment** tab. Values in `docker-compose.yml` are read via `${VARIABLE}`.

## Model / endpoint

| Variable | Example | Description |
|----------|---------|-------------|
| `OPENAI_BASE_URL` | `https://api.example.com/v1` | OpenAI-compatible endpoint |
| `OPENAI_API_KEY` | `sk-...` or `dummy` | API key (must be set even if the endpoint doesn't require auth) |
| `HERMES_MODEL` | `gpt-4o` | Default model — persists across refreshes |

## Provider API keys (switch model/provider from the dashboard)

Set any of these and you can switch between providers live in Hermes via the
`/model` command in the dashboard. Leave blank to disable a provider.

| Variable | Provider |
|----------|----------|
| `OPENROUTER_API_KEY` | OpenRouter (multi-model aggregator) |
| `ANTHROPIC_API_KEY` | Anthropic Claude |
| `GEMINI_API_KEY` | Google Gemini |
| `DEEPSEEK_API_KEY` | DeepSeek |
| `GROQ_API_KEY` | Groq |
| `XAI_API_KEY` | xAI Grok |
| `MISTRAL_API_KEY` | Mistral |
| `OPENAI_BASE_URL` + `OPENAI_API_KEY` | Any OpenAI-compatible endpoint (vLLM, Ollama, custom) |

## Dashboard auth

By default (`HERMES_DASHBOARD_INSECURE=1`) the dashboard is open — no login required.
That's fine for development or a trusted network. For production / multi-tenant use, set a password instead.

### Open (default — dev / trusted LAN)

```
HERMES_DASHBOARD_INSECURE=1
```

### Password-protected

**Remove** `HERMES_DASHBOARD_INSECURE` (or set it to an empty string) and set:

```
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=alice
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=s3cret
HERMES_DASHBOARD_BASIC_AUTH_SECRET=<random 32+ char string>
```

Generate the secret with `openssl rand -hex 32`.

> **IMPORTANT — fails-closed:** If `HERMES_DASHBOARD_INSECURE` is empty but no
> `BASIC_AUTH_USERNAME`/`PASSWORD` are set, the container **refuses to start**.
> Always set the auth vars before removing INSECURE.

| Variable | Required for auth | Description |
|----------|-------------------|-------------|
| `HERMES_DASHBOARD_INSECURE` | Must be empty | Set to `1` to disable auth gate; leave empty to enable it |
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | Yes | Login username |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | Yes | Plaintext password (hashed in memory at startup) |
| `HERMES_DASHBOARD_BASIC_AUTH_SECRET` | Yes | HMAC signing key for session tokens — sessions die on restart without this |

## Networking

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PORT` | `9119` | Host port the dashboard is published on |
| `APP_BIND` | `127.0.0.1` | Host interface to bind (`0.0.0.0` to reach it from outside the server) |

## Image updates

The compose file sets `pull_policy: always`, so every Easypanel **Redeploy**
fetches the newest `nousresearch/hermes-agent:latest` image before starting the
container. A plain **Restart** reuses the cached image.

## Running multiple Hermes instances

Easypanel routes a domain to each service via Traefik → the container's internal
port `9119` (e.g. `https://app-hermes2.<your>.easypanel.host`). The published
host port is **not** used for domain access.

Give **each** Hermes its own Easypanel service (separate `data` volume). Then:

- **Domain access (recommended for many instances):** drop the `ports:` block
  entirely and reach each instance via its Easypanel domain. No host-port
  management, no conflicts.
- **Direct host port:** if you keep `ports:` and want `localhost:port` access on
  the server, give each instance a unique `APP_PORT` (9119, 9120, 9121…),
  otherwise the second container fails with "port already allocated".

The container's internal port stays `9119` for all of them.

## Local model (Ollama on host)

```
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
HERMES_MODEL=llama3.2
```
