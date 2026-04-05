# Implementation Plan: Attack Harness

**Branch**: `001-attack-harness-impl` | **Date**: 2026-04-04 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-attack-harness-impl/spec.md`

## Summary

Build a typed Haskell DSL for LLM prompt injection attacks with a Servant
REST API, PostgreSQL persistence, keyword-based evaluation, and a React
dashboard comparing Naive vs. Sanitized attack success rates across OWASP
LLM Top 10 categories. The core research question: does wrapping user input
in a typed `Untrusted` slot + sanitization reduce attack success rate vs
naive string interpolation?

## Technical Context

**Language/Version**: Haskell (GHC 9.6+, GHC2021 edition), JavaScript (ES2022+)
**Primary Dependencies**: Servant, postgresql-simple, req, aeson, uuid (backend); React 18, Vite, Recharts, TanStack Query (frontend)
**Storage**: PostgreSQL 16 (via Docker Compose)
**Testing**: cabal test (HUnit/Hspec), manual API testing via curl
**Target Platform**: Linux (local development machine)
**Project Type**: Web service (Haskell API backend) + SPA frontend
**Performance Goals**: Single-user research tool; no high-throughput requirements
**Constraints**: Temperature 0.0 for reproducibility; all payloads wrapped in Untrusted newtype
**Scale/Scope**: Single researcher, ~100s of attack runs, 4 OWASP categories, 3 frontend views

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Type-Safe Prompt Handling | PASS | `Untrusted` newtype in DSL/Sanitizer.hs; all payloads wrapped at construction in DSL/Attack.hs builder functions. `Text` only, no `String`. |
| II | OWASP Taxonomy as ADT | PASS | `OWASPCategory` ADT in DSL/OWASP.hs with 4 constructors; `deriving Enum, Bounded` enables exhaustive coverage. |
| III | Servant as Single Source of Truth | PASS | `type API` in API/Routes.hs defines all 8 endpoints; handlers and frontend client derive from it. |
| IV | Reproducible Attack Runs | PASS | Temperature hardcoded to 0.0 in Runner/LLM.hs `complete` function. |
| V | No Hardcoded Endpoints | PASS | `LLMTarget` read from `llm_targets` DB table at runtime; no URL literals in source. |
| VI | Pluggable Evaluation | PASS | `EvaluatorMethod` ADT with `KeywordMatch`, `RegexMatch`, `LLMJudge` constructors; `evaluate` dispatches by pattern match. |
| VII | Strict Compilation | PASS | `GHC2021` default language, `-Wall -Werror` in cabal file; `Either`/`ExceptT` for errors, no `error` calls. |

**Gate result**: ALL PASS — proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-attack-harness-impl/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api.md
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── DSL/
│   │   ├── OWASP.hs          # OWASPCategory ADT + descriptions
│   │   ├── Sanitizer.hs      # Untrusted newtype + sanitize
│   │   ├── Attack.hs         # Attack ADT + builder DSL
│   │   └── Prompt.hs         # PromptStrategy + buildMessages
│   ├── Runner/
│   │   ├── LLM.hs            # HTTP client for Ollama/vLLM
│   │   └── Evaluator.hs      # EvaluatorMethod + evaluate
│   ├── DB/
│   │   ├── Schema.hs         # Table definitions
│   │   └── Queries.hs        # CRUD queries
│   └── API/
│       ├── Types.hs          # JSON request/response types
│       ├── Routes.hs         # Servant API type
│       └── Handlers.hs       # Route implementations
├── app/
│   └── Main.hs               # Server entrypoint
├── test/
│   └── Spec.hs               # Test suite
├── sql/
│   ├── schema.sql             # DDL
│   └── seed.sql               # Dev seed data
└── backend.cabal

frontend/
├── src/
│   ├── components/
│   │   ├── Dashboard.jsx      # Charts + summary cards
│   │   ├── AttackBuilder.jsx  # Run attack form
│   │   └── RunHistory.jsx     # Run history table
│   ├── api/
│   │   └── client.js          # API client functions
│   ├── App.jsx
│   └── main.jsx
├── index.html
├── vite.config.js
└── package.json

docker-compose.yml                 # PostgreSQL + backend
```

**Structure Decision**: Web application layout (backend + frontend). The
Haskell backend uses a flat module hierarchy under `src/` matching the DSL,
Runner, DB, and API layers from the spec. The React frontend is a standard
Vite SPA. SQL files live alongside the backend for schema management.

## Complexity Tracking

> No constitution violations — table intentionally left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    |            |                                     |
