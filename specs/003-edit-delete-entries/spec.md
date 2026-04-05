# Feature Specification: Edit & Delete LLM Targets and Attacks

**Feature Branch**: `003-edit-delete-entries`
**Created**: 2026-04-05
**Status**: Draft
**Input**: User description: "The application frontend should allow user to edit and delete models and attacks"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edit an Existing LLM Target (Priority: P1)

A security researcher realizes that an LLM target they registered has
an incorrect base URL or model name. From the targets list in the
Attack Builder, they click an "Edit" action on the target row, which
opens an inline edit form pre-populated with the current values. They
modify the fields they need to change and submit. The updated values
are immediately reflected in the targets list and in the target
dropdown.

**Why this priority**: Incorrect target configuration prevents valid
attack runs. Editing is the most common correction workflow and avoids
the need to delete and re-create entries.

**Independent Test**: Click "Edit" on a target, change the model name,
submit, and verify the updated model name appears in the targets list
and target dropdown.

**Acceptance Scenarios**:

1. **Given** the targets list shows one or more entries, **When** the
   user clicks "Edit" on a target row, **Then** an inline form appears
   pre-populated with the target's current name, base URL, model, and
   API key status.
2. **Given** the user modifies one or more fields in the edit form,
   **When** they submit, **Then** the updated target is persisted and
   the targets list and dropdown reflect the changes without a page
   refresh.
3. **Given** the user clears a required field (name, base URL, or
   model), **When** they attempt to submit, **Then** the form shows
   a validation error and does not submit.
4. **Given** the user decides not to edit, **When** they click
   "Cancel", **Then** the edit form closes and no changes are made.

---

### User Story 2 - Edit an Existing Attack Template (Priority: P2)

A security researcher wants to refine an attack template's payload
or description after reviewing run results. From the attacks list in
the Attack Builder, they click "Edit" on the attack row, modify the
desired fields, and submit. The updated attack is immediately
reflected in the list and dropdown.

**Why this priority**: Iterating on attack payloads is a core research
activity. Editing avoids creating duplicate templates for small
refinements.

**Independent Test**: Click "Edit" on an attack, change the payload
text, submit, and verify the updated payload appears in the attacks
list.

**Acceptance Scenarios**:

1. **Given** the attacks list shows one or more entries, **When** the
   user clicks "Edit" on an attack row, **Then** an inline form
   appears pre-populated with the attack's current category, technique
   (if applicable), payload, and description.
2. **Given** the user modifies one or more fields, **When** they
   submit, **Then** the updated attack is persisted and all views
   reflect the changes without a page refresh.
3. **Given** the user changes the category away from one that requires
   a technique (e.g., Jailbreak to DirectInjection), **When** the form
   updates, **Then** the technique field is hidden and its value is
   cleared.
4. **Given** the user clears a required field, **When** they attempt
   to submit, **Then** the form shows a validation error.

---

### User Story 3 - Delete an LLM Target (Priority: P3)

A security researcher wants to remove an LLM target that is no longer
available or was created by mistake. From the targets list, they click
a "Delete" action on the target row. A confirmation prompt appears to
prevent accidental deletion. Upon confirmation, the target is removed.

**Why this priority**: Deletion is less frequent than editing but
necessary for housekeeping. It is lower priority because an unused
target doesn't interfere with the workflow.

**Independent Test**: Click "Delete" on a target with no associated
runs, confirm, and verify it disappears from the list and dropdown.

**Acceptance Scenarios**:

1. **Given** a target with no associated runs exists, **When** the
   user clicks "Delete" and confirms, **Then** the target is removed
   from the database, the list, and the dropdown.
2. **Given** a target has associated runs, **When** the user clicks
   "Delete", **Then** the system shows a message explaining the target
   cannot be deleted because it has associated run history, and the
   target is not removed.
3. **Given** the user clicks "Delete", **When** the confirmation
   prompt appears and they click "Cancel", **Then** nothing is deleted.

---

### User Story 4 - Delete an Attack Template (Priority: P4)

A security researcher wants to remove an obsolete or duplicate attack
template. From the attacks list, they click "Delete", confirm, and
the attack is removed.

**Why this priority**: Same housekeeping rationale as target deletion.

**Independent Test**: Click "Delete" on an attack with no associated
runs, confirm, and verify it disappears from the list and dropdown.

**Acceptance Scenarios**:

1. **Given** an attack with no associated runs exists, **When** the
   user clicks "Delete" and confirms, **Then** the attack is removed
   from the database, the list, and the dropdown.
2. **Given** an attack has associated runs, **When** the user clicks
   "Delete", **Then** the system shows a message explaining the attack
   cannot be deleted because it has associated run history, and the
   attack is not removed.
3. **Given** the user cancels the confirmation prompt, **Then** nothing
   is deleted.

---

### Edge Cases

- What happens when the user tries to edit an entry that was deleted
  by another user concurrently? The system shows an error message
  indicating the entry no longer exists.
- What happens when the user edits a target name to match an existing
  target's name? The system shows an error from the backend (unique
  constraint) and preserves the form input for correction.
- What happens when the user edits an attack's category to "Jailbreak"
  but doesn't select a technique? The form validates that technique is
  required for Jailbreak and prevents submission.
- What happens when the API key field is edited? The form shows a
  password-type input. If the user leaves it blank, the existing key
  is preserved (not overwritten with null).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an inline edit form for LLM targets,
  triggered by an "Edit" action in the targets list, pre-populated
  with current values.
- **FR-002**: System MUST provide an inline edit form for attack
  templates, triggered by an "Edit" action in the attacks list,
  pre-populated with current values.
- **FR-003**: Edit forms MUST validate required fields on the client
  side before submitting.
- **FR-004**: Updated entries MUST appear in all relevant lists and
  dropdowns without requiring a page refresh.
- **FR-005**: System MUST provide a "Delete" action in the targets
  list and attacks list, with a confirmation prompt before deletion.
- **FR-006**: System MUST prevent deletion of targets or attacks that
  have associated run history, displaying an explanatory message.
- **FR-007**: API key values MUST NOT be displayed in plain text in
  edit forms; the field MUST use a password-type input.
- **FR-008**: System MUST show user-friendly error messages when
  backend requests fail and MUST preserve form input on failure.
- **FR-009**: The backend MUST expose update and delete endpoints for
  both LLM targets and attack templates to support the frontend
  operations.

### Key Entities

- **LLM Target**: Existing entity. New operations: update (all fields
  except ID and creation timestamp), delete (only if no associated
  runs).
- **Attack Template**: Existing entity. New operations: update (all
  fields except ID and creation timestamp), delete (only if no
  associated runs).
- **Run**: Existing entity, unchanged. Its foreign key references to
  targets and attacks determine whether deletion is allowed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can edit any field of an LLM target in under 30
  seconds from clicking "Edit" to seeing the updated value in the list.
- **SC-002**: Users can edit any field of an attack template in under
  30 seconds.
- **SC-003**: Users can delete an unreferenced entry in under 10
  seconds (including confirmation).
- **SC-004**: 100% of deletion attempts on entries with associated
  runs are blocked with an explanatory message.
- **SC-005**: 100% of edit form submissions with missing required
  fields are caught before reaching the backend.

## Assumptions

- This feature requires backend changes: new PUT and DELETE endpoints
  for both targets and attacks (unlike the previous frontend-only
  feature).
- The database foreign key constraints on the `runs` table do not use
  `ON DELETE CASCADE`, so the backend must check for associated runs
  before attempting deletion.
- The edit form for API key uses a password input; leaving it blank
  preserves the existing value (the backend handles this by treating
  absent/empty API key as "no change").
- The existing inline creation forms (from feature 002) establish the
  UX pattern — edit forms follow the same inline style within the
  targets/attacks lists.
- No authentication or authorization — any user can edit or delete
  any entry.
- Bulk edit and bulk delete are out of scope.
