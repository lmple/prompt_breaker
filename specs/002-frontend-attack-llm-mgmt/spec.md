# Feature Specification: Frontend Attack Creation & LLM Management

**Feature Branch**: `002-frontend-attack-llm-mgmt`
**Created**: 2026-04-05
**Status**: Draft
**Input**: User description: "The application frontend should allow user to create new attacks and add LLMs"

## Clarifications

### Session 2026-04-05

- Q: How should users access the LLM target and attack creation forms? → A: Inline "Add new..." buttons next to the target/attack dropdowns in the existing Attack Builder.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a New LLM Target (Priority: P1)

A security researcher wants to register a new LLM endpoint (e.g., a
local Ollama instance or a vLLM server) so they can run attack tests
against it. While using the Attack Builder, they click an "Add new..."
button next to the Target dropdown, fill in the target name, base URL,
model identifier, and optionally an API key, then submit. The new
target appears in the Target dropdown and is immediately selectable
for the current attack run.

**Why this priority**: Without at least one registered LLM target, no
attacks can be executed. Adding targets is the prerequisite for all
other functionality.

**Independent Test**: Can be fully tested by submitting the form and
verifying the new target appears in the target dropdown within the
Attack Builder.

**Acceptance Scenarios**:

1. **Given** the user clicks "Add new..." next to the Target dropdown
   in the Attack Builder, **When** they fill in name, base URL, and
   model and submit the inline form, **Then** the new target is
   persisted and appears in the Target dropdown without a page refresh.
2. **Given** the user submits the form with a missing required field
   (name, base URL, or model), **When** they click submit, **Then**
   the form displays a validation message and does not submit.
3. **Given** the user provides an optional API key, **When** they
   submit the form, **Then** the key is stored and the target entry
   shows that an API key is configured (without displaying the key
   itself).

---

### User Story 2 - Create a New Attack Template (Priority: P2)

A security researcher wants to define a new prompt-injection attack
template so they can test it against registered LLM targets. While
using the Attack Builder, they click an "Add new..." button next to
the Attack Template dropdown, select an OWASP category and optionally
a jailbreak technique, write the attack payload text, provide a
human-readable description, and submit. The new attack template
appears in the Attack Template dropdown and is immediately selectable
for the current attack run.

**Why this priority**: Creating custom attacks is the core research
workflow, but it depends on having at least one LLM target already
registered (US1) to be useful end-to-end.

**Independent Test**: Can be fully tested by submitting the form and
verifying the new attack appears in the attack dropdown within the
Attack Builder.

**Acceptance Scenarios**:

1. **Given** the user clicks "Add new..." next to the Attack Template
   dropdown in the Attack Builder, **When** they select an OWASP
   category, enter a payload and description, and submit, **Then**
   the new attack template is persisted and appears in the Attack
   Template dropdown without a page refresh.
2. **Given** the user selects a category that supports jailbreak
   techniques (e.g., Jailbreak), **When** the form renders, **Then**
   a technique selector appears with options (Roleplay, Hypothetical,
   Encoding, Fragmentation).
3. **Given** the user submits the form with a missing required field
   (category, payload, or description), **When** they click submit,
   **Then** the form displays a validation message and does not submit.

---

### User Story 3 - View and Manage Existing Entries (Priority: P3)

A security researcher wants to see all registered LLM targets and
attack templates in a browsable list so they can review what is
already configured before creating duplicates. Each list shows key
attributes and creation timestamps.

**Why this priority**: Browsing existing entries reduces duplicate
creation and improves usability, but is not required for the core
create-and-run workflow.

**Independent Test**: Can be fully tested by loading the management
views and verifying that previously created targets and attacks are
displayed with correct attributes.

**Acceptance Scenarios**:

1. **Given** one or more LLM targets exist, **When** the user opens
   the targets list view, **Then** all targets are displayed showing
   name, base URL, model, API key status (present/absent), and
   creation date.
2. **Given** one or more attack templates exist, **When** the user
   opens the attacks list view, **Then** all attacks are displayed
   showing description, OWASP category, technique (if applicable),
   and creation date.
3. **Given** no entries exist for a given type, **When** the user
   opens the list view, **Then** a helpful empty state message is
   shown with a prompt to create the first entry.

---

### Edge Cases

- What happens when the backend is unreachable during form submission?
  The user sees a clear error message and their form input is preserved
  so they can retry.
- What happens when the user enters an extremely long payload (e.g.,
  10,000+ characters)? The form accepts it — payload length is not
  constrained on the frontend since attack payloads vary widely.
- What happens when two users create targets with the same name? Both
  are accepted — names are not required to be unique (targets are
  identified by UUID).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an inline form, accessible via an
  "Add new..." button next to the Target dropdown in the Attack
  Builder, to register new LLM targets with fields: name (required),
  base URL (required), model (required), and API key (optional).
- **FR-002**: System MUST provide an inline form, accessible via an
  "Add new..." button next to the Attack Template dropdown in the
  Attack Builder, to create new attack templates with fields: OWASP
  category (required), payload text (required), description (required),
  OWASP reference (required), and jailbreak technique (optional, shown
  only for relevant categories).
- **FR-003**: System MUST validate required fields on the client side
  before submitting to the backend.
- **FR-004**: Newly created targets and attacks MUST appear in all
  relevant lists and dropdowns without requiring a full page reload.
- **FR-005**: The OWASP category selector MUST present only the
  categories defined in the system's taxonomy — users MUST NOT be
  able to enter free-text categories.
- **FR-006**: API key values MUST NOT be displayed in plain text in
  list views; only their presence or absence is shown.
- **FR-007**: System MUST display browsable lists of existing LLM
  targets and attack templates with key attributes.
- **FR-008**: System MUST show user-friendly error messages when
  backend requests fail, and MUST preserve form input on failure.

### Key Entities

- **LLM Target**: A registered LLM endpoint to test against.
  Attributes: name, base URL, model identifier, optional API key,
  creation timestamp.
- **Attack Template**: A reusable prompt-injection attack definition.
  Attributes: OWASP category, optional jailbreak technique, payload
  text, human-readable description, OWASP reference, creation
  timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can register a new LLM target in under 30 seconds
  from opening the form to seeing it in the list.
- **SC-002**: Users can create a new attack template in under 60
  seconds from opening the form to seeing it in the attacks list.
- **SC-003**: 100% of form submissions with missing required fields
  are caught before reaching the backend.
- **SC-004**: Newly created entries appear in all relevant views
  within 2 seconds of successful submission.
- **SC-005**: Users can browse all existing targets and attacks
  without navigating away from the Attack Builder.

## Assumptions

- The backend already exposes working creation endpoints for LLM
  targets and attack templates (confirmed: POST `/targets` and
  POST `/attacks` exist).
- The frontend API client already includes functions for these
  endpoints (`postTarget`, `postAttack` — confirmed in
  `api/client.js`).
- This feature covers frontend work only — no backend changes are
  required.
- The OWASP categories available in the frontend are sourced from
  the backend or hardcoded to match the backend's current taxonomy.
- There is no authentication or authorization layer — any user of
  the application can create targets and attacks.
- Deletion and editing of existing entries are out of scope for
  this feature.
