# Data Model: Frontend Attack Creation & LLM Management

**Date**: 2026-04-05
**Branch**: `002-frontend-attack-llm-mgmt`

This feature introduces no new persistent entities. It consumes
existing backend API types. The following documents the frontend
data shapes used in forms and list displays.

## Entities (consumed from backend)

### LLM Target

Corresponds to `LLMTargetRequest` (create) and `LLMTarget` (read)
from `API/Types.hs`.

**Create form fields**:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| name | string | Yes | Non-empty |
| baseUrl | string | Yes | Non-empty |
| model | string | Yes | Non-empty |
| apiKey | string | No | None |

**Display attributes** (list view):

| Attribute | Source field | Display |
|-----------|-------------|---------|
| Name | `ltName` | Plain text |
| Base URL | `ltBaseUrl` | Plain text |
| Model | `ltModel` | Plain text |
| API Key | `ltApiKey` | "Configured" / "None" (never show value) |
| Created | `ltCreatedAt` | Formatted date |

### Attack Template

Corresponds to `AttackRequest` (create) and `AttackTemplate` (read)
from `API/Types.hs`.

**Create form fields**:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| category | enum (OWASP) | Yes | Must be one of 4 values |
| technique | enum | No | Shown only when category supports it |
| payload | string | Yes | Non-empty |
| description | string | Yes | Non-empty |
| owaspRef | string | Yes | Auto-populated from category |

**Display attributes** (list view):

| Attribute | Source field | Display |
|-----------|-------------|---------|
| Description | `atDescription` | Plain text |
| Category | `atCategory` | Plain text |
| Technique | `atTechnique` | Plain text or "—" if null |
| OWASP Ref | `atOwaspRef` | Plain text |
| Created | `atCreatedAt` | Formatted date |

## Constants (frontend-only)

### OWASP Categories

Hardcoded to match `DSL/OWASP.hs`:

```
LLM01_PromptInjection        → "Prompt Injection"
LLM02_InsecureOutputHandling  → "Insecure Output Handling"
LLM06_SensitiveInfoDisclosure → "Sensitive Info Disclosure"
LLM07_InsecurePluginDesign    → "Insecure Plugin Design"
```

### Jailbreak Techniques

Hardcoded to match `DSL/Attack.hs` `JailbreakTechnique`:

```
Roleplay
Hypothetical
Encoding
Fragmentation
```

## Relationships

- An attack run references one LLM Target and one Attack Template
  (existing relationship, unchanged by this feature).
- The OWASP category selected during attack creation determines
  the `arOwaspRef` value (derived, not user-entered).
