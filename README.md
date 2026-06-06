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

Under the service's **Environment** tab, set at minimum:

```
OPENAI_BASE_URL=https://api.example.com/v1
OPENAI_API_KEY=your-key
HERMES_MODEL=gpt-4o
```

See [env.md](env.md) for all available variables.

### 4. Deploy

Hit **Deploy**. Easypanel starts the container — the dashboard is available on the port you configured.

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

`docker-compose.yml` always pulls `nousresearch/hermes-agent:latest`. To upgrade to the latest version of Hermes, just hit **Deploy** again in Easypanel.

## Persistence

Data is stored in Easypanel's project folder on the host:

```
/etc/easypanel/projects/<your-project>/
```

Everything is preserved across deploys and restarts.

---

## What is this?

Hermes Easy is a thin wrapper around the official Hermes image — a single `docker-compose.yml` with sensible defaults and documented environment variables, optimized for Easypanel.
