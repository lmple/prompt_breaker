# Tasks: Edit & Delete LLM Targets and Attacks

**Input**: Design documents from `/specs/003-edit-delete-entries/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/, research.md, quickstart.md

**Tests**: No test framework configured. Tests are not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: No setup tasks needed — project structure and dependencies already exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Backend infrastructure shared by all user stories. MUST complete before any story work.

- [x] T001 Add CORS support for PUT and DELETE methods in backend/app/Main.hs — add `"PUT"` and `"DELETE"` to the `corsMethods` list in the `corsMiddleware` policy
- [x] T002 [P] Add DB query `hasRunsForTarget` in backend/src/DB/Queries.hs — `hasRunsForTarget :: Connection -> UUID -> IO Bool` that checks `SELECT EXISTS (SELECT 1 FROM runs WHERE target_id = ?)`
- [x] T003 [P] Add DB query `hasRunsForAttack` in backend/src/DB/Queries.hs — `hasRunsForAttack :: Connection -> UUID -> IO Bool` that checks `SELECT EXISTS (SELECT 1 FROM runs WHERE attack_id = ?)`
- [x] T004 Add frontend API client functions in frontend/src/api/client.js — add `putTarget(id, data)` (PUT `/targets/:id`), `deleteTarget(id)` (DELETE `/targets/:id`), `putAttack(id, data)` (PUT `/attacks/:id`), `deleteAttack(id)` (DELETE `/attacks/:id`)

**Checkpoint**: CORS, run-check queries, and API client ready for all stories

---

## Phase 3: User Story 1 - Edit an Existing LLM Target (Priority: P1) MVP

**Goal**: Users can edit LLM target fields via an inline form in the targets list

**Independent Test**: Click "Edit" on a target, change the model name, submit, verify updated name in list and dropdown

### Implementation for User Story 1

- [x] T005 [US1] Add `updateTarget` DB query in backend/src/DB/Queries.hs — `updateTarget :: Connection -> UUID -> Text -> Text -> Text -> Maybe Text -> IO [LLMTargetRow]` that runs `UPDATE llm_targets SET name=?, base_url=?, model=?, api_key=COALESCE(?, api_key) WHERE id=? RETURNING ...`. Handle API key 3-way logic: `Nothing` → keep existing (use SQL `COALESCE`), `Just ""` → set NULL, `Just key` → update
- [x] T006 [US1] Add PUT `/targets/:id` route in backend/src/API/Routes.hs — add `"targets" :> Capture "id" UUID :> ReqBody '[JSON] LLMTargetRequest :> Put '[JSON] LLMTarget` to the `API` type
- [x] T007 [US1] Add `putTargetH` handler in backend/src/API/Handlers.hs — call `updateTarget`, return 404 if empty result, wire into `server` function
- [x] T008 [US1] Create EditTargetForm component in frontend/src/components/EditTargetForm.jsx — accepts `target` prop, pre-populates fields (name, baseUrl, model; API key as empty password input with placeholder "Leave blank to keep current"), uses `useMutation` with `putTarget(target.ltId, data)`, `invalidateQueries(['targets'])` on success, client-side required field validation, error display with input preservation, Save and Cancel buttons
- [x] T009 [US1] Add Edit button and inline edit form to frontend/src/components/TargetList.jsx — add "Edit" button per row, `useState` to track `editingId`, when `editingId` matches row ID render `<EditTargetForm target={t} onClose={() => setEditingId(null)} />` replacing the row, collapse form on successful save or cancel

**Checkpoint**: User Story 1 fully functional — targets can be edited inline

---

## Phase 4: User Story 2 - Edit an Existing Attack Template (Priority: P2)

**Goal**: Users can edit attack template fields via an inline form in the attacks list

**Independent Test**: Click "Edit" on an attack, change the payload, submit, verify updated payload in list and dropdown

### Implementation for User Story 2

- [x] T010 [US2] Add `updateAttack` DB query in backend/src/DB/Queries.hs — `updateAttack :: Connection -> UUID -> Text -> Maybe Text -> Text -> Text -> Text -> IO [AttackTemplateRow]` that runs `UPDATE attack_templates SET category=?, technique=?, payload=?, description=?, owasp_ref=? WHERE id=? RETURNING ...`
- [x] T011 [US2] Add PUT `/attacks/:id` route in backend/src/API/Routes.hs — add `"attacks" :> Capture "id" UUID :> ReqBody '[JSON] AttackRequest :> Put '[JSON] AttackTemplate`
- [x] T012 [US2] Add `putAttackH` handler in backend/src/API/Handlers.hs — call `updateAttack`, return 404 if empty result, wire into `server`
- [x] T013 [US2] Create EditAttackForm component in frontend/src/components/EditAttackForm.jsx — accepts `attack` prop, pre-populates fields (category from `ATTACK_CATEGORIES`, technique if applicable, payload, description), conditionally shows technique selector when category is `Jailbreak`, auto-populates `arOwaspRef` from selected category, uses `useMutation` with `putAttack(attack.atId, data)`, `invalidateQueries(['attacks'])` on success, validation, error handling, Save/Cancel
- [x] T014 [US2] Add Edit button and inline edit form to frontend/src/components/AttackList.jsx — add "Edit" button per row, `useState` to track `editingId`, render `<EditAttackForm>` replacing row when editing, collapse on save/cancel

**Checkpoint**: User Story 2 fully functional — attacks can be edited inline

---

## Phase 5: User Story 3 - Delete an LLM Target (Priority: P3)

**Goal**: Users can delete LLM targets that have no associated runs

**Independent Test**: Click "Delete" on a target with no runs, confirm, verify it disappears; try on a target with runs, verify blocked

### Implementation for User Story 3

- [x] T015 [US3] Add `deleteTarget` DB query in backend/src/DB/Queries.hs — `deleteTarget :: Connection -> UUID -> IO Int64` that runs `DELETE FROM llm_targets WHERE id=?` and returns affected row count
- [x] T016 [US3] Add DELETE `/targets/:id` route in backend/src/API/Routes.hs — add `"targets" :> Capture "id" UUID :> DeleteNoContent`
- [x] T017 [US3] Add `deleteTargetH` handler in backend/src/API/Handlers.hs — call `hasRunsForTarget` first: if true return 409 with message "Cannot delete target: it has associated run history"; otherwise call `deleteTarget`, return 404 if 0 rows affected, return 204 on success
- [x] T018 [US3] Add Delete button to frontend/src/components/TargetList.jsx — add "Delete" button per row, on click call `window.confirm('Delete target "NAME"? This cannot be undone.')`, if confirmed use `useMutation` with `deleteTarget(id)`, `invalidateQueries(['targets'])` on success, show error message on failure (409 = has runs, 404 = not found)

**Checkpoint**: User Story 3 fully functional — targets can be deleted (with run-check guard)

---

## Phase 6: User Story 4 - Delete an Attack Template (Priority: P4)

**Goal**: Users can delete attack templates that have no associated runs

**Independent Test**: Click "Delete" on an attack with no runs, confirm, verify it disappears; try on an attack with runs, verify blocked

### Implementation for User Story 4

- [x] T019 [US4] Add `deleteAttack` DB query in backend/src/DB/Queries.hs — `deleteAttack :: Connection -> UUID -> IO Int64` that runs `DELETE FROM attack_templates WHERE id=?` and returns affected row count
- [x] T020 [US4] Add DELETE `/attacks/:id` route in backend/src/API/Routes.hs — add `"attacks" :> Capture "id" UUID :> DeleteNoContent`
- [x] T021 [US4] Add `deleteAttackH` handler in backend/src/API/Handlers.hs — call `hasRunsForAttack` first: if true return 409; otherwise call `deleteAttack`, return 404 if 0 rows, return 204 on success
- [x] T022 [US4] Add Delete button to frontend/src/components/AttackList.jsx — add "Delete" button per row, `window.confirm`, `useMutation` with `deleteAttack(id)`, `invalidateQueries(['attacks'])` on success, error display

**Checkpoint**: All user stories functional — full edit and delete workflow

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation and cleanup

- [x] T023 Rebuild backend with `cd backend && cabal build` and verify it compiles cleanly under `-Wall -Werror`
- [x] T024 Rebuild frontend with `cd frontend && npm run build` and verify no build errors
- [ ] T025 Run quickstart.md validation from specs/003-edit-delete-entries/quickstart.md — verify all 5 scenarios (edit target, edit attack, delete unreferenced, delete blocked, edit validation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — can start immediately
- **User Story 1 (Phase 3)**: Depends on Foundational (CORS, client functions, run-check queries)
- **User Story 2 (Phase 4)**: Depends on Foundational; independent of US1 (different files in Routes/Handlers/Queries)
- **User Story 3 (Phase 5)**: Depends on Foundational (run-check queries); modifies TargetList.jsx (schedule after US1 T009)
- **User Story 4 (Phase 6)**: Depends on Foundational; modifies AttackList.jsx (schedule after US2 T014)
- **Polish (Phase 7)**: Depends on all stories complete

### Within Each User Story

- DB query before route before handler (backend dependency chain)
- Frontend component before list integration
- Backend must be complete before frontend integration can be tested

### Parallel Opportunities

- T002 and T003 can run in parallel (independent DB queries in same file, different functions)
- T001 and T004 can run in parallel with T002/T003 (different files)
- US1 and US2 backend work (T005-T007 and T010-T012) touch the same files (Routes.hs, Handlers.hs, Queries.hs) so should be sequential
- US1 frontend (T008-T009) and US2 frontend (T013-T014) touch different files and can run in parallel
- US3 (T015-T018) and US4 (T019-T022) follow the same pattern as US1/US2

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001-T004)
2. Complete Phase 3: US1 backend (T005-T007) + frontend (T008-T009)
3. **STOP and VALIDATE**: Edit a target, verify changes persist
4. Ship MVP if ready

### Incremental Delivery

1. T001-T004 → Foundation ready
2. T005-T009 → US1 complete (edit targets)
3. T010-T014 → US2 complete (edit attacks)
4. T015-T018 → US3 complete (delete targets)
5. T019-T022 → US4 complete (delete attacks)
6. T023-T025 → Polish complete

---

## Notes

- Backend files (Routes.hs, Handlers.hs, Queries.hs) are modified across multiple stories — execute backend tasks sequentially per story
- Frontend edit components (EditTargetForm.jsx, EditAttackForm.jsx) are new files — can be created in parallel
- Frontend list components (TargetList.jsx, AttackList.jsx) are modified across edit + delete stories — edit integration before delete integration
- The `hasRunsForTarget`/`hasRunsForAttack` queries are shared by delete stories (US3/US4) but created in foundational phase
- CORS update is a one-line change but blocks all PUT/DELETE operations
- API key 3-way logic (`null` = keep, `""` = remove, value = update) is implemented in T005's SQL query
