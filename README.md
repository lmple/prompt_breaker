# prompt_breaker

LLM Prompt Injection Research Tool — a typed Haskell DSL for crafting and evaluating prompt injection attacks, with a React dashboard comparing Naive vs Sanitized success rates across OWASP LLM Top 10 categories.

## Prerequisites

- GHC 9.6+ via [ghcup](https://www.haskell.org/ghcup/) (system GHC on Arch won't work — see below)
- cabal-install 3.10+
- Node.js 20+
- Docker and Docker Compose
- PostgreSQL client libraries (`postgresql-libs` on Arch)
- Ollama with at least one model (`ollama pull llama3.2`)

### Arch Linux: GHC setup

The system GHC package on Arch only ships dynamic interface files, which breaks cabal dependency builds. Use ghcup instead:

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
source ~/.ghcup/env   # if not already in your profile
cd backend
cabal update           # first time only
cabal build
cabal run attack-harness
```

The API starts on http://localhost:8080.

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

## Project Structure

```
backend/
├── src/
│   ├── DSL/          # OWASP categories, Untrusted newtype, Attack ADT, Prompt builder
│   ├── Runner/       # LLM HTTP client, keyword-based evaluator
│   ├── DB/           # PostgreSQL row types and queries
│   └── API/          # Servant routes, JSON types, handlers
├── app/Main.hs       # Server entrypoint (Warp on :8080)
├── sql/              # DDL schema + dev seed data
└── backend.cabal

frontend/
├── src/
│   ├── components/   # Dashboard, AttackBuilder, RunHistory
│   ├── api/client.js # API fetch wrappers
│   ├── App.jsx       # Tab navigation shell
│   └── main.jsx      # React + TanStack Query entrypoint
├── index.html
└── vite.config.js

docker-compose.yml    # PostgreSQL 16
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
