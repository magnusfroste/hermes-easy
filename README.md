# Hermes Easy

Det snabbaste, enklaste sättet att köra [Hermes Agent](https://github.com/NousResearch/hermes-agent) på [Easypanel](https://easypanel.io).

Ingen byggtid. Ingen konfiguration. Bara deploy och kör.

---

## Kom igång

### 1. Skapa en Docker Compose-service i Easypanel

I ditt Easypanel-projekt: **Create Service → Docker Compose** och peka på detta repo.

### 2. Anslut Git-repot

Ange `https://github.com/magnusfroste/hermes-easy` som källa. Easypanel hämtar `docker-compose.yml` automatiskt.

### 3. Klistra in env-variabler

Under servicens **Environment**-flik, fyll i minst:

```
OPENAI_BASE_URL=https://api.example.com/v1
OPENAI_API_KEY=din-nyckel
HERMES_MODEL=gpt-4o
```

Se [env.md](env.md) för alla tillgängliga variabler.

### 4. Deploya

Tryck **Deploy**. Easypanel startar containern — dashboarden är tillgänglig på den port du konfigurerat.

---

## Uppdatera

`docker-compose.yml` använder alltid `nousresearch/hermes-agent:latest`. För att uppgradera till senaste versionen av Hermes: tryck **Deploy** igen i Easypanel så dras den nya imagen.

## Persistens

Data lagras i Easypanels projektmapp på hosten:

```
/etc/easypanel/projects/<projektnamn>/
```

Allt bevaras mellan deploys och omstarter.

---

## Vad är detta?

Hermes Easy är ett tunt lager ovanpå den officiella Hermes-imagen — en enda `docker-compose.yml` med rimliga defaults och dokumenterade env-variabler, optimerad för Easypanel.
