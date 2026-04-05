CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS llm_targets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    base_url    TEXT NOT NULL,
    model       TEXT NOT NULL,
    api_key     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS attack_templates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category    TEXT NOT NULL CHECK (category IN ('DirectInjection', 'IndirectInjection', 'Jailbreak', 'PromptLeaking')),
    technique   TEXT CHECK (
        (category = 'Jailbreak' AND technique IS NOT NULL) OR
        (category != 'Jailbreak' AND technique IS NULL)
    ),
    payload     TEXT NOT NULL,
    description TEXT NOT NULL,
    owasp_ref   TEXT NOT NULL CHECK (owasp_ref IN ('LLM01_PromptInjection', 'LLM02_InsecureOutputHandling', 'LLM06_SensitiveInfoDisclosure', 'LLM07_InsecurePluginDesign')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS runs (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attack_id         UUID NOT NULL REFERENCES attack_templates(id),
    target_id         UUID NOT NULL REFERENCES llm_targets(id),
    prompt_strategy   TEXT NOT NULL CHECK (prompt_strategy IN ('naive', 'sanitized')),
    system_prompt     TEXT NOT NULL,
    raw_response      TEXT,
    success           BOOLEAN,
    confidence        DOUBLE PRECISION,
    evaluator_method  TEXT NOT NULL,
    ran_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_runs_attack_id ON runs(attack_id);
CREATE INDEX IF NOT EXISTS idx_runs_target_id ON runs(target_id);
CREATE INDEX IF NOT EXISTS idx_runs_owasp_strategy ON runs(prompt_strategy);
