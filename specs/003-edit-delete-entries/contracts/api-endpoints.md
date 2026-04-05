# API Endpoints: Edit & Delete

**Date**: 2026-04-05

New endpoints added to the existing Servant API.

## PUT /targets/:id

**Request** (`LLMTargetRequest`):
```json
{
  "ltrName": "string (required)",
  "ltrBaseUrl": "string (required)",
  "ltrModel": "string (required)",
  "ltrApiKey": "string | null"
}
```

**Response** (`LLMTarget`, 200 OK):
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

**Errors**:
- 404: Target not found
- 409: Name conflicts with existing target (unique constraint)

## DELETE /targets/:id

**Request**: No body.

**Response**: 204 No Content.

**Errors**:
- 404: Target not found
- 409: Target has associated runs — cannot delete

## PUT /attacks/:id

**Request** (`AttackRequest`):
```json
{
  "arCategory": "string (required, matches AttackCategory ADT)",
  "arTechnique": "string | null",
  "arPayload": "string (required)",
  "arDescription": "string (required)",
  "arOwaspRef": "string (required, matches OWASPCategory)"
}
```

**Response** (`AttackTemplate`, 200 OK):
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

**Errors**:
- 404: Attack not found
- 409: DB CHECK constraint violation (invalid category/technique combo)

## DELETE /attacks/:id

**Request**: No body.

**Response**: 204 No Content.

**Errors**:
- 404: Attack not found
- 409: Attack has associated runs — cannot delete
