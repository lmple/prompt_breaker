# Quickstart: Attack Harness

## Prerequisites

- GHC 9.6+ with cabal-install 3.10+
- Node.js 20+ with npm
- Docker and Docker Compose
- Ollama installed locally with at least one model pulled
  (e.g., `ollama pull llama3.2`)

## 1. Start the Database

```bash
docker compose up -d postgres
```

Wait a few seconds for PostgreSQL to initialize, then apply the schema
and seed data:

```bash
docker compose exec postgres psql -U harness -d attack_harness \
  -f /docker-entrypoint-initdb.d/schema.sql

docker compose exec postgres psql -U harness -d attack_harness \
  -f /docker-entrypoint-initdb.d/seed.sql
```

Alternatively, if running psql locally:

```bash
psql -h localhost -U harness -d attack_harness -f backend/sql/schema.sql
psql -h localhost -U harness -d attack_harness -f backend/sql/seed.sql
```

## 2. Build and Run the Backend

```bash
cd backend
cabal build
cabal run attack-harness
```

The API starts on `http://localhost:8080`.

## 3. Start the Frontend

```bash
cd frontend
npm install
npm run dev
```

The dashboard opens at `http://localhost:5173`.

## 4. Verify the Setup

Check that the API is running and seed data is loaded:

```bash
# List targets (should show 2 Ollama targets)
curl http://localhost:8080/targets

# List attack templates (should show 3 seed attacks)
curl http://localhost:8080/attacks
```

## 5. Run Your First Attack

Make sure Ollama is running (`ollama serve`), then:

```bash
curl -X POST http://localhost:8080/runs \
  -H "Content-Type: application/json" \
  -d '{
    "attackId": "<UUID from /attacks>",
    "targetId": "<UUID from /targets>",
    "strategy": "Naive",
    "systemPrompt": "You are a helpful assistant.",
    "evaluatorMethod": {"tag": "KeywordMatch", "contents": ["I cannot", "I'\''m unable", "I won'\''t"]}
  }'
```

The response includes `success`, `confidence`, and `rawResponse`.

## 6. View the Dashboard

Open `http://localhost:5173` in a browser. After running several attacks
with both Naive and Sanitized strategies, the dashboard will show
comparative success rates per OWASP category.

## Common Issues

- **Backend fails to connect to DB**: Ensure `docker compose up -d postgres`
  is running and the env vars match (`DB_HOST=localhost`, `DB_PORT=5432`,
  `DB_NAME=attack_harness`, `DB_USER=harness`, `DB_PASS=harness`).

- **Ollama returns errors**: Verify `ollama serve` is running and the
  model is pulled (`ollama list`).

- **CORS errors in browser**: The backend must allow requests from
  `http://localhost:5173`. Check that CORS middleware is configured.
