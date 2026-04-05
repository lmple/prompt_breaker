# Data Model: Attack Harness

**Phase**: 1 — Design & Contracts
**Date**: 2026-04-04

## Entities

### LLMTarget

Represents a model endpoint the system sends attack prompts to.

| Field      | Type         | Constraints                  |
|------------|--------------|------------------------------|
| id         | UUID         | PK, server-generated         |
| name       | Text         | NOT NULL, UNIQUE             |
| baseUrl    | Text         | NOT NULL                     |
| model      | Text         | NOT NULL                     |
| apiKey     | Text         | nullable (optional)          |
| createdAt  | UTCTime      | NOT NULL, default now()      |

**Validation rules**:
- `name` MUST be unique across all targets.
- `baseUrl` MUST be a valid URL (scheme + host at minimum).

---

### OWASPCategory (enum)

Closed set of OWASP LLM Top 10 categories used to classify attacks.

| Value                          | Description                  |
|--------------------------------|------------------------------|
| LLM01_PromptInjection          | Prompt Injection             |
| LLM02_InsecureOutputHandling   | Insecure Output Handling     |
| LLM06_SensitiveInfoDisclosure  | Sensitive Info Disclosure    |
| LLM07_InsecurePluginDesign     | Insecure Plugin Design       |

Stored as text in the database. Validated against the ADT on read/write.

---

### JailbreakTechnique (enum)

Sub-classification for jailbreak-type attacks.

| Value          |
|----------------|
| Roleplay       |
| Hypothetical   |
| Encoding       |
| Fragmentation  |

---

### AttackCategory (tagged union)

| Variant            | Payload              |
|--------------------|----------------------|
| DirectInjection    | (none)               |
| IndirectInjection  | (none)               |
| Jailbreak          | JailbreakTechnique   |
| PromptLeaking      | (none)               |

Stored in DB as two columns: `category` (text) + `technique` (nullable text).

---

### AttackTemplate

A reusable attack definition stored as a template.

| Field       | Type            | Constraints             |
|-------------|-----------------|-------------------------|
| id          | UUID            | PK, server-generated    |
| category    | Text            | NOT NULL                |
| technique   | Text            | nullable                |
| payload     | Text            | NOT NULL (Untrusted)    |
| description | Text            | NOT NULL                |
| owaspRef    | Text            | NOT NULL, valid OWASP   |
| createdAt   | UTCTime         | NOT NULL, default now() |

**Validation rules**:
- `owaspRef` MUST be a valid `OWASPCategory` value.
- `category` MUST be one of: DirectInjection, IndirectInjection,
  Jailbreak, PromptLeaking.
- `technique` MUST be set when `category` is Jailbreak; NULL otherwise.
- `payload` is stored as plain text in DB but MUST be loaded into
  `Untrusted` newtype in Haskell.

---

### PromptStrategy (enum)

| Value     | Behavior                                    |
|-----------|---------------------------------------------|
| Naive     | Send raw payload without modification       |
| Sanitized | Apply sanitization before sending           |

Stored as text in DB. CHECK constraint: `('naive', 'sanitized')`.

---

### EvaluatorMethod (tagged union)

| Variant      | Payload    | Description                      |
|--------------|------------|----------------------------------|
| KeywordMatch | [Text]     | List of refusal keywords         |
| RegexMatch   | Text       | Regex pattern for validation     |
| LLMJudge     | Text       | Judge prompt for LLM evaluator   |

Stored as text (JSON-encoded) in DB `evaluator_method` column.

---

### Run

A single execution of an attack against a target.

| Field           | Type            | Constraints                     |
|-----------------|-----------------|---------------------------------|
| id              | UUID            | PK, server-generated            |
| attackId        | UUID            | FK → attack_templates(id)       |
| targetId        | UUID            | FK → llm_targets(id)            |
| promptStrategy  | Text            | NOT NULL, CHECK naive/sanitized |
| systemPrompt    | Text            | NOT NULL                        |
| rawResponse     | Text            | nullable (null on LLM error)    |
| success         | Bool            | nullable (null on LLM error)    |
| confidence      | Double          | nullable                        |
| evaluatorMethod | Text            | NOT NULL (JSON-encoded)         |
| ranAt           | UTCTime         | NOT NULL, default now()         |

**Validation rules**:
- `attackId` MUST reference a valid attack template.
- `targetId` MUST reference a valid LLM target.
- `success` and `confidence` are NULL only when the LLM call fails.

---

### Stats (computed, not stored)

Aggregate view derived from runs joined with attack_templates.

| Field                | Type   | Description                          |
|----------------------|--------|--------------------------------------|
| owaspCategory        | Text   | OWASP category being aggregated      |
| naiveSuccessRate     | Double | Success rate for Naive strategy      |
| sanitizedSuccessRate | Double | Success rate for Sanitized strategy  |
| totalRuns            | Int    | Total runs in this category          |

Computed via SQL GROUP BY on `owasp_ref` × `prompt_strategy`.

## Relationships

```text
LLMTarget 1 ──── * Run
AttackTemplate 1 ──── * Run
AttackTemplate * ──── 1 OWASPCategory (via owaspRef text field)
AttackTemplate * ──── 0..1 JailbreakTechnique (via technique text field)
```

## State Transitions

Runs have no state machine — they are immutable records created once
when an attack completes. There is no update or delete operation on runs
in the MVP.

Attack templates and LLM targets are similarly create-and-read only in
the MVP (no update/delete endpoints defined in the spec).
