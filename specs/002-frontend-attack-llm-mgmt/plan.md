# Implementation Plan: Frontend Attack Creation & LLM Management

**Branch**: `002-frontend-attack-llm-mgmt` | **Date**: 2026-04-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-frontend-attack-llm-mgmt/spec.md`

## Summary

Add inline creation forms to the existing Attack Builder component so
users can register new LLM targets and define new attack templates
without leaving the run-building workflow. Also add browsable list
views for existing entries. This is frontend-only work — the backend
API and client functions already exist.

## Technical Context

**Language/Version**: JavaScript (ES2022+)
**Primary Dependencies**: React 18, Vite 6, TanStack Query 5, Recharts 2
**Storage**: N/A (frontend consumes existing REST API)
**Testing**: Manual verification (no test framework configured in frontend)
**Target Platform**: Modern browsers (desktop)
**Project Type**: Web application (frontend SPA)
**Performance Goals**: Forms submit and lists refresh within 2 seconds
**Constraints**: No backend changes; must match existing Servant API types exactly
**Scale/Scope**: 3 new components, 1 modified component (AttackBuilder.jsx)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Type-Safe Prompt Handling | N/A | Haskell backend concern; frontend sends Text via JSON |
| II. OWASP Taxonomy as ADT | PASS | Frontend will hardcode the 4 `OWASPCategory` values matching `DSL/OWASP.hs`; no free-text entry allowed (FR-005) |
| III. Servant as Single Source of Truth | PASS | Form field names match `LLMTargetRequest` and `AttackRequest` types from `API/Types.hs` exactly |
| IV. Reproducible Attack Runs | N/A | Creation forms, not run execution |
| V. No Hardcoded Endpoints | N/A | `api/client.js` BASE_URL is existing; out of scope |
| VI. Pluggable Evaluation | N/A | Not touched by this feature |
| VII. Strict Compilation | N/A | Frontend; no Haskell changes |

All gates pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/002-frontend-attack-llm-mgmt/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── api-request-shapes.md
└── tasks.md            # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
frontend/
├── src/
│   ├── api/
│   │   └── client.js          # existing — already has postTarget, postAttack
│   ├── components/
│   │   ├── AttackBuilder.jsx   # MODIFIED — add "Add new..." buttons
│   │   ├── AddTargetForm.jsx   # NEW — inline LLM target creation form
│   │   ├── AddAttackForm.jsx   # NEW — inline attack template creation form
│   │   ├── TargetList.jsx      # NEW — browsable list of LLM targets
│   │   ├── AttackList.jsx      # NEW — browsable list of attack templates
│   │   ├── Dashboard.jsx       # existing — unchanged
│   │   └── RunHistory.jsx      # existing — unchanged
│   ├── App.jsx                 # existing — unchanged
│   └── main.jsx                # existing — unchanged
└── package.json                # existing — no new dependencies needed
```

**Structure Decision**: Web application layout (Option 2). All new
files are React components in `frontend/src/components/`. No new
dependencies are required — React 18, TanStack Query, and the
existing `api/client.js` provide everything needed.

## Complexity Tracking

> No constitution violations. Table intentionally left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | | |
