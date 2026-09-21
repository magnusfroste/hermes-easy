# Environment Variables

Set these in Easypanel under the service's **Environment** tab. Values in `docker-compose.yml` are read via `${VARIABLE}`.

## Model / endpoint

| Variable | Example | Description |
|----------|---------|-------------|
| `OPENAI_BASE_URL` | `https://api.example.com/v1` | OpenAI-compatible endpoint |
| `OPENAI_API_KEY` | `sk-...` or `dummy` | API key (must be set even if the endpoint doesn't require auth) |
| `HERMES_MODEL` | `gpt-5.6-luna` | Default model, **bare name**. Written into `config.yaml` by the boot seed. |
| `HERMES_PROVIDER` | `openai-api` | Provider slug from Hermes' catalogue. Written into `config.yaml` by the boot seed. |
| `HERMES_MODEL_BASE_URL` | *(empty)* | Only for an endpoint the catalogue does not know. Empty makes the seed **remove** `model.base_url`. |

### Why these go through config.yaml

### An endpoint you host is a provider of its own

| Variable | Example | Meaning |
|---|---|---|
| `HERMES_PROVIDERS` | `house\|House endpoint\|https://your-endpoint/v1\|PRIVATE_LLM_API_KEY` | One record per endpoint: `id\|name\|base_url\|KEY_ENV_VAR[\|api_mode]`, several separated by `;`. |
| `PRIVATE_LLM_API_KEY` | `sk-…` | The key itself, in the variable the record names. Any variable name works; this one already exists here. |

Each record becomes a `providers:` entry in `config.yaml`, which Hermes resolves as
`source='user-config'` with its own wire protocol, key variable and base URL, overriding
nothing. So your own box and every hosted provider are loaded at boot and the person switches
between them at runtime with `/model`. `api_mode` defaults to `chat_completions`, which is what
vLLM, Ollama and llama.cpp serve; `anthropic_messages` and `codex_responses` are the others.

**Name the entry for its role, not its hardware.** The id is what `/model` shows and what
`HERMES_PROVIDER` selects, and the box behind it gets replaced -- today a DGX serving GLM, next
month vLLM or Unsloth serving something else. `house`, `private`, `onprem` and `lab` age well;
`dgx` and `glm` do not. The boot seed refuses the bare word `custom`: Hermes treats a stored
bare `custom` as corrupt state from an old model-switch bug and self-heals it to the first entry
it finds (`providers.py:456`).

`model.provider` takes the entry's **bare** key -- `house`, not `custom:house`. Verified against
the image 2026-09-20: `resolve_provider_full` tries `providers.<raw name>` first, and
`custom:house` resolves to `None` for a keyed entry, because the `custom:` form addresses the
legacy `custom_providers:` **list** instead. Earlier revisions of this file said otherwise.

**Do not reach a private endpoint through another provider's variables.** Both shortcuts look
like they work and then take something else away:

- `OPENAI_BASE_URL` redirects the **real** OpenAI provider. Measured 2026-09-20: a local DGX
  cluster was wired in exactly this way with `OPENAI_API_KEY` holding the cluster's key. The
  agent reached the cluster and could no longer reach OpenAI at all, with nothing saying so --
  and switching model in `/model` would have sent `gpt-*` to a machine that has never heard
  of it.
- Borrowing the provider the catalogue infers from the model name is worse. A model served as
  `glm-5.3-flash` resolves to provider `zai` whatever `HERMES_PROVIDER` says, and the session
  dies with *"No usable credentials found for provider 'zai'. Set GLM_API_KEY, ZAI_API_KEY,
  Z_AI_API_KEY"* -- for a model running on hardware in the next room. Setting `GLM_BASE_URL`
  and `GLM_API_KEY` does work, and is still a lie: the day that box serves Qwen, the name
  resolves somewhere else again.

The boot seed prints one line per declared provider, and warns when the key variable a
provider names is empty -- because that failure otherwise surfaces much later, inside a
session, naming the provider and not the variable.

**A self-hosted endpoint serves the name IT chose, not the name the weights were published
under.** Measured 2026-09-20: a local DGX cluster was added as `OPENAI_BASE_URL` and
`HERMES_MODEL` was set to the repository slug of the weights,
`local-inference-lab/GLM-5.3-Flash-NVFP4-Spark`, while vLLM served the same model as plain
`glm-5.3-flash`. The agent started, reported `provider_configured: true`, and answered
HTTP 404 to every call for a day. Ask the endpoint before guessing:

```bash
curl -sS "$OPENAI_BASE_URL/models" -H "authorization: Bearer $OPENAI_API_KEY"
```

Since then the boot seed asks for you whenever the endpoint is given by URL, and prints either
`the endpoint serves '<name>'` or a warning listing the names it does serve. It is a warning,
not a refusal: a model server can legitimately be asleep when the agent boots.

`HERMES_MODEL` on its own does nothing. The active model is read from `config.yaml` and
only from there — `tui_gateway/server.py:1423` takes `(model, provider)` "by config.yaml
— and ONLY config", and `hermes_cli/config.py:2989` states that "a truthy configured
model wins over `HERMES_MODEL`". The image ships:

```yaml
model:
  default: anthropic/claude-opus-4.6
  provider: auto
  base_url: https://openrouter.ai/api/v1
```

So before the boot seed wrote these keys, two agents whose Environment panels read
`HERMES_MODEL=openai/gpt-5.6-luna` had both been running Claude Opus through OpenRouter
for a day. Only the agent that lacked an `OPENROUTER_API_KEY` showed anything, and what
it showed was `payment / credit error` — nowhere near the real cause. Measured 2026-09-11.

Two traps in the values themselves:

- **The model name must be bare.** `openai/gpt-5.6-luna` is forwarded to the endpoint
  verbatim and returns `HTTP 404: The model 'openai/gpt-5.6-luna' does not exist`; in
  other code paths the prefix is looked up as a provider and fails with
  `Unknown provider`. The seed logs a warning if the value contains a `/`.
- **The slug is `openai-api`, not `openai`.** `hermes config set model.provider openai`
  is accepted by the config writer and then fails at inference with
  `Unknown provider 'openai'`. `openai-codex` is the ChatGPT-subscription route, a
  different thing. The catalogue holds 79 slugs; `hermes model` lists them, but it
  requires a real terminal and refuses to run through a pipe.

`model.base_url` must be **removed**, not overwritten, when you switch to a catalogue
provider — a leftover `openrouter.ai` there contradicts the provider, and
`auxiliary_client.py:4136` carries a warn-once for exactly that state. The seed does this
whenever `HERMES_MODEL_BASE_URL` is empty.

### Private AI / your own endpoint

An endpoint of your own is not in the catalogue. It needs a **named** entry plus
`model.provider = custom:<name>`:

```yaml
providers:
  house:
    base_url: https://your-endpoint/v1
    key_env: PRIVATE_LLM_API_KEY     # the NAME of the env var, not the key itself
    default_model: your-model
    api_mode: chat_completions
model:
  default: your-model
  provider: house            # the entry's bare key, not custom:house
```

Never a bare `custom`: with the bare form the entry name is lost and the key has to be
persisted in clear text in `config.yaml` (`runtime_provider_custom.py:220`). `key_env` names a
variable instead, so the key stays in the Easypanel panel and never lands on the data volume —
the same rule as `SUPABASE_MCP_KEY`.

`HERMES_PROVIDERS` writes this block for you at every boot, which is what the paragraph above
describes; the hand-written form is here because it is what the entry looks like, and for an
endpoint you want on one agent only.

This is **not** seeded from env yet, deliberately: there is no private endpoint here to
test the branch against, and untested boot-seed code is worse than a documented recipe.
Set it once per agent with `hermes config set providers.house.base_url …` (dotted keys
create the nested entry — verified) and it persists on the volume across Redeploys.

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
| `PULL_POLICY` | — | **Unused.** The image is built from the `Dockerfile`, and the base tag is re-resolved on every build by `pull: true`. |
| `HERMES_TAG` | (empty = `latest`) | Docker Hub tag. `latest` is rebuilt from upstream `main` several times a week and is usually *ahead* of the newest GitHub release (on 2026-09-09: `latest` = v0.21.1 built that night, newest release tag `v2026.9.7`). Pin a `vYYYY.M.D` tag for reproducible redeploys. |

## Running multiple Hermes instances

One Easypanel service per Hermes (separate `data` volume), each with its own Domain.
Nothing else to manage: there are no host ports. The container's internal port is
`9119` for all of them. Give each its own `HERMES_AGENT_ID` and `SUPABASE_MCP_KEY`.

## Supabase MCP (shared data for a fleet of agents)

Pairs with [skillhub](https://github.com/magnusfroste/skillhub): Studio's MCP
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
from the container environment when it connects.

`HERMES_AGENT_ID` appends one marked block to `SOUL.md`: the agent's identifier, and the
handful of house rules that have to arrive before the agent has read anything. It names tools
explicitly, because with this many MCP tools Hermes pools them as *deferred* and the agent sees
only names and about 60 truncated characters — a rule that says "follow the conventions" reaches
nobody. What the block says, and why each line is there:

- **Run `skillhub_overview` at the start of a session** — the one call that shows what exists.
- **Search before you ANSWER from that data** — a colleague may have written down how it has to
  be read, and reading it wrong yields a confident wrong number rather than an error.
- **Search before you RESEARCH anything, whatever the subject.** Added 2026-09-21 after watching
  the first agent on a client install research an ERP system from scratch: it deliberated five
  times over whether the answer-rule applied to a web-research task, concluded "do it anyway to
  follow convention", and ran `skillhub_overview` twice on the way. The reason that actually
  applies to research — somebody may have done this last week — was in none of the rules it had.
- **Anything worth keeping goes INTO the store, not into a file in your workspace.** Same
  session: the agent's plan was "save the report to a file in the workspace… I might also save a
  note to skillhub". The store was the afterthought and the container's filesystem was the
  default, which is exactly backwards — that filesystem is gone at the next restart.
- **Run `skillhub_rules` before writing** — the rules decide table, note or skill.
- **Read whole objects with `skillhub_read`**, not from a search excerpt.

Both the MCP block and this one are re-applied on every boot, so edit the env, not the files. Restrict tools by adding under the same block by hand:

```yaml
    tools:
      exclude: [apply_migration]
```

Verify from the dashboard: `/reload-mcp`, then ask the agent to run `list_tables`.

## Local model (Ollama on host)

Ollama on the host is a custom endpoint, so it takes the named-entry route from
"Private AI" above. **Untested here** — there is no Ollama on this host; what is measured
is that `OPENAI_BASE_URL` and `OPENAI_API_KEY` alone do *not* move the model off the image
default, which is the whole point of the section above.

```
HERMES_MODEL=llama3.2
OPENAI_API_KEY=ollama
```

plus, once per agent:

```
hermes config set providers.ollama.base_url http://host.docker.internal:11434/v1
hermes config set model.provider custom:ollama
```

Leave `HERMES_MODEL_BASE_URL` empty: the endpoint comes from the `providers:` entry, and
setting `model.base_url` as well recreates exactly the contradiction described above.
