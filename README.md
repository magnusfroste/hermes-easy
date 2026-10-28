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
HERMES_EASY_MODEL=openai-api/gpt-5.6-luna     # provider/model; prefix = a HERMES_PROVIDERS id or a catalogue slug (plain `openai` does not exist)
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=alice
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=s3cret
HERMES_DASHBOARD_BASIC_AUTH_SECRET=<openssl rand -hex 32>
SUPABASE_MCP_URL=https://skillhub.example.com/mcp
SUPABASE_MCP_KEY=<MCP_KEY_NN from the Supabase service>
HERMES_AGENT_ID=agent_NN
```

The dashboard login is not optional: Hermes 2026.9+ refuses to start the dashboard on a
non-loopback bind without it. See [env.md](env.md) for all variables and [example.env](example.env).

`HERMES_EASY_MODEL` was called `HERMES_MODEL` until 2026-10. The old name still works in the
panel, but it is no longer passed to Hermes itself, which reads `HERMES_MODEL` on its own and
split a served name like `garageai/auto` into provider + `auto`. See env.md.

### 4. Deploy

Hit **Deploy**, then add a **Domain** on the service pointing at port `9119`. There is no
host port; the dashboard is reached through that domain. The container reports healthy once
`/api/health` answers (open without login; it covers the dashboard, not the model endpoint).

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

`docker-compose.yml` builds on `nousresearch/hermes-agent:${HERMES_TAG:-latest}` and re-pulls
the base on every Redeploy. Since v0.22.0 upstream moves `latest` (and `stable`) only when a
release is cut, so an unset tag means the newest release; pin `HERMES_TAG=v0.22.5`-style tags
when you want the same image every time.

## Persistence

All of Hermes's state lives in `/opt/data` (`HERMES_HOME`) on the named volume `data`
(`app_hermes_data` once Easypanel prefixes it): `config.yaml`, `SOUL.md`, sessions,
memories, skills, cron jobs, the browser profile, and the packages the agent installs
for itself (`HERMES_LAZY_INSTALL_TARGET=/opt/data/lazy-packages`, plus anything it puts
under `/opt/data/home`). A **Redeploy keeps all of it** — the container is replaced, the
volume is not.

## What this image adds

Built from the `Dockerfile` beside `docker-compose.yml`: upstream's image plus two things,
because the shared data store asks an agent to read what it was handed and then publish what
it says.

- **`poppler-utils`** — `pdftotext`, `pdfinfo`, `pdftoppm`. Measured on a 159 KB quality
  manual: 22,909 characters of text in about 90 milliseconds. Without it an agent asked to
  put that manual in the store started OCR, spent minutes on it, and was interrupted — for a
  document that was never scanned in the first place.
- **`openpyxl`**, into `/opt/hermes/.venv`, which is the interpreter Hermes' own tools run
  in. The store's loader takes CSV, so a spreadsheet has to be converted before it can be
  handed over.

Deliberately absent: `tesseract`. It is right for a scanned page and the wrong first
instinct for everything else, it costs about 100 MB with its language data, and having it
available is how an agent ends up running it on a PDF that already holds text. Add it the day
a scanned document turns up.

`HERMES_TAG` still chooses the base, and a Redeploy rebuilds on top of it.

Two things are *not* on the volume, by design:

- **Playwright browsers** ship inside the image, and the image's own
  `PLAYWRIGHT_BROWSERS_PATH` points at them (`/opt/hermes/tools` on v0.22; it has moved
  before), so they come back with every image. This compose file does **not** set the
  variable, so the image's value always wins. Do not set it in the panel: pointed at the data
  volume it finds an empty directory and the browser tool re-downloads the set, and an
  **empty** value overrides the image's `ENV` so the tool scans `$HOME/.cache/ms-playwright`
  and reports that there is no browser. Measured 2026-09-17: an agent asked to log in to a
  website found no browser, downloaded a 293 MB Chrome of its own into the volume, and still
  could not see it. Until 2026-10 this file defaulted the variable to
  `/opt/hermes/.playwright`, which later images no longer have -- the same failure again.
  `/dev/shm` is raised to 1 GB (`shm_size`) because Chromium uses it for renderer memory and
  Docker's 64 MB default crashes heavier pages.
- **System packages installed with `apt` at runtime.** Those live in the container layer
  and reset on every redeploy, and the agent cannot install them anyway: it runs as the
  unprivileged `hermes` user and the image ships no `sudo`.

  Language-level installs *are* handled by environment variables, no image build needed.
  The compose file sets `NPM_CONFIG_PREFIX`, `UV_TOOL_DIR` and `UV_TOOL_BIN_DIR` to
  `/opt/data/.local`, which is on the volume **and** already on the image's `PATH`, so
  `npm install -g <tool>` and `uv tool install <tool>` survive a redeploy and stay
  callable. Python packages Hermes installs for itself already land in
  `/opt/data/lazy-packages` (the image's own `HERMES_LAZY_INSTALL_TARGET`).

  Only real system packages need an image. The base image already has `git`, `ripgrep`,
  `curl`, `node`/`npm`/`npx`, `uv` and the `docker` CLI; it does **not** have `tmux`,
  `sudo` or a full `chromium`. "Thin" here means a two-instruction file — upstream's image
  plus one `apt-get` layer, no source build, no application code — the same pattern
  `openclaw-easy` uses:

  ```dockerfile
  FROM nousresearch/hermes-agent:latest
  USER root
  RUN apt-get update && apt-get install -y --no-install-recommends \
      tmux sudo python3-pip && rm -rf /var/lib/apt/lists/*
  ```

  Then swap the `image:` line for a `build: .` in `docker-compose.yml`; Easypanel builds it
  on Deploy. That is the only reason to add a build step here — everything else is env.

---

## What is this?

Hermes Easy is a thin wrapper around the official Hermes image — a single `docker-compose.yml` with sensible defaults and documented environment variables, optimized for Easypanel.
