# Changelog

All notable changes to the Beacon construct will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
