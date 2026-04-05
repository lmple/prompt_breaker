# Tasks: Attack Harness

**Input**: Design documents from `/specs/001-attack-harness-impl/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/api.md

**Tests**: Not explicitly requested in the spec. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Project initialization, build tooling, and infrastructure files

- [x] T001 Create backend/backend.cabal with GHC2021 default-language, -Wall -Werror ghc-options, and dependencies: base, servant, servant-server, warp, aeson, text, uuid, postgresql-simple, req, http-client, wai-cors, time
- [x] T002 [P] Create frontend project: frontend/package.json, frontend/vite.config.js, frontend/index.html with dependencies react, react-dom, recharts, @tanstack/react-query
- [x] T003 [P] Create docker-compose.yml with postgres service (image postgres:16, DB attack_harness, user harness, password harness, port 5432, pgdata volume)
- [x] T004 [P] Create backend/sql/schema.sql with DDL: pgcrypto extension, llm_targets table, attack_templates table, runs table with foreign keys and indexes per data-model.md
- [x] T005 [P] Create backend/sql/seed.sql with dev seed data: 2 Ollama targets (llama3.2, mistral) and 3 attack templates (DirectInjection, Jailbreak/Roleplay, PromptLeaking)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: DSL types, DB row types, API types, and route definition that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 [P] Implement backend/src/DSL/OWASP.hs — OWASPCategory ADT with 4 constructors (LLM01_PromptInjection, LLM02_InsecureOutputHandling, LLM06_SensitiveInfoDisclosure, LLM07_InsecurePluginDesign), deriving Show/Eq/Ord/Enum/Bounded/Generic/ToJSON/FromJSON, and owaspDescription function
- [x] T007 [P] Implement backend/src/DSL/Sanitizer.hs — Untrusted newtype wrapping Text with getUntrusted accessor, sanitize function that strips and replaces blocklist phrases with [REDACTED]
- [x] T008 [P] Implement backend/src/Runner/Evaluator.hs — EvaluatorMethod ADT (KeywordMatch [Text], RegexMatch Text, LLMJudge Text) with ToJSON/FromJSON, EvalResult record (success, confidence, reasoning), evaluate function implementing KeywordMatch (refusal phrases, confidence scoring per research.md)
- [x] T009 Implement backend/src/DSL/Attack.hs — JailbreakTechnique enum, AttackCategory tagged union, Attack record with Maybe UUID / AttackCategory / Untrusted / Text / OWASPCategory fields, builder functions directInjection, jailbreak, promptLeak (depends on T006, T007)
- [x] T010 Implement backend/src/DSL/Prompt.hs — PromptStrategy enum (Naive/Sanitized) with ToJSON/FromJSON, ChatMessage record (role, content), buildMessages function that applies sanitize for Sanitized strategy (depends on T007, T009)
- [x] T011 Implement backend/src/DB/Schema.hs — Haskell record types mirroring DB tables: LLMTargetRow, AttackTemplateRow, RunRow with FromRow/ToRow instances for postgresql-simple (depends on T006, T009)
- [x] T012 Implement backend/src/API/Types.hs — JSON request/response types: LLMTargetRequest, AttackRequest, RunRequest, RunResult, LLMTarget, AttackTemplate, Stats, CategoryStats with ToJSON/FromJSON instances per contracts/api.md (depends on T006, T007, T008, T009)
- [x] T013 Implement backend/src/API/Routes.hs — Servant type API with all 8 endpoints: GET/POST /targets, GET/POST /attacks, GET/POST /runs, GET /runs/:id, GET /stats (depends on T012)

**Checkpoint**: Foundation ready — all types compile, user story implementation can begin

---

## Phase 3: User Story 1 — Run a Single Attack (Priority: P1) MVP

**Goal**: Execute an attack against an LLM target with Naive or Sanitized strategy, evaluate the response, persist and return the result

**Independent Test**: POST a run request via curl with a pre-seeded attack and target, verify the response contains success flag, confidence, and raw LLM response

- [x] T014 [P] [US1] Implement backend/src/Runner/LLM.hs — LLMTarget config record (baseUrl, model, apiKey), complete function that POSTs to /v1/chat/completions via req with temperature 0.0 and returns Either Text Text
- [x] T015 [P] [US1] Implement run-related queries in backend/src/DB/Queries.hs — connectDB helper, insertRun, getRun (by UUID), getRuns (list all with joined attack+target data)
- [x] T016 [US1] Implement run handlers in backend/src/API/Handlers.hs — postRun handler (load attack+target from DB, buildMessages with strategy, call LLM complete, evaluate response, insertRun, return RunResult), getRuns handler, getRunById handler (depends on T014, T015)
- [x] T017 [US1] Implement backend/app/Main.hs — read DB config from env vars, establish postgresql-simple Connection, configure wai-cors middleware for localhost:5173, start Warp server on port 8080 serving the Servant API (depends on T016)

**Checkpoint**: Backend compiles and runs. `curl -X POST localhost:8080/runs` executes an attack end-to-end (requires seed data in DB and Ollama running)

---

## Phase 4: User Story 2 — Manage Templates & Targets (Priority: P2)

**Goal**: CRUD endpoints for LLM targets and attack templates so researchers can build a reusable library

**Independent Test**: POST a new target via curl, GET /targets to verify it appears; POST a new attack template, GET /attacks to verify it appears with correct OWASP ref

- [x] T018 [P] [US2] Add target and attack queries to backend/src/DB/Queries.hs — insertTarget (with unique name conflict handling), getTargets, insertAttack (with OWASP validation), getAttacks
- [x] T019 [US2] Add target and attack handlers to backend/src/API/Handlers.hs — postTarget, getTargets, postAttack, getAttacks handlers; wire into the Servant server in app/Main.hs (depends on T018)

**Checkpoint**: All 8 API endpoints operational. Researchers can manage their attack library and run attacks via curl

---

## Phase 5: User Story 3 — Dashboard (Priority: P3)

**Goal**: React dashboard showing comparative success rates per OWASP category (Naive vs Sanitized) with summary cards

**Independent Test**: Load localhost:5173 with pre-seeded run data, verify bar chart renders correct rates and summary cards show totals

- [x] T020 [US3] Add getStats query to backend/src/DB/Queries.hs — SQL GROUP BY owasp_ref and prompt_strategy computing success rates and total runs per category
- [x] T021 [US3] Add stats handler to backend/src/API/Handlers.hs — getStats handler returning Stats with byCategory list (depends on T020)
- [x] T022 [P] [US3] Implement frontend/src/api/client.js — fetch wrappers for all API endpoints: getAttacks, getTargets, getRuns, getStats, postRun, postTarget, postAttack per contracts/api.md
- [x] T023 [US3] Implement frontend/src/components/Dashboard.jsx — Recharts BarChart with grouped bars (Naive vs Sanitized) per OWASP category, summary cards (total runs, naive rate, sanitized rate, most vulnerable category) using TanStack Query useQuery for /stats (depends on T022)
- [x] T024 [US3] Implement frontend/src/App.jsx — app shell with navigation (Dashboard, Attack Builder, Run History tabs), React Router or simple tab state
- [x] T025 [US3] Implement frontend/src/main.jsx — mount App with QueryClientProvider from @tanstack/react-query

**Checkpoint**: Dashboard renders with live data from the API. Researcher can visually compare Naive vs Sanitized success rates

---

## Phase 6: User Story 4 — Run History & Attack Builder (Priority: P4)

**Goal**: Table view of past runs with filtering, and a form to build and execute new attacks from the browser

**Independent Test**: Load Run History with pre-seeded runs, filter by OWASP category, expand a row to see raw response. Use Attack Builder to submit a run and verify it appears in history

- [x] T026 [P] [US4] Implement frontend/src/components/AttackBuilder.jsx — form with attack template dropdown, target dropdown, strategy radio (Naive/Sanitized), system prompt textarea, run button; POST /runs via useMutation, display inline result
- [x] T027 [P] [US4] Implement frontend/src/components/RunHistory.jsx — table (attack, target, model, strategy, success checkmark, confidence, timestamp) using useQuery for /runs; filter dropdowns for OWASP category and strategy; expandable rows showing raw LLM response

**Checkpoint**: All 4 user stories complete. Full research workflow available in browser

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation, cleanup, and end-to-end verification

- [x] T028 [P] Verify cabal build compiles cleanly with -Wall -Werror (fix any warnings)
- [x] T029 [P] Validate quickstart.md end-to-end: docker compose up, schema+seed, cabal run, npm run dev, curl test
- [x] T030 [P] Verify seed data loads correctly and API returns expected seed targets and attacks

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T001 (cabal project exists); T006/T007/T008 can start in parallel once T001 is done
- **User Stories (Phase 3+)**: All depend on Foundational phase (Phase 2) completion
  - US1 (Phase 3) can start immediately after Phase 2
  - US2 (Phase 4) can start immediately after Phase 2 (parallel with US1 if desired)
  - US3 (Phase 5) depends on US1 + US2 (needs working API for frontend)
  - US4 (Phase 6) depends on US3 (needs App.jsx shell and api/client.js)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2. No dependency on other stories
- **US2 (P2)**: Requires Phase 2. No dependency on other stories. Can run in parallel with US1
- **US3 (P3)**: Requires US1 + US2 (frontend needs all API endpoints working)
- **US4 (P4)**: Requires US3 (shares App.jsx shell and api/client.js)

### Within Each User Story

- Models/queries before handlers
- Handlers before Main.hs wiring
- Backend API working before frontend components
- Story complete before moving to next priority

### Parallel Opportunities

- T002, T003, T004, T005 can all run in parallel (Phase 1)
- T006, T007, T008 can all run in parallel (Phase 2 — no interdependencies)
- T014, T015 can run in parallel within US1
- T018 can run in parallel with US1 work
- T022 can run in parallel with T020/T021 (frontend client vs backend stats)
- T026, T027 can run in parallel (different React components)
- T028, T029, T030 can all run in parallel (Phase 7)

---

## Parallel Examples

### Phase 1: Setup (all parallel)

```text
Task: T001 — backend.cabal
Task: T002 — frontend project init
Task: T003 — docker-compose.yml
Task: T004 — schema.sql
Task: T005 — seed.sql
```

### Phase 2: First wave (parallel)

```text
Task: T006 — DSL/OWASP.hs
Task: T007 — DSL/Sanitizer.hs
Task: T008 — Runner/Evaluator.hs
```

### Phase 3: US1 first wave (parallel)

```text
Task: T014 — Runner/LLM.hs
Task: T015 — DB/Queries.hs (run queries)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (all DSL types + DB types + API types)
3. Complete Phase 3: User Story 1 (run attacks via curl)
4. **STOP and VALIDATE**: POST a run via curl, verify response
5. Deploy/demo if ready — core research capability available

### Incremental Delivery

1. Setup + Foundational → types compile
2. US1 → run attacks via curl (MVP!)
3. US2 → manage attack library via curl
4. US3 → dashboard visualizes results in browser
5. US4 → full browser-based workflow
6. Each story adds value without breaking previous stories

### Single Developer Strategy

1. Complete Setup (Phase 1) — all tasks parallel
2. Complete Foundational (Phase 2) — T006/T007/T008 parallel, then T009→T010→T011→T012→T013
3. US1 (Phase 3) — T014+T015 parallel, then T016→T017
4. US2 (Phase 4) — T018→T019
5. US3 (Phase 5) — T020→T021, T022 parallel, then T023→T024→T025
6. US4 (Phase 6) — T026+T027 parallel
7. Polish (Phase 7) — all parallel

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable via curl (backend) or browser (frontend)
- No test tasks generated — tests were not explicitly requested in the spec
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
