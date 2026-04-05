# prompt_breaker

LLM Prompt Injection Research Tool — a typed Haskell DSL for crafting and evaluating prompt injection attacks, with a React dashboard comparing Naive vs Sanitized success rates across OWASP LLM Top 10 categories.

## Features

- **Attack Builder**: Register LLM targets (base URL, model, API key) and create attack templates categorized by OWASP LLM Top 10
- **Edit & Delete**: Modify or remove targets and attack templates inline; deletion is blocked when run history exists
- **Attack strategies**: Naive (pass-through) vs Sanitized (Untrusted newtype sanitization)
- **Evaluators**: Keyword match and regex match on LLM responses
- **Dashboard**: Charts comparing naive vs sanitized success rates across OWASP categories
- **Run History**: Browse past attack runs with full results

## Prerequisites

- GHC 9.6+ via [ghcup](https://www.haskell.org/ghcup/) — **do not use the system GHC** (see platform notes below)
- cabal-install 3.10+
- Node.js 20+
- Docker and Docker Compose
- PostgreSQL client libraries
- Ollama with at least one model (`ollama pull llama3.2`)

### Platform: Arch Linux

The system GHC package on Arch only ships dynamic interface files, which breaks cabal dependency builds. Install via ghcup instead:

```bash
sudo pacman -S --needed base-devel postgresql-libs libffi
```

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
  BOOTSTRAP_HASKELL_GHC_VERSION=9.6.6 \
  BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.3.0 \
  BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 sh
```

Then add to your shell profile:

```bash
source ~/.ghcup/env
```

### Platform: Ubuntu 22.04 / 24.04

The system GHC from `apt` is too old. Install system dependencies first, then use ghcup:

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential curl git \
  libpq-dev libffi-dev libgmp-dev zlib1g-dev \
  nodejs npm docker.io docker-compose-plugin
```

Install ghcup (installs GHC 9.6.6 and cabal 3.10):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
  BOOTSTRAP_HASKELL_GHC_VERSION=9.6.6 \
  BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.3.0 \
  BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 sh
```

Add to your shell profile (`~/.bashrc` or `~/.profile`):

```bash
source ~/.ghcup/env
```

Install Node.js 20 if the apt version is too old (Ubuntu 22.04 ships Node 12):

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Add your user to the `docker` group to run Docker without sudo:

```bash
sudo usermod -aG docker $USER   # log out and back in after this
```

## Quick Start

### 1. Start the database

```bash
docker compose up -d postgres
```

Apply schema and seed data (wait a few seconds for Postgres to init):

```bash
psql -h localhost -U harness -d attack_harness -f backend/sql/schema.sql
psql -h localhost -U harness -d attack_harness -f backend/sql/seed.sql
```

### 2. Build and run the backend

```bash
source ~/.ghcup/env   # if not already in your shell profile
cd backend
cabal update           # first time only — fetches package index
cabal build
cabal run attack-harness
```

The API starts on http://localhost:8080.

> **Note**: The first `cabal build` compiles all dependencies from source and can take 10–20 minutes. Subsequent builds are incremental and fast.

### 3. Start the frontend

```bash
cd frontend
npm install
npm run dev
```

The dashboard opens at http://localhost:5173.

### 4. Verify

```bash
curl http://localhost:8080/targets   # should return 2 Ollama targets
curl http://localhost:8080/attacks   # should return 3 seed attacks
```

### 5. Run an attack

Make sure Ollama is running (`ollama serve`), then:

```bash
curl -X POST http://localhost:8080/runs \
  -H "Content-Type: application/json" \
  -d '{
    "rrqAttackId": "<UUID from /attacks>",
    "rrqTargetId": "<UUID from /targets>",
    "rrqStrategy": "Naive",
    "rrqSystemPrompt": "You are a helpful assistant.",
    "rrqEvaluatorMethod": {"tag": "KeywordMatch", "contents": ["I cannot", "I'\''m unable"]}
  }'
```

Or use the Attack Builder in the browser at http://localhost:5173.

## API Reference

All endpoints return JSON. The backend runs on `http://localhost:8080`.

### LLM Targets

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/targets` | List all registered LLM targets |
| `POST` | `/targets` | Create a new LLM target |
| `PUT` | `/targets/:id` | Update an existing LLM target |
| `DELETE` | `/targets/:id` | Delete a target (blocked if it has run history) |

**Target object**:
```json
{
  "ltId": "uuid",
  "ltName": "Local Ollama",
  "ltBaseUrl": "http://localhost:11434",
  "ltModel": "llama3.2",
  "ltApiKey": null,
  "ltCreatedAt": "2026-04-05T12:00:00Z"
}
```

**Create/Update request** (`ltrApiKey`: `null` = keep existing on update, `""` = remove, string = set):
```json
{
  "ltrName": "Local Ollama",
  "ltrBaseUrl": "http://localhost:11434",
  "ltrModel": "llama3.2",
  "ltrApiKey": null
}
```

### Attack Templates

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/attacks` | List all attack templates |
| `POST` | `/attacks` | Create a new attack template |
| `PUT` | `/attacks/:id` | Update an existing attack template |
| `DELETE` | `/attacks/:id` | Delete a template (blocked if it has run history) |

**Attack object**:
```json
{
  "atId": "uuid",
  "atCategory": "Jailbreak",
  "atTechnique": "Roleplay",
  "atPayload": "Ignore all previous instructions...",
  "atDescription": "Roleplay jailbreak attempt",
  "atOwaspRef": "LLM01_PromptInjection",
  "atCreatedAt": "2026-04-05T12:00:00Z"
}
```

Valid `atCategory` values: `DirectInjection`, `IndirectInjection`, `Jailbreak`, `PromptLeaking`

Valid `atTechnique` values (required when category is `Jailbreak`, null otherwise): `Roleplay`, `Hypothetical`, `Encoding`, `Fragmentation`

### Runs

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/runs` | List all attack runs (newest first) |
| `POST` | `/runs` | Execute an attack against a target |
| `GET` | `/runs/:id` | Get a single run result |

**Run request**:
```json
{
  "rrqAttackId": "uuid",
  "rrqTargetId": "uuid",
  "rrqStrategy": "Naive",
  "rrqSystemPrompt": "You are a helpful assistant.",
  "rrqEvaluatorMethod": {"tag": "KeywordMatch", "contents": ["I cannot", "I'm unable"]}
}
```

Valid `rrqStrategy` values: `Naive`, `Sanitized`

Valid `rrqEvaluatorMethod` values:
```json
{"tag": "KeywordMatch", "contents": ["keyword1", "keyword2"]}
{"tag": "RegexMatch",   "contents": ["regex pattern"]}
```

### Stats

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/stats` | Success rates by OWASP category and strategy |

## Project Structure

```
backend/
├── src/
│   ├── DSL/          # OWASP categories, Untrusted newtype, Attack ADT, Prompt builder
│   ├── Runner/       # LLM HTTP client, keyword/regex evaluator
│   ├── DB/           # PostgreSQL row types and queries
│   └── API/          # Servant routes, JSON types, handlers
├── app/Main.hs       # Server entrypoint (Warp on :8080, CORS configured)
├── sql/
│   ├── schema.sql    # DDL — creates tables with FK constraints
│   └── seed.sql      # Dev seed data (2 targets, 3 attacks)
└── backend.cabal

frontend/
├── src/
│   ├── components/
│   │   ├── Dashboard.jsx        # Success rate charts (Recharts)
│   │   ├── AttackBuilder.jsx    # Main attack configuration UI
│   │   ├── TargetList.jsx       # Registered targets table with edit/delete
│   │   ├── AttackList.jsx       # Attack templates table with edit/delete
│   │   ├── AddTargetForm.jsx    # Inline create form for targets
│   │   ├── AddAttackForm.jsx    # Inline create form for attacks
│   │   ├── EditTargetForm.jsx   # Inline edit form for targets
│   │   ├── EditAttackForm.jsx   # Inline edit form for attacks
│   │   └── RunHistory.jsx       # Past run results
│   ├── api/client.js            # fetch wrappers for all API endpoints
│   ├── constants.js             # ATTACK_CATEGORIES and JAILBREAK_TECHNIQUES
│   ├── App.jsx                  # Tab navigation shell
│   └── main.jsx                 # React + TanStack Query entrypoint
├── index.html
└── vite.config.js

docker-compose.yml    # PostgreSQL 16
specs/                # Feature specifications (speckit workflow)
```

## Environment Variables

The backend reads DB connection from env vars (defaults match docker-compose):

| Variable  | Default          |
|-----------|------------------|
| `DB_HOST` | `localhost`      |
| `DB_PORT` | `5432`           |
| `DB_NAME` | `attack_harness` |
| `DB_USER` | `harness`        |
| `DB_PASS` | `harness`        |

## Troubleshooting

**`cabal build` fails with "Could not find module 'Prelude'"**
The system GHC is being used instead of the ghcup one. Run `source ~/.ghcup/env` and verify `which ghc` points to `~/.ghcup/bin/ghc`.

**`psql: error: connection to server failed`**
The Postgres container may still be starting. Wait 5–10 seconds after `docker compose up -d postgres` before running the schema scripts.

**`ollama: command not found`**
Install Ollama from https://ollama.com and run `ollama serve` in a separate terminal. Then `ollama pull llama3.2` to download a model.

**Frontend shows empty lists after adding entries**
Check the browser console for CORS or network errors. Confirm the backend is running on port 8080 (`curl http://localhost:8080/targets`).

**Delete blocked with "has associated run history"**
This is intentional — runs are the primary research output and cannot be orphaned. To remove a target or attack that has runs, you must first delete the runs directly in the database:
```sql
DELETE FROM runs WHERE target_id = '<uuid>';
```
