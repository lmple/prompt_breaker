export const ATTACK_CATEGORIES = [
  { key: 'DirectInjection', label: 'Direct Injection', owaspRef: 'LLM01_PromptInjection' },
  { key: 'IndirectInjection', label: 'Indirect Injection', owaspRef: 'LLM01_PromptInjection' },
  { key: 'Jailbreak', label: 'Jailbreak', owaspRef: 'LLM01_PromptInjection' },
  { key: 'PromptLeaking', label: 'Prompt Leaking', owaspRef: 'LLM06_SensitiveInfoDisclosure' },
];

export const JAILBREAK_TECHNIQUES = [
  'Roleplay',
  'Hypothetical',
  'Encoding',
  'Fragmentation',
];
