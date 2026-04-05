# Research: Edit & Delete LLM Targets and Attacks

**Date**: 2026-04-05
**Branch**: `003-edit-delete-entries`

## R1: Servant PUT/DELETE Route Pattern

**Decision**: Add `Capture "id" UUID` routes for PUT and DELETE,
following the existing `runs/:id` pattern in `API/Routes.hs`. PUT
accepts the same request body types as POST (`LLMTargetRequest`,
`AttackRequest`). DELETE takes no body and returns `NoContent`.

**Rationale**: Consistent with existing Servant patterns in the
codebase. Reusing request types avoids new data types for updates.

**Alternatives considered**:
- PATCH with partial updates: More complex (optional fields, merge
  semantics) for marginal benefit in a research tool.

## R2: Delete Safety — Run Reference Checks

**Decision**: Before deleting, the backend queries the `runs` table
to check if any rows reference the target/attack ID. If references
exist, return HTTP 409 Conflict with a descriptive message. Do NOT
attempt the DELETE and catch the FK violation.

**Rationale**: Proactive checking provides a clear, user-friendly
error message. Catching FK exceptions is backend-dependent and harder
to translate into helpful messages.

**Alternatives considered**:
- `ON DELETE CASCADE`: Destroying run history is unacceptable for a
  research tool — runs are the primary output.
- `ON DELETE SET NULL`: Would orphan runs, breaking the data model.

## R3: API Key Handling on Edit

**Decision**: The PUT endpoint accepts `ltrApiKey :: Maybe Text`.
The frontend sends `null` to mean "keep existing key" and an empty
string to mean "remove key". The backend handler implements this
three-way logic: `Nothing` → preserve, `Just ""` → set to NULL,
`Just key` → update.

**Rationale**: The password-type input can't display the current key.
Users need a way to keep, change, or remove the key without seeing it.

**Alternatives considered**:
- Separate endpoint for API key management: Over-engineered for this
  use case.
- Always require re-entering the key: Poor UX — users would need to
  remember/paste the key on every edit.

## R4: CORS Method Expansion

**Decision**: Add `"PUT"` and `"DELETE"` to the `corsMethods` list
in `Main.hs`. No other CORS changes needed.

**Rationale**: The existing CORS middleware already allows the correct
origin and headers. Only the methods list needs expansion.

## R5: Frontend Edit Form Pattern

**Decision**: Create dedicated `EditTargetForm` and `EditAttackForm`
components (separate from the create forms) that accept the current
entity as a prop and pre-populate fields. They render inline in the
list row when the user clicks "Edit", replacing the row content
temporarily.

**Rationale**: Separate edit components avoid complicating the create
forms with dual-mode logic. The existing `AddTargetForm` and
`AddAttackForm` are purpose-built for creation and don't accept
initial values.

**Alternatives considered**:
- Reuse create forms with an `initialValues` prop: Would require
  refactoring both create forms and adding mode-switching logic.
  More coupling for less clarity.

## R6: Delete Confirmation Pattern

**Decision**: Use `window.confirm()` for delete confirmation. Simple,
built-in, and sufficient for a research tool.

**Rationale**: No need for a custom modal component for a single
yes/no prompt. `window.confirm()` is blocking and returns a boolean,
making the control flow trivial.

**Alternatives considered**:
- Custom confirmation modal component: Over-engineered for this UX.
