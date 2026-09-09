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

## Dashboard auth (required)

Hermes v0.21 (2026.9) changed the rule: the dashboard **refuses to bind on 0.0.0.0
without an auth provider**, and `HERMES_DASHBOARD_INSECURE` no longer disables the
gate on a non-loopback bind. Since Easypanel reaches the container over the Docker
network, the bind is always non-loopback, so a password is mandatory:

```
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=alice
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=s3cret
HERMES_DASHBOARD_BASIC_AUTH_SECRET=<openssl rand -hex 32>
```

> **Fails closed:** without these the log says `Refusing to bind dashboard to 0.0.0.0`
> and the dashboard never comes up, while the gateway keeps running. Check the
> container log first when the Domain answers 502.

| Variable | Description |
|----------|-------------|
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | Login username |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | Plaintext password (hashed in memory at startup) |
| `HERMES_DASHBOARD_BASIC_AUTH_SECRET` | HMAC signing key for session tokens — sessions die on restart without it |
| `HERMES_DASHBOARD_INSECURE` | Only honoured by images older than 2026.9. Leave empty. |

## Networking

No host port is published. Give the service a **Domain** in Easypanel pointing at
container port `9119`; Traefik does the rest. `APP_PORT` and `APP_BIND` from earlier
versions of this repo are gone: a `ports:` binding makes a second Hermes on the same
host fail with "port is already allocated" while Easypanel still reports success.

## Image updates

| Variable | Default | Description |
|----------|---------|-------------|
| `PULL_POLICY` | `always` | Every Easypanel **Redeploy** pulls the image first. `missing` reuses the cached one. |
| `HERMES_TAG` | (empty = `latest`) | Docker Hub tag. `latest` is rebuilt from upstream `main` several times a week and is usually *ahead* of the newest GitHub release (on 2026-09-09: `latest` = v0.21.1 built that night, newest release tag `v2026.9.7`). Pin a `vYYYY.M.D` tag for reproducible redeploys. |

## Running multiple Hermes instances

One Easypanel service per Hermes (separate `data` volume), each with its own Domain.
Nothing else to manage: there are no host ports. The container's internal port is
`9119` for all of them. Give each its own `HERMES_AGENT_ID` and `SUPABASE_MCP_KEY`.

## Supabase MCP (shared data for a fleet of agents)

Pairs with [supabase-easy](https://github.com/magnusfroste/supabase-easy): Studio's MCP
server behind Kong key-auth, one key per agent.

| Variable | Example | Description |
|----------|---------|-------------|
| `SUPABASE_MCP_URL` | `https://skillhub.example.com/mcp` | Streamable-HTTP MCP endpoint |
| `SUPABASE_MCP_KEY` | `MCP_KEY_03` value from the Supabase service | Sent as header `apikey` (not `Authorization: Bearer` — Kong ignores that) |
| `HERMES_AGENT_ID` | `agent_03` | Identifier in the shared data; same number as the key slot |

At every boot the compose `command` seeds `config.yaml`:

```yaml
mcp_servers:
  supabase:
    url: https://skillhub.example.com/mcp
    headers:
      apikey: ${SUPABASE_MCP_KEY}
    enabled: true
    timeout: 120
```

The key itself is never written to the volume; Hermes resolves `${SUPABASE_MCP_KEY}`
from the container environment when it connects. `HERMES_AGENT_ID` appends one marked
line to `SOUL.md` telling the agent its identifier and to read the shared
`supabase-konventioner` skill before writing. Both are re-applied on every boot, so
edit the env, not the files. Restrict tools by adding under the same block by hand:

```yaml
    tools:
      exclude: [apply_migration]
```

Verify from the dashboard: `/reload-mcp`, then ask the agent to run `list_tables`.

## Local model (Ollama on host)

```
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
HERMES_MODEL=llama3.2
```
