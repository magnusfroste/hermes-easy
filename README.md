# Hermes Easy

The fastest, simplest way to run [Hermes Agent](https://github.com/NousResearch/hermes-agent) on [Easypanel](https://easypanel.io).

No build step. No complex configuration. Just deploy and go.

---

## Getting Started

### 1. Create a Docker Compose service in Easypanel

In your Easypanel project: **Create Service → Docker Compose** and point it to this repo.

### 2. Connect the Git repo

Enter `https://github.com/magnusfroste/hermes-easy` as the source. Easypanel will pick up `docker-compose.yml` automatically.

### 3. Set your environment variables

Under the service's **Environment** tab, set at minimum a model provider, the dashboard
login, and (for a shared-data fleet) the Supabase MCP trio:

```
OPENAI_BASE_URL=https://api.example.com/v1   # your OpenAI-compatible endpoint, or drop both
OPENAI_API_KEY=your-key                       # OPENAI_* lines and set e.g. OPENROUTER_API_KEY
HERMES_MODEL=gpt-4o                           # bare model name; see env.md
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=alice
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=s3cret
HERMES_DASHBOARD_BASIC_AUTH_SECRET=<openssl rand -hex 32>
SUPABASE_MCP_URL=https://skillhub.example.com/mcp
SUPABASE_MCP_KEY=<MCP_KEY_NN from the Supabase service>
HERMES_AGENT_ID=agent_NN
```

The dashboard login is not optional: Hermes 2026.9+ refuses to start the dashboard on a
non-loopback bind without it. See [env.md](env.md) for all variables and [example.env](example.env).

### 4. Deploy

Hit **Deploy**, then add a **Domain** on the service pointing at port `9119`. There is no
host port; the dashboard is reached through that domain.

---

## Switching models & providers

You can switch provider/model live from the dashboard with the `/model` command.

The major providers have their **endpoints built into Hermes** — you only supply
the API key, never a URL:

| Set this env var | Provider |
|------------------|----------|
| `OPENROUTER_API_KEY` | OpenRouter (one key, many models) |
| `ANTHROPIC_API_KEY` | Anthropic Claude |
| `GEMINI_API_KEY` | Google Gemini |
| `DEEPSEEK_API_KEY` | DeepSeek |
| `GROQ_API_KEY` | Groq |
| `XAI_API_KEY` | xAI Grok |
| `MISTRAL_API_KEY` | Mistral |

For example, OpenRouter always routes to `https://openrouter.ai/api/v1` — set
`OPENROUTER_API_KEY`, pick a model in `/model`, done.

`OPENAI_BASE_URL` + `OPENAI_API_KEY` are **only** for your own
OpenAI-compatible endpoint (vLLM, Ollama, a custom box). Note: while
`OPENAI_BASE_URL` is set, Hermes treats the auto/default provider as that custom
endpoint — explicitly switching to another provider via `/model` still routes
correctly.

---

## Updating

`docker-compose.yml` pulls `nousresearch/hermes-agent:${HERMES_TAG:-latest}` on every
Redeploy. `latest` tracks upstream `main` and is usually ahead of the newest release; pin
`HERMES_TAG=v2026.9.7`-style tags when you want the same image every time.

## Persistence

All of Hermes's state lives in `/opt/data` (`HERMES_HOME`) on the named volume `data`
(`app_hermes_data` once Easypanel prefixes it): `config.yaml`, `SOUL.md`, sessions,
memories, skills, cron jobs, the browser profile, and the packages the agent installs
for itself (`HERMES_LAZY_INSTALL_TARGET=/opt/data/lazy-packages`, plus anything it puts
under `/opt/data/home`). A **Redeploy keeps all of it** — the container is replaced, the
volume is not.

Two things are *not* on the volume, by design:

- **Playwright browsers** ship inside the image (`/opt/hermes/.playwright`, ~266 MB), so
  they come back with every image. Do not repoint `PLAYWRIGHT_BROWSERS_PATH` at the data
  volume: that directory is empty and the browser tool would re-download the set.
- **System packages installed with `apt` at runtime.** Those live in the container layer
  and reset on every redeploy. The base image already has `git`, `ripgrep`, `curl`,
  `node`/`npm`/`npx`, `uv` and the `docker` CLI; it does **not** have `tmux`, `sudo` or a
  full `chromium`. If the agent needs those permanently, build a thin image on top instead
  of installing them at runtime:

  ```dockerfile
  FROM nousresearch/hermes-agent:latest
  USER root
  RUN apt-get update && apt-get install -y --no-install-recommends \
      tmux sudo python3-pip && rm -rf /var/lib/apt/lists/*
  ```

  and point the compose `image:` at it (Easypanel builds it on Deploy).

---

## What is this?

Hermes Easy is a thin wrapper around the official Hermes image — a single `docker-compose.yml` with sensible defaults and documented environment variables, optimized for Easypanel.
