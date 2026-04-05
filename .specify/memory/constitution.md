<!-- Sync Impact Report
Version change: 0.0.0 → 1.0.0 (initial ratification)
Modified principles: N/A (initial)
Added sections:
  - Core Principles (I–VII)
  - Technology Constraints
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md — ✅ no changes needed (generic)
  - .specify/templates/spec-template.md — ✅ no changes needed (generic)
  - .specify/templates/tasks-template.md — ✅ no changes needed (generic)
  - .specify/templates/commands/ — no command files exist yet
Follow-up TODOs: none
-->

# Attack Harness Constitution

## Core Principles

### I. Type-Safe Prompt Handling (NON-NEGOTIABLE)

All user-supplied content MUST be wrapped in the `Untrusted` newtype
defined in `DSL/Sanitizer.hs`. Plain `Text` values MUST NOT carry
untrusted input. `String` MUST NOT be used for prompt content anywhere
in the codebase — always `Text`.

**Rationale**: The project tests prompt injection attacks; confusing
trusted and untrusted content in the harness itself would undermine
the entire security model.

### II. OWASP Taxonomy as ADT

All attack categories MUST map to the `OWASPCategory` algebraic data
type in `DSL/OWASP.hs`. New OWASP categories MUST NOT be introduced
without updating that module first.

**Rationale**: A closed ADT ensures exhaustive pattern matching — the
compiler catches missing cases when categories change.

### III. Servant as Single Source of Truth

The Servant API definition in `API/Routes.hs` is the authoritative
specification for all request and response shapes. Frontend client
code and handler implementations MUST conform to it.

**Rationale**: Servant's type-level API guarantees that serialization,
routing, and documentation stay in sync without manual coordination.

### IV. Reproducible Attack Runs

Temperature MUST be set to `0.0` for all attack requests sent to LLM
targets. Any parameter that introduces non-determinism MUST be
documented and justified if deviating from deterministic defaults.

**Rationale**: Reproducibility is essential for comparing attack
success rates across runs and targets.

### V. No Hardcoded Endpoints

LLM target configuration (URL, model name, API variant) MUST be read
from the `llm_targets` database table or equivalent runtime config.
Endpoint URLs MUST NOT appear as string literals in source code.

**Rationale**: The harness targets multiple backends (Ollama, vLLM);
hardcoding defeats multi-target testing.

### VI. Pluggable Evaluation

The success-detection pipeline in `Runner/Evaluator.hs` MUST support
swappable evaluator strategies (e.g., `KeywordMatch`, future
`LLMJudge`). New strategies MUST implement a common interface.

**Rationale**: Different attack types require different success
criteria; a fixed evaluator would limit research flexibility.

### VII. Strict Compilation

The project MUST use `GHC2021` as the default language edition and
enforce `-Wall -Werror`. Library code MUST NOT use `error` — use
`Either` or `ExceptT` for recoverable failures.

**Rationale**: `-Werror` catches regressions early; banning `error`
prevents partial functions from crashing long-running attack batches.

## Technology Constraints

- **Backend**: Haskell, Cabal (never `stack`), Servant,
  postgresql-simple, req.
- **Frontend**: React (Vite), Recharts, TanStack Query.
- **Database**: PostgreSQL.
- **LLM targets**: Ollama / vLLM via OpenAI-compatible
  `/v1/chat/completions` endpoint.
- **Build tool**: `cabal build` exclusively. Dependencies pinned via
  `cabal.project` freeze file.
- **Language edition**: `GHC2021` — common extensions are included by
  default; do not redundantly enable them per module.

## Development Workflow

- **Build**: `cd backend && cabal build`
- **Test**: `cd backend && cabal test`
- **Run**: `cd backend && cabal run attack-harness`
- **Frontend**: `cd frontend && npm install && npm run dev`
- **Database**: `docker compose up -d postgres`
- All code changes MUST compile cleanly under `-Wall -Werror` before
  being considered complete.
- Commits SHOULD be small and focused; each commit MUST leave the
  project in a buildable state.

## Governance

This constitution is the highest-authority document for development
decisions in the attack-harness project. When in conflict with ad-hoc
guidance, the constitution prevails.

**Amendment procedure**:
1. Propose the change with rationale.
2. Document the delta (old → new) in the Sync Impact Report comment.
3. Bump the version per semantic versioning (see below).
4. Verify consistency with dependent templates.

**Versioning policy**:
- MAJOR: Principle removed or redefined incompatibly.
- MINOR: New principle or section added, or existing principle
  materially expanded.
- PATCH: Wording clarifications, typo fixes, non-semantic edits.

**Compliance**: All implementation plans and code reviews MUST verify
alignment with the principles above. Deviations MUST be justified in
the plan's Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-04-04 | **Last Amended**: 2026-04-04
