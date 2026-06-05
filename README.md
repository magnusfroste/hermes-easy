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
