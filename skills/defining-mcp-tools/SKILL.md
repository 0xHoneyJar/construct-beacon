# Skill: defining-mcp-tools

> Generate an MCP server from a construct's or service's action surface — the agent-fetchable mirror of `defining-actions`.

## Purpose

`defining-actions` produces JSON Schema + OpenAPI for HTTP endpoints — agents can discover and call the surface over HTTP. Many surfaces are *also* called by agents that prefer MCP (stdio for Claude Code/Codex/Cline; Streamable HTTP for production). This skill closes that loop: every action defined by Beacon gets a parallel MCP tool with the same input/output contract.

The skill follows the **constructs-mcp-shape** doctrine (lookup × list × validate × describe core operations, UNIX self-description, HARD/SOFT/LLM-OWNED tier model). It generates:

1. **MCP server entry-point** — a stdio-ready server using `@modelcontextprotocol/sdk`
2. **Streamable HTTP transport** (optional) — per-session bridge for production deploy
3. **Dockerfile + deploy manifest** (optional) — Path B self-host scaffolding
4. **`/.well-known/mcp` discovery endpoint** — agent-discoverable MCP metadata
5. **`beacon.yaml` MCP block** — declares shape (data/compute), paths (stdio/remote), tools list

**Required context:** none. The skill auto-detects target shape (construct repo vs app repo) and adapts. Optional: `mcp_config` overlay for deployment targets.

## Trigger

```
/beacon-mcp [--shape data|compute] [--paths stdio,remote] [--from-actions]
```

**Arguments:**
- `--shape data|compute` — Force construct shape. Default: detected from `construct.yaml` presence (construct → data) vs `package.json` Next.js (→ compute).
- `--paths stdio,remote` — Output paths to generate. Default: `stdio` (Path A always); add `remote` for Dockerfile + HTTP transport (Path B).
- `--from-actions` — Read the existing `grimoires/beacon/discovery/openapi.yaml` and generate one MCP tool per action. Default: true if openapi.yaml exists.

## Workflow

### Phase 1: Detect Target Shape

1. **Construct repo detection**
   - If `construct.yaml` at project root → shape: **data** (construct ships a pack of knowledge/data)
   - Read `construct.yaml.slug` → use as MCP server name
   - Locate data files referenced from skills (e.g., `core-lore/*.md`, `data/*.json`)

2. **App repo detection**
   - If `package.json` with Next.js dependency → shape: **compute** (service ships HTTP routes)
   - If `app/.well-known/x402/route.ts` exists → mark as Beacon-described already
   - If existing `Dockerfile` → respect, don't overwrite

3. **Hybrid detection**
   - Both `construct.yaml` AND `package.json` present → ask via `AskUserQuestion`:
     - "Generate MCP for construct data or for app HTTP routes?"

### Phase 2: Discover Action Surface

If `--from-actions` (default when `openapi.yaml` exists):

1. **Read OpenAPI fragment** at `grimoires/beacon/discovery/openapi.yaml`
2. **Parse paths + operations** — each `operationId` becomes an MCP tool name
3. **Extract Zod / JSON Schema** for inputs (preserves `defining-actions`'s validations)
4. **Map x-payment extension** to MCP tool annotations (informational)

Otherwise (no openapi.yaml — construct-first authoring):

1. **Scan construct skills** for action declarations
2. **Prompt via AskUserQuestion** for tool list:
   - "What canonical operations does this construct expose?"
   - Suggest the four-op core: `lookup_<noun>`, `list_<noun>`, `validate_<noun>`, `describe_<noun>`

### Phase 2.5: Tool Naming Convention

Enforce **`{module}__{verb}_{noun}`** convention:

| Detected operationId | Generated MCP tool name |
|---|---|
| `getZone` | `mcp__{slug}__lookup_zone` |
| `listFactors` | `mcp__{slug}__list_factors` |
| `validateArchetype` | `mcp__{slug}__validate_archetype` |
| `describeFactor` | `mcp__{slug}__describe_factor` |

`{slug}` comes from `construct.yaml.slug` (data shape) or service name (compute shape). Override via `--prefix NAME`.

If detected name doesn't match `{verb}_{noun}` pattern, prompt via AskUserQuestion to map to canonical verb. Verbs: `lookup`, `list`, `validate`, `describe`, `get` (read-models tier-2).

### Phase 3: Generate MCP Server (`bin/mcp.ts` or `src/mcp/server.ts`)

Generate target file based on shape:

**Data shape** → `bin/mcp.ts`:
```typescript
#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { lookupZone } from "../src/lookups/zone.js";
// ...one import per tool

export function createServer(): McpServer {
  const server = new McpServer({ name: "{slug}-mcp", version: "{version}" });

  server.tool(
    "lookup_zone",
    "Look up a single zone by canonical slug.",
    z.object({ slug: z.string() }).shape,
    async (input) => ({
      content: [{ type: "text", text: JSON.stringify(await lookupZone(input.slug)) }],
    }),
  );

  // ...one tool() call per generated tool

  return server;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const server = createServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
}
```

**Compute shape** → `src/mcp/server.ts` (factory; transport wired separately):
- Same `createServer()` factory
- Tools call existing route handlers via thin adapter (DRY with HTTP routes)
- No stdio bootstrap — transport is composed in Phase 5

**Lookup stubs** (data shape only):
- Generate `src/lookups/{noun}.ts` for each lookup tool
- Each stub reads from data files declared in construct (or prompts via AskUserQuestion if no data path is detectable)
- Mark with `// TODO(beacon-mcp): wire to real data source` — author fills in

### Phase 4: Generate Streamable HTTP Transport (if `--paths` includes `remote`)

Generate `src/mcp/transport.ts` following the score-mcp per-session pattern:
- `Mcp-Session-Id` header → fresh `StreamableHTTPServerTransport` + `createServer()` per session
- LRU eviction (default `MAX_SESSIONS=16`)
- Idle TTL (default 5 min) + total TTL (default 30 min) GC
- Hono adapter for `app/api/mcp/route.ts` (Next.js) or `index.ts` (Node service)

Generate route handler:

**Next.js (App Router)** → `app/api/mcp/route.ts`
**Node service** → wired into existing entry-point (insert into `index.ts`)

### Phase 5: Generate Discovery Endpoint

Generate `app/.well-known/mcp/route.ts` (Next.js) or static `dist/.well-known/mcp.json` (Node):

```json
{
  "version": "1.0",
  "name": "{slug}-mcp",
  "transports": [
    { "kind": "stdio", "command": "npx", "args": ["{slug}", "mcp"] },
    { "kind": "streamable-http", "endpoint": "{base_url}/api/mcp" }
  ],
  "tools": [
    { "name": "lookup_zone", "description": "...", "inputSchema": { ... } }
  ],
  "shape": "data",
  "version_pin": "1.0.0",
  "x-beacon": { "generated_by": "defining-mcp-tools@2.1.0" }
}
```

This composes with `discovering-endpoints` — agents can hit `/.well-known/x402` for HTTP commerce, `/.well-known/mcp` for MCP discovery, and the same Beacon-described surface backs both.

### Phase 6: Generate Dockerfile (if `--paths` includes `remote`)

Only if no existing Dockerfile. Template follows score-mcp:

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

Generate `railway.toml` (or `fly.toml` based on `--target` flag) with:
- `healthcheckPath = "/healthz"`
- `restartPolicyType = "ON_FAILURE"`

### Phase 7: Generate `beacon.yaml` MCP Block

Append (or create) `beacon.yaml` at project root:

```yaml
mcp:
  shape: data    # or "compute"
  paths:
    - stdio       # always present after this skill runs
    - remote      # only if --paths includes remote
  remote:
    transport: streamable-http
    endpoint: ${MCP_REMOTE_ENDPOINT}   # author fills via env or static
  tools:
    - lookup_zone
    - list_zones
    - validate_world_element
    # ...full tool list
  source_of_truth:
    type: git_repo   # or "live_db"
    files:
      - core-lore/festival-zones-vocabulary.md
      - data/archetypes.json
  payment:
    enabled: false   # set true after running /beacon-pay
```

This is the contract layer — registry + downstream consumers read this to know what MCP shape the construct exposes.

### Phase 8: Update State

Update `grimoires/beacon/state.yaml`:
```yaml
mcp:
  shape: data
  paths_generated:
    - stdio
    - remote
  tools_generated: 7
  last_generation: "{timestamp}"
  files:
    - bin/mcp.ts
    - src/mcp/server.ts
    - src/mcp/transport.ts
    - app/.well-known/mcp/route.ts
    - Dockerfile
    - beacon.yaml
```

### Phase 9: Event Emission

After all phases complete, emit:

```yaml
event: forge.beacon.mcp_generated
data:
  shape: "data"
  paths: ["stdio", "remote"]
  tools_count: 7
  source_actions: 7  # if --from-actions
```

---

## Schema Generation Rules

### Tool Input Schemas

- If source action has Zod schema → reuse via `import { schemaName } from '@/schemas'`
- If source has JSON Schema only → convert via `json-schema-to-zod` pattern (or inline `z.object({...})`)
- If neither → generate `z.object({}).passthrough()` and flag for manual refinement

### Tool Output Format

All tools return `{ content: [{ type: "text", text: string }] }` per MCP spec. Inner text is `JSON.stringify(result)` for structured outputs. Author may upgrade to `type: "resource"` or multi-content for richer surfaces.

### Tier Annotation (HARD/SOFT/LLM-OWNED)

If construct declares anti-hallucination tiers in `beacon.yaml.mcp.tiers`:

```yaml
mcp:
  tiers:
    hard:
      - zone.slug
      - zone.emoji
      - archetype.canonical_name
    soft:
      - zone.vibe
      - archetype.lore
    llm_owned:
      - narrator_voice
      - activity_class
```

Generate inline JSDoc on each tool documenting which tier the response fields are. Consumers reading the MCP discovery endpoint see the tier model and can write entity-coverage validators against the HARD set.

---

## Examples

### Example 1: Construct adopting MCP (data-shaped)

```bash
cd construct-mibera-codex/
/beacon-actions                 # generates JSON Schema + OpenAPI from construct skills
/beacon-mcp --paths stdio       # generates stdio MCP entry-point
```

Output:
- `bin/mcp.ts` — stdio MCP server with `lookup_zone`, `lookup_archetype`, `list_zones`, `validate_world_element`
- `src/lookups/{zone,archetype}.ts` — stubs to fill in
- `beacon.yaml` — declares `shape: data, paths: [stdio]`

Validates immediately: install pack via Loa, MCP works in Claude Code.

### Example 2: Add remote deployment later

```bash
/beacon-mcp --paths stdio,remote
```

Adds:
- `src/mcp/transport.ts` — Streamable HTTP transport
- `app/api/mcp/route.ts` — Hono-style handler (or Express, detected)
- `Dockerfile` + `railway.toml`
- Updates `beacon.yaml` paths to `[stdio, remote]`

Author then deploys (Railway/Fly/Render) to get Path B.

### Example 3: Existing service (compute-shaped) adopting MCP

```bash
cd score-mibera/
/beacon-discover && /beacon-actions  # if not yet Beacon-described
/beacon-mcp --shape compute --paths remote
```

Generates `src/mcp/server.ts` factory + transport, wires into existing service entry-point. Compose with existing route handlers (thin adapter pattern).

---

## Output Files

| File | Always | Notes |
|---|---|---|
| `bin/mcp.ts` (data) or `src/mcp/server.ts` (compute) | yes | Tool definitions + factory |
| `src/lookups/{noun}.ts` | data shape only | Stub per lookup tool — author fills in data wiring |
| `src/mcp/transport.ts` | if `--paths` includes `remote` | Per-session HTTP bridge |
| `app/api/mcp/route.ts` | if `--paths` includes `remote` AND Next.js detected | Adapter |
| `app/.well-known/mcp/route.ts` | yes | Discovery endpoint |
| `Dockerfile` + `railway.toml` | if `--paths` includes `remote` AND no existing Dockerfile | Path B scaffolding |
| `beacon.yaml` (mcp block) | yes | Contract declaration |
| `grimoires/beacon/state.yaml` | yes | Generation state |

---

## Edge Cases

### No action surface yet

If neither `openapi.yaml` nor route handlers exist, the skill prompts via AskUserQuestion for the four-op core noun list, then generates stubs:

> "What canonical entities does this construct/service expose?"
> e.g., zone, archetype, factor, dimension

For each entity, generate the four tools (lookup_X, list_X, validate_X, describe_X), each with a TODO stub.

### Existing MCP server in repo

If `bin/mcp.ts` or `src/mcp/server.ts` exists already:
1. Read existing tool list
2. Compute diff against actions surface
3. Append missing tools (don't overwrite existing)
4. Flag in state.yaml: `manual_tools: [...existing tool names]`

### Composition with `defining-actions` and `accepting-payments`

- **defining-actions FIRST**: produces OpenAPI + JSON Schema; this skill consumes it
- **defining-mcp-tools SECOND**: generates MCP tools paralleling each action
- **accepting-payments AFTER**: wraps tool surface with x402 (consume `beacon.yaml.mcp.tools` to know what to price)

If the user runs `/beacon-mcp` before `/beacon-actions`, the skill warns and offers to run `/beacon-actions` first.

### Construct doesn't have data

If construct ships skills (knowledge) only, not data files:
- Generate stubs that throw `Error("MCP tool not implemented — wire to data source")`
- Flag in state.yaml: `requires_manual_wiring: true`
- Author fills in lookups, then re-runs `/beacon-mcp --refresh` to regenerate state

---

## Dual-Nature Contract

### As an agent executing this skill:
- **Input**: optional flags (`--shape`, `--paths`, `--from-actions`, `--prefix`); existing `openapi.yaml` if available
- **Phases**: 1 → 2 → 2.5 → 3 → 4 → 5 → 6 → 7 → 8 → 9
- **Decisions**:
  - If construct.yaml present, prefer data shape and stdio path A
  - If app, prefer compute shape and remote path
  - If both, ask via AskUserQuestion
  - If existing MCP file, merge instead of overwrite
- **Escalation**: if no action surface and no entity list → AskUserQuestion for four-op nouns; if naming doesn't match `{verb}_{noun}` → AskUserQuestion to remap
- **Output**: MCP server scaffolding + transport + discovery + beacon.yaml + state update

### As output consumed by other agents:
- **Format**: TypeScript MCP server using `@modelcontextprotocol/sdk`, Streamable HTTP transport per spec, JSON discovery endpoint
- **Machine-readable fields**: tool list with input schemas in `/.well-known/mcp`; `beacon.yaml.mcp` block with shape/paths/tools/tiers
- **Cross-references**: consumes `defining-actions` output (OpenAPI); produces input for `accepting-payments` (x402 wrapping); registered with constructs.network registry via `beacon.yaml`
- **Temporal markers**: generation timestamp + Beacon version in discovery endpoint's `x-beacon` field

---

## Doctrine references

This skill implements the patterns from:

- **`constructs-mcp-shape`** (vault) — the four-op core surface (lookup × list × validate × describe), UNIX self-description, JOIN-bridge pattern, HARD/SOFT/LLM-OWNED tier model
- **`constructs-mcp-deployment-topology`** (vault) — three host paths (stdio/self-host/registry-gateway); this skill generates Path A by default, Path B on flag, Path C declarations for future registry consumption
- **`mcp-wraps-cli-pattern`** (vault) — every canonical CLI gets an MCP mirror; this skill is the codegen path that makes the mirror automatic
- **score-mibera/src/mcp/** — reference implementation (9-tool MCP, Streamable HTTP per-session transport, hallucination-guard validator)

When the construct ecosystem grows, this skill is the single point that turns a Beacon-described surface into an agent-fetchable MCP — no per-construct hand-rolling.
