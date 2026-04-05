# Research: Frontend Attack Creation & LLM Management

**Date**: 2026-04-05
**Branch**: `002-frontend-attack-llm-mgmt`

## R1: Inline Form Pattern in React

**Decision**: Use collapsible inline forms toggled by "Add new..."
buttons, managed with React `useState` for visibility. Forms render
directly below the associated dropdown inside the existing
`AttackBuilder` component.

**Rationale**: Keeps the user in context — no routing, no modals, no
new dependencies. TanStack Query's `useMutation` + `invalidateQueries`
handles submission and automatic list refresh, matching the existing
`postRun` pattern in `AttackBuilder.jsx`.

**Alternatives considered**:
- Modal dialogs: Adds complexity (portal, focus trap, overlay) with
  no UX benefit for simple forms.
- Separate pages with React Router: Requires adding a router dependency
  and restructuring App.jsx for a two-form feature.

## R2: OWASP Category Values in Frontend

**Decision**: Hardcode the 4 OWASP categories as a constant array
in the frontend, matching `DSL/OWASP.hs` exactly:
`LLM01_PromptInjection`, `LLM02_InsecureOutputHandling`,
`LLM06_SensitiveInfoDisclosure`, `LLM07_InsecurePluginDesign`.

**Rationale**: The backend does not expose a dedicated `/owasp-categories`
endpoint. The spec constrains this feature to frontend-only changes.
The category set changes infrequently (constitution requires updating
`DSL/OWASP.hs` first), so hardcoding is safe.

**Alternatives considered**:
- Fetch from a new backend endpoint: Would require backend changes,
  violating the "frontend-only" scope assumption.
- Parse from existing attack template responses: Unreliable if no
  attacks exist yet.

## R3: Jailbreak Technique Conditional Display

**Decision**: Show the technique selector only when the selected
OWASP category maps to an attack category that uses techniques.
In the current DSL, only `Jailbreak` (within `AttackCategory`)
takes a `JailbreakTechnique` parameter. The frontend will show
the technique dropdown when the user selects `LLM01_PromptInjection`
(since jailbreaks target this OWASP category).

**Rationale**: The `AttackRequest` type has `arTechnique :: Maybe Text`,
so the backend accepts `null` for non-jailbreak attacks. The frontend
conditionally renders the technique selector based on category selection.

**Alternatives considered**:
- Always show technique selector with "N/A" option: Confusing for
  non-jailbreak categories.

## R4: Form Field Mapping to API Types

**Decision**: Map form fields directly to `LLMTargetRequest` and
`AttackRequest` field names from `API/Types.hs`:

| Form | API Field | Required |
|------|-----------|----------|
| Target: Name | `ltrName` | Yes |
| Target: Base URL | `ltrBaseUrl` | Yes |
| Target: Model | `ltrModel` | Yes |
| Target: API Key | `ltrApiKey` | No |
| Attack: Category | `arCategory` | Yes |
| Attack: Technique | `arTechnique` | No |
| Attack: Payload | `arPayload` | Yes |
| Attack: Description | `arDescription` | Yes |
| Attack: OWASP Ref | `arOwaspRef` | Yes |

**Rationale**: Matches Servant API types exactly (Constitution
Principle III). The `arOwaspRef` field is auto-populated from the
selected category — no separate user input needed.

## R5: List Display for Existing Entries

**Decision**: Render target and attack lists as simple HTML tables
below the Attack Builder form, using the existing `getTargets` and
`getAttacks` query functions. Lists are always visible (not collapsed).

**Rationale**: Matches the existing data-fetching pattern in
`AttackBuilder.jsx`. No pagination needed — this is a research tool
with low data volumes.

**Alternatives considered**:
- Collapsible lists: Adds state management for marginal benefit.
- Separate tab: Would require modifying App.jsx; contradicts the
  "inline in Attack Builder" clarification.
