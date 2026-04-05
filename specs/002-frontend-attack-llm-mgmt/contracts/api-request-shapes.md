# API Request/Response Shapes

**Date**: 2026-04-05

These are the existing backend API contracts consumed by the new
frontend forms. No new endpoints are introduced.

## POST /targets

**Request** (`LLMTargetRequest`):
```json
{
  "ltrName": "string (required)",
  "ltrBaseUrl": "string (required)",
  "ltrModel": "string (required)",
  "ltrApiKey": "string | null"
}
```

**Response** (`LLMTarget`, 201 Created):
```json
{
  "ltId": "uuid",
  "ltName": "string",
  "ltBaseUrl": "string",
  "ltModel": "string",
  "ltApiKey": "string | null",
  "ltCreatedAt": "ISO 8601 datetime"
}
```

## POST /attacks

**Request** (`AttackRequest`):
```json
{
  "arCategory": "string (required, one of OWASP category keys)",
  "arTechnique": "string | null",
  "arPayload": "string (required)",
  "arDescription": "string (required)",
  "arOwaspRef": "string (required, same as arCategory)"
}
```

**Response** (`AttackTemplate`, 201 Created):
```json
{
  "atId": "uuid",
  "atCategory": "string",
  "atTechnique": "string | null",
  "atPayload": "string",
  "atDescription": "string",
  "atOwaspRef": "string",
  "atCreatedAt": "ISO 8601 datetime"
}
```

## GET /targets

**Response** (`[LLMTarget]`): Array of LLMTarget objects (same shape
as POST response).

## GET /attacks

**Response** (`[AttackTemplate]`): Array of AttackTemplate objects
(same shape as POST response).
