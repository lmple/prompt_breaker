# Data Model: Edit & Delete LLM Targets and Attacks

**Date**: 2026-04-05
**Branch**: `003-edit-delete-entries`

No new entities or schema changes. This feature adds operations to
existing entities.

## Updated Operations

### LLM Target

**Update** (PUT `/targets/:id`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | string | Yes | Non-empty; unique constraint enforced by DB |
| baseUrl | string | Yes | Non-empty |
| model | string | Yes | Non-empty |
| apiKey | string/null | No | `null` = keep existing, `""` = remove, other = update |

Returns: Updated `LLMTarget` object.

**Delete** (DELETE `/targets/:id`):

Precondition: No rows in `runs` reference this target ID.
Returns: 204 No Content on success, 409 Conflict if runs exist.

### Attack Template

**Update** (PUT `/attacks/:id`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| category | string | Yes | Must match DB CHECK constraint |
| technique | string/null | No | Required when category = "Jailbreak", null otherwise |
| payload | string | Yes | Non-empty |
| description | string | Yes | Non-empty |
| owaspRef | string | Yes | Must match DB CHECK constraint |

Returns: Updated `AttackTemplate` object.

**Delete** (DELETE `/attacks/:id`):

Precondition: No rows in `runs` reference this attack ID.
Returns: 204 No Content on success, 409 Conflict if runs exist.

## Run Reference Check Queries

- `hasRunsForTarget :: UUID -> IO Bool` — checks if any run
  references the given target ID.
- `hasRunsForAttack :: UUID -> IO Bool` — checks if any run
  references the given attack ID.
