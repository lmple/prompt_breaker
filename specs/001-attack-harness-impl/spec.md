# Feature Specification: Attack Harness

**Feature Branch**: `001-attack-harness-impl`
**Created**: 2026-04-04
**Status**: Draft
**Input**: User description: "LLM prompt injection attack harness with typed DSL, Servant API, Postgres store, and React dashboard"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run a Single Attack Against an LLM Target (Priority: P1)

A security researcher selects an attack template (e.g., "Classic override
attempt"), picks a target LLM (e.g., local Ollama llama3), chooses a prompt
strategy (Naive or Sanitized), and runs the attack. The system sends the
crafted prompt to the LLM, evaluates whether the attack succeeded, and
displays the result — including the raw LLM response, success/failure
verdict, and confidence score.

**Why this priority**: This is the core value proposition — without the
ability to run a single attack end-to-end, no other feature matters. It
exercises every layer: DSL, runner, evaluator, database persistence, and API.

**Independent Test**: Can be fully tested by submitting one attack via the
API and verifying that a run record is persisted with a success/failure
evaluation. Delivers immediate research value even without the dashboard.

**Acceptance Scenarios**:

1. **Given** at least one attack template and one LLM target exist,
   **When** the researcher submits a run request with strategy "Naive",
   **Then** the system sends the raw payload to the LLM, evaluates the
   response, and returns a run result with success flag, confidence score,
   and raw response text.

2. **Given** at least one attack template and one LLM target exist,
   **When** the researcher submits a run request with strategy "Sanitized",
   **Then** the system sanitizes the payload before sending it, evaluates
   the response, and returns a run result — allowing direct comparison
   with the Naive strategy.

3. **Given** the target LLM is unreachable,
   **When** the researcher submits a run request,
   **Then** the system returns a clear error indicating the target is
   unavailable, without persisting an incomplete run record.

---

### User Story 2 - Manage Attack Templates and LLM Targets (Priority: P2)

A security researcher registers LLM targets (name, URL, model) and creates
attack templates (category, payload, OWASP reference) so they can build up
a library of attacks and targets for systematic testing.

**Why this priority**: Without a managed library of attacks and targets, the
researcher cannot run controlled experiments. This story provides the data
foundation that US1 consumes.

**Independent Test**: Can be fully tested by creating, listing, and
verifying attack templates and LLM targets via the API. Delivers value as
a reusable attack library even before runs are implemented.

**Acceptance Scenarios**:

1. **Given** no LLM targets exist,
   **When** the researcher registers a new target with name, URL, and model,
   **Then** the system persists the target and returns it with a unique
   identifier.

2. **Given** no attack templates exist,
   **When** the researcher creates an attack template with category, payload,
   description, and OWASP reference,
   **Then** the system persists it and returns it with a unique identifier.

3. **Given** multiple attack templates exist,
   **When** the researcher lists all attacks,
   **Then** the system returns all templates with their categories and
   OWASP references.

---

### User Story 3 - View Attack Success Rate Dashboard (Priority: P3)

A security researcher opens the web dashboard to see a visual comparison of
attack success rates across OWASP categories, broken down by prompt strategy
(Naive vs. Sanitized). Summary cards show total runs, overall success rates,
and the most vulnerable category.

**Why this priority**: Visualization is essential for the research question
("Does typed sanitization reduce attack success?") but depends on having
run data from US1 and US2. It's the presentation layer on top of the core
engine.

**Independent Test**: Can be fully tested by loading the dashboard with
pre-seeded run data and verifying that charts render correct success rates
per category and strategy. Delivers the research insight that motivates the
entire project.

**Acceptance Scenarios**:

1. **Given** runs exist across multiple OWASP categories and both strategies,
   **When** the researcher opens the dashboard,
   **Then** a bar chart displays success rate per OWASP category with Naive
   and Sanitized bars side by side.

2. **Given** runs exist,
   **When** the researcher views summary cards,
   **Then** cards show total run count, overall Naive success rate, overall
   Sanitized success rate, and the most vulnerable category.

---

### User Story 4 - Browse Run History (Priority: P4)

A security researcher browses past attack runs in a table, filters by OWASP
category or strategy, and expands individual rows to inspect raw LLM
responses.

**Why this priority**: Detailed run inspection supports debugging and
qualitative analysis. It depends on run data (US1) and is less critical
than the aggregate dashboard (US3) for answering the core research question.

**Independent Test**: Can be tested by loading the run history view with
pre-seeded data and verifying that filtering, sorting, and row expansion
work correctly.

**Acceptance Scenarios**:

1. **Given** multiple runs exist,
   **When** the researcher views run history,
   **Then** a table shows each run's attack, target, model, strategy,
   success verdict, confidence, and timestamp.

2. **Given** runs span multiple OWASP categories,
   **When** the researcher filters by a specific category,
   **Then** only runs matching that category appear.

3. **Given** a run exists with a raw response,
   **When** the researcher clicks to expand a row,
   **Then** the full raw LLM response is displayed.

---

### Edge Cases

- What happens when the LLM target returns an empty response?
  The evaluator MUST treat empty responses as attack failure (confidence 0.0).

- What happens when the sanitizer strips the entire payload?
  The system MUST still send the (now-empty) sanitized content and record
  the result, since a blank payload is a valid experimental condition.

- What happens when two targets share the same name?
  The system MUST reject the duplicate and return a clear validation error.

- What happens when an attack template references an unknown OWASP category?
  The system MUST validate against the known OWASP category set and reject
  unrecognized values.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow researchers to register LLM targets with
  a unique name, base URL, model identifier, and optional API key.

- **FR-002**: System MUST allow researchers to create attack templates with
  a category (DirectInjection, IndirectInjection, Jailbreak with technique,
  PromptLeaking), payload text, description, and OWASP category reference.

- **FR-003**: System MUST execute attack runs by sending a prompt to the
  selected LLM target using the chosen strategy (Naive or Sanitized).

- **FR-004**: When strategy is "Naive", the system MUST send the raw attack
  payload without modification. When strategy is "Sanitized", the system
  MUST apply sanitization before sending.

- **FR-005**: System MUST evaluate each LLM response for attack success
  using a keyword-based evaluator that checks for absence of refusal
  phrases and presence of compliance signals.

- **FR-006**: System MUST persist every completed run with attack reference,
  target reference, strategy used, system prompt, raw response, success
  verdict, confidence score, and timestamp.

- **FR-007**: System MUST provide aggregate statistics: success rate per
  OWASP category broken down by prompt strategy.

- **FR-008**: System MUST use deterministic LLM parameters (temperature 0.0)
  for all attack requests to ensure reproducibility.

- **FR-009**: System MUST enforce that all user-supplied attack payloads
  are wrapped in a typed safety boundary — never treated as plain text
  internally.

- **FR-010**: System MUST support multiple evaluator methods (keyword match
  initially, with the interface allowing future addition of regex and
  LLM-as-judge evaluators).

- **FR-011**: The web dashboard MUST display a side-by-side bar chart
  comparing Naive vs. Sanitized success rates per OWASP category.

- **FR-012**: The web dashboard MUST display summary cards: total runs,
  overall Naive success rate, overall Sanitized success rate, and the
  most vulnerable OWASP category.

- **FR-013**: The run history view MUST support filtering by OWASP category
  and prompt strategy.

- **FR-014**: LLM target configuration (URLs, models) MUST NOT be
  hardcoded — all targets MUST be stored and read from the database.

### Key Entities

- **LLM Target**: A model endpoint the system sends prompts to. Has a
  unique name, base URL, model identifier, and optional API key.

- **Attack Template**: A reusable attack definition. Has a category
  (direct injection, jailbreak with technique, prompt leaking), a payload,
  a human-readable description, and an OWASP category reference.

- **Run**: A single execution of an attack against a target. References
  an attack template and target, records the prompt strategy used, the
  system prompt, the raw LLM response, the success evaluation, confidence
  score, evaluator method, and execution timestamp.

- **Stats**: Aggregate view over runs. Groups results by OWASP category,
  computing Naive and Sanitized success rates and total run counts per
  category.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A researcher can go from selecting an attack to viewing the
  evaluated result in under 30 seconds (excluding LLM response latency).

- **SC-002**: Running the same attack against the same target with the same
  strategy produces identical success/failure verdicts across repeated runs.

- **SC-003**: The dashboard accurately reflects aggregate statistics — the
  displayed success rates match the underlying run data to within 0.1%.

- **SC-004**: The system supports at least 4 distinct OWASP attack
  categories with pre-seeded attack templates for each.

- **SC-005**: A researcher can visually determine whether sanitization
  reduces attack success rates by viewing the dashboard, without needing
  to manually query or compute statistics.

- **SC-006**: All run data is persisted — no results are lost between
  sessions or across restarts.

## Assumptions

- The primary user is a security researcher with technical knowledge of
  LLM prompt injection; the UI does not need onboarding guidance.

- At least one local LLM target (Ollama) is available on the researcher's
  machine during testing; the system does not provision LLM infrastructure.

- Authentication and authorization are out of scope — the harness is a
  local research tool, not a multi-tenant service.

- The initial evaluator (keyword match) is sufficient for MVP; LLM-as-judge
  evaluation is a future enhancement that the architecture supports but
  does not require for launch.

- The frontend communicates with the backend over localhost; CORS
  configuration assumes same-machine deployment.

- Seed data (sample attack templates and local Ollama targets) is provided
  for development and demonstration purposes.
