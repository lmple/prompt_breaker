# Tasks: Frontend Attack Creation & LLM Management

**Input**: Design documents from `/specs/002-frontend-attack-llm-mgmt/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/, research.md, quickstart.md

**Tests**: No test framework configured in the frontend. Tests are not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Define shared constants used across creation forms and list views

- [x] T001 Create constants file with OWASP categories and jailbreak techniques in frontend/src/constants.js — export `OWASP_CATEGORIES` array (objects with `key` and `label` matching `DSL/OWASP.hs`: `LLM01_PromptInjection` → "Prompt Injection", `LLM02_InsecureOutputHandling` → "Insecure Output Handling", `LLM06_SensitiveInfoDisclosure` → "Sensitive Info Disclosure", `LLM07_InsecurePluginDesign` → "Insecure Plugin Design") and `JAILBREAK_TECHNIQUES` array (`Roleplay`, `Hypothetical`, `Encoding`, `Fragmentation`)

**Checkpoint**: Constants available for all user story phases

---

## Phase 2: User Story 1 - Add a New LLM Target (Priority: P1) MVP

**Goal**: Users can register new LLM endpoints via an inline form in the Attack Builder

**Independent Test**: Click "Add new..." next to Target dropdown, fill in name/URL/model, submit, verify target appears in dropdown

### Implementation for User Story 1

- [x] T002 [US1] Create AddTargetForm component in frontend/src/components/AddTargetForm.jsx — form with fields: name (text, required), base URL (text, required), model (text, required), API key (password, optional). Use `useMutation` with `postTarget` from api/client.js, `invalidateQueries(['targets'])` on success, client-side required field validation, error display with input preservation on failure, and a cancel button to hide the form
- [x] T003 [US1] Integrate AddTargetForm into frontend/src/components/AttackBuilder.jsx — add "Add new..." button next to the Target `<select>`, add `useState` toggle for form visibility (`showAddTarget`), render `<AddTargetForm>` below the dropdown when toggled, collapse form on successful submission

**Checkpoint**: User Story 1 fully functional — new targets can be created inline and selected immediately

---

## Phase 3: User Story 2 - Create a New Attack Template (Priority: P2)

**Goal**: Users can define new attack templates via an inline form in the Attack Builder

**Independent Test**: Click "Add new..." next to Attack Template dropdown, select OWASP category, enter payload/description, submit, verify attack appears in dropdown

### Implementation for User Story 2

- [x] T004 [US2] Create AddAttackForm component in frontend/src/components/AddAttackForm.jsx — form with fields: OWASP category (`<select>` from `OWASP_CATEGORIES` constant, required), jailbreak technique (`<select>` from `JAILBREAK_TECHNIQUES` constant, conditionally shown when category is `LLM01_PromptInjection`), payload (textarea, required), description (text, required). Auto-populate `arOwaspRef` from selected category. Use `useMutation` with `postAttack`, `invalidateQueries(['attacks'])` on success, client-side required field validation, error display with input preservation, cancel button
- [x] T005 [US2] Integrate AddAttackForm into frontend/src/components/AttackBuilder.jsx — add "Add new..." button next to the Attack Template `<select>`, add `useState` toggle (`showAddAttack`), render `<AddAttackForm>` below the dropdown when toggled, collapse form on successful submission

**Checkpoint**: User Story 2 fully functional — new attack templates can be created inline and selected immediately

---

## Phase 4: User Story 3 - View and Manage Existing Entries (Priority: P3)

**Goal**: Users can browse all registered LLM targets and attack templates in list views below the Attack Builder

**Independent Test**: Verify targets table and attacks table render below the form with correct attributes; verify empty state messages when no entries exist

### Implementation for User Story 3

- [x] T006 [P] [US3] Create TargetList component in frontend/src/components/TargetList.jsx — HTML table displaying all targets via `useQuery` with `getTargets`: columns for name, base URL, model, API key status ("Configured" / "None" — never show actual key), and formatted creation date. Show "No targets registered yet" empty state with prompt to use the "Add new..." button above
- [x] T007 [P] [US3] Create AttackList component in frontend/src/components/AttackList.jsx — HTML table displaying all attacks via `useQuery` with `getAttacks`: columns for description, OWASP category, technique (or "—" if null), and formatted creation date. Show "No attack templates defined yet" empty state
- [x] T008 [US3] Integrate TargetList and AttackList into frontend/src/components/AttackBuilder.jsx — render `<TargetList>` and `<AttackList>` below the existing attack builder form, with section headings "Registered Targets" and "Attack Templates"

**Checkpoint**: All user stories functional — full create-and-browse workflow within Attack Builder

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation and cleanup across all stories

- [x] T009 Run quickstart.md validation from specs/002-frontend-attack-llm-mgmt/quickstart.md — verify all 4 verification scenarios pass end-to-end (add target, create attack, browse lists, run attack with new entries)
- [x] T010 Verify error handling across all forms — confirm backend-unreachable errors show user-friendly messages and preserve form input for retry

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **User Story 1 (Phase 2)**: Depends on Setup (T001 not strictly needed for US1, but establishes pattern)
- **User Story 2 (Phase 3)**: Depends on Setup (needs constants from T001) and US1 completion (T003 modifies AttackBuilder.jsx)
- **User Story 3 (Phase 4)**: Depends on US2 completion (T008 modifies AttackBuilder.jsx)
- **Polish (Phase 5)**: Depends on all user stories being complete

### Within Each User Story

- Component creation before integration into AttackBuilder
- Within US3: T006 and T007 can run in parallel (different files)
- T008 depends on both T006 and T007

### Parallel Opportunities

- T006 and T007 can run in parallel (different files, no shared state)
- All other tasks are sequential due to shared AttackBuilder.jsx modifications

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: User Story 1 (T002 → T003)
3. **STOP and VALIDATE**: Create a target inline, verify it appears in dropdown
4. Ship MVP if ready

### Incremental Delivery

1. T001 → Constants ready
2. T002 → T003 → US1 complete (add targets)
3. T004 → T005 → US2 complete (add attacks)
4. T006 + T007 (parallel) → T008 → US3 complete (browse lists)
5. T009 → T010 → Polish complete

---

## Notes

- All new files are in `frontend/src/components/` (plus one `frontend/src/constants.js`)
- `AttackBuilder.jsx` is modified incrementally across US1, US2, and US3 — each phase adds its integration
- No new npm dependencies required
- The existing `api/client.js` already exports `postTarget` and `postAttack` — no API client changes needed
- OWASP categories and jailbreak techniques are hardcoded to match backend `DSL/OWASP.hs` and `DSL/Attack.hs`
