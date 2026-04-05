# Implementation Plan: Edit & Delete LLM Targets and Attacks

**Branch**: `003-edit-delete-entries` | **Date**: 2026-04-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-edit-delete-entries/spec.md`

## Summary

Add edit and delete capabilities for LLM targets and attack templates.
This is a full-stack feature: the backend needs new PUT and DELETE
Servant endpoints with associated DB queries and run-reference checks,
and the frontend needs inline edit forms in list rows plus delete
buttons with confirmation prompts. CORS must also be updated to allow
PUT and DELETE methods.

## Technical Context

**Language/Version**: Haskell (GHC 9.6+, GHC2021), JavaScript (ES2022+)
**Primary Dependencies**: Servant, postgresql-simple (backend); React 18, TanStack Query 5 (frontend)
**Storage**: PostgreSQL (existing schema, no migrations needed)
**Testing**: `cabal test` (backend); manual verification (frontend)
**Target Platform**: Linux server + modern browsers
**Project Type**: Web application (full-stack)
**Performance Goals**: Edit/delete operations complete within 2 seconds
**Constraints**: Must match existing Servant API patterns; FK constraints prevent cascading deletes
**Scale/Scope**: 4 new backend endpoints, 4 new API client functions, 2 modified list components, CORS update

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Type-Safe Prompt Handling | N/A | No new prompt handling; edit sends Text via JSON same as create |
| II. OWASP Taxonomy as ADT | PASS | Edit form reuses existing `ATTACK_CATEGORIES` constant; no new categories |
| III. Servant as Single Source of Truth | PASS | New PUT/DELETE routes added to `API/Routes.hs`; frontend matches exactly |
| IV. Reproducible Attack Runs | N/A | Edit/delete don't affect run execution |
| V. No Hardcoded Endpoints | PASS | No new endpoint URLs hardcoded; reuses existing `api/client.js` pattern |
| VI. Pluggable Evaluation | N/A | Not touched |
| VII. Strict Compilation | PASS | All new Haskell code under `-Wall -Werror`; no use of `error`; `Either`/`ExceptT` for failures |

All gates pass.

## Project Structure

### Documentation (this feature)

```text
specs/003-edit-delete-entries/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── api-endpoints.md
└── tasks.md            # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
backend/
├── app/
│   └── Main.hs                 # MODIFIED — add PUT, DELETE to CORS methods
├── src/
│   ├── API/
│   │   ├── Routes.hs           # MODIFIED — add 4 new routes (PUT/DELETE targets, PUT/DELETE attacks)
│   │   ├── Types.hs            # EXISTING — reuse LLMTargetRequest, AttackRequest for updates
│   │   └── Handlers.hs         # MODIFIED — add 4 new handler functions
│   └── DB/
│       └── Queries.hs          # MODIFIED — add updateTarget, deleteTarget, updateAttack, deleteAttack, hasRunsForTarget, hasRunsForAttack

frontend/
├── src/
│   ├── api/
│   │   └── client.js           # MODIFIED — add putTarget, putAttack, deleteTarget, deleteAttack
│   ├── components/
│   │   ├── TargetList.jsx      # MODIFIED — add Edit/Delete buttons, inline edit form
│   │   ├── AttackList.jsx      # MODIFIED — add Edit/Delete buttons, inline edit form
│   │   ├── EditTargetForm.jsx  # NEW — inline edit form for targets (pre-populated)
│   │   └── EditAttackForm.jsx  # NEW — inline edit form for attacks (pre-populated)
│   └── constants.js            # EXISTING — unchanged
```

**Structure Decision**: Web application layout. Backend changes span
4 modules (Routes, Handlers, Queries, Main). Frontend adds 2 new
components and modifies 3 existing files.

## Complexity Tracking

> No constitution violations. Table intentionally left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *(none)* | | |
