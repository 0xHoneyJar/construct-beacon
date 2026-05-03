---
name: defining-actions
description: Generate JSON Schema and OpenAPI specifications for x402 endpoints — produces per-endpoint request/response schemas plus a combined OpenAPI fragment so AI agents can discover and call the surface. Slash command `/beacon-actions`.
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Skill: defining-actions

> Generate JSON Schema and OpenAPI specifications for x402 endpoints.

## Purpose

AI agents need machine-readable specifications to understand how to call API endpoints. This skill generates:

1. **JSON Schema** - Per-endpoint request/response schemas
2. **OpenAPI Fragment** - Combined specification for all endpoints

These specifications enable agents to:
- Validate requests before sending
- Understand response structures
- Generate type-safe client code

## Trigger

```
/beacon-actions [path]
```

**Arguments:**
- `path` - Optional specific endpoint path (e.g., `/api/generate-image`)
- If no path provided, generates schemas for all payment-enabled endpoints

## Workflow

### Phase 1: Discover Endpoints

1. **Check prerequisites**
   - Read `grimoires/beacon/state.yaml`
   - If `discovery.last_generation` is non-null, prefer reading the existing discovery endpoint
   - If no discovery endpoint exists and no API routes found, suggest: "Run `/beacon-discover` first to generate the x402 discovery endpoint."

2. **Read discovery endpoint** if it exists
   - Parse `app/.well-known/x402/route.ts`
   - Extract endpoint list from discovery response

2. **Or scan API routes**
   - Glob `app/api/**/route.ts`
   - Identify routes with x402 middleware

3. **Collect endpoint metadata**
   - Path
   - Method (POST, GET, etc.)
   - Description
   - Pricing

### Phase 2: Analyze Route Handlers

For each endpoint:

1. **Read route handler** file
2. **Extract request body structure**
   - Look for TypeScript interfaces
   - Parse Zod schemas if present
   - Infer from usage patterns
3. **Extract response structure**
   - Look for return statements
   - Parse response types

#### 2.5 next-safe-action / Zod Detection

Many Next.js projects use `next-safe-action` with Zod schemas for type-safe server actions. Detect these patterns:

```typescript
// Pattern: next-safe-action with Zod
import { actionClient } from "@/lib/safe-action";
import { z } from "zod";

const schema = z.object({
  prompt: z.string().min(1),
  style: z.enum(["realistic", "artistic"]),
});

export const generateImage = actionClient
  .schema(schema)
  .action(async ({ parsedInput }) => { ... });
```

**Detection steps:**
1. Grep for `next-safe-action` or `actionClient` imports
2. If found, extract Zod schemas from `.schema()` calls
3. Convert Zod schemas to JSON Schema (these are more accurate than inferred types)
4. Note in manifest: "Schemas extracted from next-safe-action/Zod definitions"

### Phase 3: Generate JSON Schema

For each endpoint, generate `app/api/{path}/schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Generate Image Request",
  "type": "object",
  "properties": {
    "prompt": {
      "type": "string",
      "description": "Text prompt for image generation"
    }
  },
  "required": ["prompt"]
}
```

### Phase 4: Generate OpenAPI Fragment

Create `grimoires/beacon/discovery/openapi.yaml`:

```yaml
openapi: 3.0.3
info:
  title: {{SERVICE_NAME}} API
  version: 1.0.0
paths:
  /api/generate-image:
    post:
      summary: Generate AI image
      x-payment:
        amount: 1
        currency: "{context:chain_config.default_token}"
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/GenerateImageRequest'
```

### Phase 4.5: OpenAPI Generation Standards

Follow these conventions for production-quality OpenAPI specs:

| Convention | Rule |
|-----------|------|
| **Tags** | Group endpoints by domain (e.g., `earn`, `swap`, `profile`, `game`) |
| **operationIds** | camelCase, descriptive (e.g., `getCombinedAprs`, `verifyQuestCompletion`) |
| **$ref schemas** | All request/response bodies use `$ref: '#/components/schemas/...'` |
| **Error responses** | Include 400 (validation), 401 (auth), 402 (payment), 429 (rate limit), 500 (server) |
| **Security** | Document auth schemes in `securitySchemes` (API key headers, cookie auth) |
| **Cache info** | Add `x-cache-policy` extension with revalidation strategy |
| **x-payment** | For x402 endpoints, add `x-payment: { amount, currency, subsidized }` extension |
| **Descriptions** | Security-sensitive endpoints get explicit warnings (e.g., "Returns raw transaction calldata") |

**Example:**
```yaml
paths:
  /api/earn/aprs:
    get:
      operationId: getCombinedAprs
      tags: [earn]
      summary: Combined BGT and Beradrome APRs for all vault strikes
      x-cache-policy:
        strategy: edge-revalidate
        ttl: 300
      responses:
        '200':
          description: APR data by strike tier
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CombinedAprsResponse'
```

### Phase 5: Update State

Update `grimoires/beacon/state.yaml`:
```yaml
actions:
  schemas_generated: 3
  last_generation: "{timestamp}"
  endpoints:
    - /api/generate-image
    - /api/download-image
    - /api/mint
```

### Phase 5.5: Event Emission

After all phases complete, emit the declared event:

```yaml
event: forge.beacon.actions_defined
data:
  endpoints_count: {schemas_generated}
  openapi_path: "grimoires/beacon/discovery/openapi.yaml"
```

---

## Schema Generation Rules

### Request Body Detection

```typescript
// Pattern 1: Explicit interface
interface GenerateImageRequest {
  prompt: string;
  style?: string;
}

// Pattern 2: Zod schema
const requestSchema = z.object({
  prompt: z.string(),
  style: z.string().optional()
})

// Pattern 3: Inline type
const body = await request.json() as { prompt: string }
```

### Response Detection

```typescript
// Pattern 1: Explicit return type
return NextResponse.json({ image: string, mintable: boolean })

// Pattern 2: Interface
interface GenerateImageResponse {
  image: string;
  mintable: boolean;
}
```

## Examples

### Example 1: Generate All Schemas

```
/beacon-actions
```

- Discovers all endpoints from `/.well-known/x402`
- Generates JSON Schema for each
- Creates combined OpenAPI spec

### Example 2: Single Endpoint

```
/beacon-actions /api/generate-image
```

- Generates schema for specific endpoint only
- Useful for updating individual schemas

## Output Files

| File | Description |
|------|-------------|
| `app/api/{path}/schema.json` | JSON Schema for endpoint |
| `grimoires/beacon/discovery/openapi.yaml` | Combined OpenAPI spec |

## Edge Cases

### No Type Information

If route handler lacks explicit types:
1. Generate minimal schema with `additionalProperties: true`
2. Add comment noting manual refinement recommended
3. Log warning in manifest

### Zod Schemas Present

If Zod is used:
1. Use `zod-to-json-schema` pattern
2. Preserve Zod validations in schema
3. Note Zod source in schema description

### Complex Nested Types

For nested objects:
1. Generate nested schema structure
2. Use `$ref` for reusable components
3. Place shared schemas in `/components/schemas`

## Dual-Nature Contract

### As an agent executing this skill:
- **Input**: Optional endpoint path, discovery endpoint data
- **Phases**: 1 → 2 → 2.5 → 3 → 4 → 4.5 → 5 → 5.5
- **Decisions**: If Zod schemas exist, use them over inferred types. If discovery endpoint exists, use its endpoint list.
- **Escalation**: If no type information available, generate minimal schema and flag for manual refinement.
- **Output**: JSON Schema per endpoint + combined OpenAPI spec in `grimoires/beacon/discovery/`

### As output consumed by other agents:
- **Format**: JSON Schema files + OpenAPI 3.0.3 YAML
- **Machine-readable fields**: Full request/response schemas, operationIds, tags, security schemes
- **Cross-references**: Consumes API inventory from `discovering-endpoints`, consumed by agent SDKs
- **Temporal markers**: Generation timestamp, spec version, schema source (Zod/inferred/manual)
