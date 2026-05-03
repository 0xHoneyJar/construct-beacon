---
name: discovering-endpoints
description: Generate `/.well-known/x402` discovery endpoint for agent commerce — advertises services, pricing, and payment requirements. Slash command `/beacon-discover`.
user-invocable: true
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Skill: discovering-endpoints

> Generate x402 v2 discovery endpoint for agent commerce.
>
> **Required context:** `chain_config` — see `contexts/overlays/chain-config.json.example`

## Purpose

AI agents need to discover what services a business offers and how to pay for them. This skill generates a `/.well-known/x402` endpoint that advertises:

- Available payment-enabled endpoints
- Supported networks and tokens
- Pricing for each endpoint
- Subsidy information

The generated endpoint follows the x402 v2 protocol specification.

> **Required context**: This skill requires a `chain-config` overlay. See `contexts/overlays/chain-config.json.example`.

## Trigger

```
/beacon-discover [--service NAME]
```

**Arguments:**
- `--service NAME` - Optional service name (detected from reality files if not provided)

## Workflow

### Phase 1: Reality Detection

1. **Load reality files** from `grimoires/loa/reality/`
   - Check for `contracts.md` - NFT addresses, ABIs
   - Check for `services.md` - Image gen, data feeds
   - Check for `api.md` - Existing route patterns

2. **If reality not found**, prompt user via AskUserQuestion:
   - Service name
   - Available endpoints
   - Contract addresses (if minting)
   - Subsidy provider

### Phase 2: Detect Codebase Patterns

1. **Import style detection**
   ```
   Search for existing import patterns:
   - @/ prefix (Next.js standard)
   - ~/ prefix
   - Relative imports
   ```

2. **Existing API routes**
   ```
   Scan app/api/ for existing route handlers
   Identify potential payment-enabled endpoints
   ```

### Phase 3: Configure Discovery Response

Build the x402 v2 discovery response structure:

```typescript
{
  version: '2.0',
  capabilities: {
    payments: {
      kinds: ['exact'],
      networks: ['{context:chain_config.network_id}'],
      tokens: ['{context:chain_config.default_token}']
    },
    extensions: ['discovery', 'receipts', 'subsidy']
  },
  endpoints: [
    {
      path: '/api/generate-image',
      method: 'POST',
      description: 'Generate AI image from prompt',
      pricing: { amount: '1', currency: '{context:chain_config.default_token}', subsidized: true }
    }
  ],
  metadata: {
    name: '{{SERVICE_NAME}}',
    subsidy: { provider: '{context:chain_config.org_name}' }
  }
}
```

### Phase 4: Generate Code

1. **Load template** from `resources/templates/well-known-route.ts.md`

2. **Apply detected patterns**:
   - Import style
   - Endpoint list
   - Pricing configuration

3. **Write to target** `app/.well-known/x402/route.ts`

### Phase 5: Write Manifest

Create manifest at: `grimoires/beacon/discovery/service-manifest.md`

Include:
- Generated file location
- Endpoints registered
- Pricing summary
- Test command

### Phase 5.5: API Inventory Generation

Generate a structured inventory of all API routes for cross-skill consumption:

1. **Scan all API routes** — Glob `app/api/**/route.ts`
2. **For each route, extract:**
   - HTTP method(s) (GET, POST, etc.)
   - Authentication method (header check, middleware, none)
   - Rate limiting (Upstash, custom, none)
   - Cache policy (revalidate, force-dynamic, none)
   - Data sources (external APIs, databases, on-chain)
   - Description from comments or function name

3. **Classify agent utility:**
   - **Tier 1**: Direct agent value (data retrieval, generation, actions)
   - **Tier 2**: Supporting infrastructure (auth, analytics, profiles)
   - **Tier 3**: Internal/admin only

4. **Write inventory** to `grimoires/beacon/discovery/api-inventory.md`

This inventory is consumed by `defining-actions` for OpenAPI generation and by `accepting-payments` for monetization candidates.

### Phase 6: Update State

Update `grimoires/beacon/state.yaml`:
```yaml
discovery:
  count: {increment}
  last_generation: "{timestamp}"
  endpoints:
    - path: /api/generate-image
      price: "1 {context:chain_config.default_token}"
```

### Phase 6.5: Event Emission

After all phases complete, emit the declared event:

```yaml
event: forge.beacon.discovery_generated
data:
  endpoint_path: "/.well-known/x402"
  service_name: "{{SERVICE_NAME}}"
```

---

## Protocol Reference

### x402 v2 Headers

**Request:**
```
X-Payment: <base64-encoded-payment>
X-Payment-Version: 2
X-Payment-Network: {context:chain_config.network_id}
```

**Response (402):**
```
X-Payment-Required: <base64-encoded-requirements>
X-Payment-Version: 2
X-Payment-Token: {context:chain_config.default_token}
```

### Network IDs (CAIP-2)

# Example configurations
| Network | ID |
|---------|-----|
| Ethereum Mainnet | `eip155:1` |
| Base | `eip155:8453` |
| Berachain Mainnet | `eip155:80094` |

Your project's network is configured via `{context:chain_config.network_id}`.

## Examples

### Example 1: Basic Discovery

```
/beacon-discover
```

With reality files present:
- Detects service name from `services.md`
- Identifies endpoints from `api.md`
- Generates discovery endpoint
- Creates manifest

### Example 2: Custom Service Name

```
/beacon-discover --service mibera-generator
```

- Uses provided service name
- Prompts for missing endpoint info
- Generates discovery endpoint

## Edge Cases

### No Reality Files

If `grimoires/loa/reality/` is empty or missing:
1. Prompt user for service name
2. Ask about available endpoints
3. Request pricing information
4. Generate with user-provided values

### Existing Discovery Endpoint

If `app/.well-known/x402/route.ts` already exists:
1. Warn user
2. Ask for confirmation to overwrite
3. Or generate to `.generated.ts` suffix

### Non-Next.js Project

If no `app/` directory:
1. Warn: "No Next.js App Router detected"
2. Generate to suggested location
3. Provide manual integration guide

## Output Files

| File | Description |
|------|-------------|
| `app/.well-known/x402/route.ts` | Discovery endpoint |
| `grimoires/beacon/discovery/service-manifest.md` | Generation manifest |

## Dual-Nature Contract

### As an agent executing this skill:
- **Input**: Optional service name, chain config context overlay
- **Phases**: 1 → 2 → 3 → 4 → 5 → 5.5 → 6 → 6.5
- **Decisions**: If reality files exist, auto-detect. If not, prompt user. Generate API inventory alongside discovery endpoint.
- **Escalation**: If no API routes found, ask user to specify endpoints manually.
- **Output**: Discovery endpoint + API inventory + manifest in `grimoires/beacon/discovery/`

### As output consumed by other agents:
- **Format**: TypeScript route handler + structured markdown inventory
- **Machine-readable fields**: Endpoint paths, methods, pricing, auth status, rate limit status
- **Cross-references**: API inventory consumed by `defining-actions` and `accepting-payments`
- **Temporal markers**: Generation timestamp, discovery endpoint version
