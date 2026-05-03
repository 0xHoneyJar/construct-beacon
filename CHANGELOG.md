# Changelog

All notable changes to the Beacon construct will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Doctrine

**Naming disambiguation · `construct-beacon` vs `@0xhoneyjar/beacon-schema` (2026-05-03 · v0.3 federation cycle)**

Two related-but-distinct names emerged during the v0.3 MCP federation broadcast cycle. They are NOT the same thing.

- **`construct-beacon`** is the **authoring construct** — it provides the skills you use to AUTHOR a `beacon.yaml` for your MCP construct (`defining-mcp-tools`, `generating-markdown`, `auditing-content`, `accepting-payments`, `defining-actions`). Lives in the constructs-network registry. Audience: construct authors who want beacon authoring tooling in their workspace.
- **`@0xhoneyjar/beacon-schema`** is the **runtime schema package** — the npm package that the freeside-mcp-gateway uses to VALIDATE beacons at boot time and that each construct's build step uses to VALIDATE beacons at deploy time. Lives in `freeside-mcp-gateway/packages/beacon-schema/` (workspace package). Audience: gateway implementation, construct build steps, future external integrators.

The relationship: `construct-beacon` HELPS YOU AUTHOR a `beacon.yaml`; `@0xhoneyjar/beacon-schema` VALIDATES that the beacon.yaml conforms to the federation contract.

No code changes in this construct for the cycle — informational only. Future cycle: the `defining-mcp-tools` skill MAY emit a default `beacon.yaml` stub validated against `@0xhoneyjar/beacon-schema` (closes the loop).

Reference: `grimoires/bonfire/specs/freeside-mcp-federation-v0.3-broadcast-sdd-2026-05-03.md` §1.4.

## [2.1.0] - 2026-04-30

### Added

- **`defining-mcp-tools` skill** — codegen path for the `constructs-mcp-shape` doctrine. Generates an MCP server (stdio + optional Streamable HTTP transport) from a construct's or service's action surface. Trigger: `/beacon-mcp [--shape data|compute] [--paths stdio,remote]`.
- **Path A (stdio) default** — every Beacon-described surface gets a `bin/mcp.ts` stdio entry-point that works in Claude Code, Codex, Cline, or any stdio-aware MCP consumer. Zero deploy cost.
- **Path B (remote) opt-in** — `--paths stdio,remote` adds Streamable HTTP transport (`src/mcp/transport.ts`), Hono/Next.js adapter, Dockerfile, and `railway.toml` for self-host. Mirrors score-mibera's per-session HTTP pattern.
- **`/.well-known/mcp` discovery endpoint** — sibling to `/.well-known/x402`. Advertises tool list, transports, and shape so registries (constructs.network) and agents can discover MCP capability.
- **`beacon.yaml` `mcp` block** — declares construct shape (data/compute), output paths (stdio/remote), tool list, and optional anti-hallucination tier annotations (HARD/SOFT/LLM-OWNED). Contract layer between construct authors and the registry.
- **Tool-naming convention enforcement** — `mcp__{slug}__{verb}_{noun}` with verbs ∈ {lookup, list, validate, describe, get}. Predictable surfaces across constructs.
- **`forge.beacon.mcp_generated` event** — emitted on MCP scaffold generation. Payload: shape, paths, tools_count, source_actions.
- **Composes with `defining-actions`** — when `grimoires/beacon/discovery/openapi.yaml` exists, the skill consumes it and generates one MCP tool per action with preserved input schemas.
- **Composes with `accepting-payments`** — generated `beacon.yaml.mcp.tools` list feeds x402 wrapping; per-tool pricing supported.

### Changed

- Construct version 2.0.0 → 2.1.0
- `description` and `short_description` updated to reflect MCP codegen capability
- Skill list now 7 items (was 6)

### Doctrine

This release implements the patterns crystallized in:

- **`constructs-mcp-shape`** (vault) — four-op core surface (lookup × list × validate × describe), UNIX self-description, JOIN-bridge pattern, anti-hallucination tier model
- **`constructs-mcp-deployment-topology`** (vault) — three host paths (stdio default, self-host on flag, registry-gateway in future); `defining-mcp-tools` generates Path A and B
- **`mcp-wraps-cli-pattern`** (vault) — every canonical CLI gets an MCP mirror; this skill is the codegen path

Reference implementation: score-mibera `src/mcp/{server,transport,hallucination-guard}.ts`.

## [2.0.0] - 2026-02-23

### Added

- **Audit configuration schema** — `audit-config.schema.json` for project-specific known data sources, deprecated features, brand terms, and financial data patterns
- **4 new events** — `audit_completed`, `chunks_optimized`, `markdown_generated`, `actions_defined` for cross-construct coordination
- **Full-site audit mode** — `/audit-llm --all` scans all pages and API routes in parallel
- **Code Pattern Scanning phase** (Phase 1.5) — detects fabrication patterns (`Math.random()`, hardcoded APR/APY) and dead code
- **Severity Classification phase** (Phase 4.5) — CRITICAL/HIGH/MEDIUM/LOW criteria
- **API Route Assessment phase** (Phase 2.5) — auth, rate limiting, cache, agent utility scoring
- **llms.txt generation mode** — `/add-markdown llms.txt` for Vercel-pattern machine-readable site descriptions
- **Pattern 6: Data Integrity Fix** — detects and fixes `Math.random()`/hardcoded financial values
- **Pattern 7: Contradiction Resolution** — resolves conflicting states across pages
- **Effort Estimation Table** — classifies fixes as Tiny/Small/Medium
- **Audit Report Mode** — `/optimize-chunks --from-audit` parses findings into code rewrites
- **API Inventory Generation** (Phase 5.5) — structured inventory for cross-skill consumption
- **OpenAPI Generation Standards** — tag/operationId/$ref/error/security/cache conventions
- **next-safe-action/Zod detection** — extracts schemas from existing validation patterns
- **Rate Limiting Audit pre-check** (Phase 1.5) — audits existing rate limiting before generating middleware
- **Dual-Nature Contract** section added to all 6 skills
- **Expanded install.sh** — creates `discovery/` and `sync/` grimoire directories, v2 state schema
- **New templates** — `full-audit-report.md`, `api-assessment.md`

### Changed

- Construct version 1.0.0 → 2.0.0
- Discovery/Action skills templatized with `{context:chain_config.*}` references
- `optimizing-chunks` effort_hint `small` → `medium`
- `discovering-endpoints` allowed-tools now includes `Bash`
- `quick_start.command` corrected to `/audit-llm`

### Fixed

- `install.sh` now creates `discovery/` and `sync/` grimoire directories
- State YAML template includes all sections used by all 6 skills

## [1.0.0] - 2026-02-17

### Added

- Initial extraction from forge with construct schema v3
- 6 agent-readiness skills across 3 layers
- Identity system (persona + expertise)
- Context overlay system for chain configuration
- CI validation workflow
