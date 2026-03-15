# Skill: auditing-content

> Analyze pages for LLM trust signals and retrieval resilience.

## Purpose

AI systems retrieve and reuse content in unpredictable ways. Content that lacks proper scoping, evidence, or context can be misquoted, leading to brand misrepresentation and FUD propagation.

This skill audits pages against a 5-layer trust model based on how LLMs evaluate and reuse information.

## Trigger

```
/audit-llm [path]
```

**Arguments:**
- `path` - The page path to audit (e.g., `/pricing`, `/security`, `docs/api.md`)

## Workflow

### Phase 1: Content Discovery

1. **Locate the target content**
   ```
   - If path is a file (e.g., `docs/api.md`), read directly
   - If path is a route (e.g., `/pricing`), search for:
     - app/{path}/page.tsx
     - app/{path}/page.mdx
     - pages/{path}.tsx
     - content/{path}.md
   ```

2. **Extract text content**
   - Read the file(s)
   - Identify all text content, headings, claims, numbers, links
   - Note line numbers for each finding

### Phase 1.5: Crawler Reachability Check

Before analyzing content, check whether AI crawlers can reach the site. This is a lightweight pre-flight — not a full crawler verification.

1. **Locate robots.txt**
   ```
   Search for:
   - public/robots.txt (static file)
   - app/robots.ts or app/robots.txt/route.ts (dynamic generation)
   ```

2. **Check for AI crawler directives**

   Scan for `User-agent` directives targeting these crawlers:

   | Crawler | Operator | Purpose |
   |---------|----------|---------|
   | `GPTBot` | OpenAI | ChatGPT Browse, training |
   | `OAI-SearchBot` | OpenAI | ChatGPT search results |
   | `ClaudeBot` | Anthropic | Claude web access |
   | `PerplexityBot` | Perplexity | Search and citation |
   | `Googlebot` | Google | Google AI Overviews (indirect) |

3. **Flag conditions**

   | Condition | Severity | Note |
   |-----------|----------|------|
   | All AI crawlers blocked (`Disallow: /`) | HIGH | May be unintentional — verify with site owner |
   | Some AI crawlers blocked selectively | MEDIUM | Intentional access control — note which are blocked |
   | x402 endpoints enabled but AI crawlers blocked | HIGH | Contradiction: advertising to agents while blocking their crawlers |
   | No robots.txt found | LOW | Default behavior is allow-all |

4. **Limitations note**

   Include in report: "robots.txt does not control Google AI Overviews, Bing Copilot, or non-compliant crawlers. Content may appear in AI-generated summaries even when crawlers are blocked, as these systems can source from existing search indexes."

5. **Record findings** as a pre-flight section in the audit report, before Trust Layer Analysis.

---

### Phase 1.75: Code Pattern Scanning

Before analyzing content semantics, scan for code-level fabrication and dead code patterns.

#### Fabrication Patterns

Scan all TSX/TS files in the target scope for these patterns. **Context qualifiers**: matches MUST be within rendering/display context (within 15 lines of `return`, JSX tags like `<div>`, `<span>`, `<p>`, or template literals used in UI). **Exclusions**: skip test files (`*.test.*`, `*.spec.*`, `__tests__/`), seed scripts (`seed.*`, `mock.*`), and configuration files (`*.config.*`).

| Pattern | Regex | Severity | Example |
|---------|-------|----------|---------|
| Random data generators | `Math\.random\(\)` in data-display context | CRITICAL | Price charts using `Math.random()` for historical data |
| Hardcoded financial values | `(?:apr\|apy\|rate)\s*[=:]\s*['"]?\d+\.?\d*['"]?` (case-insensitive) | CRITICAL | `currentAPR="67.50"` disconnected from live data |
| Fabricated formulas | `\d{3,}\s*\/\s*\(\s*\w+\s*\+\s*\d+\s*\)` | CRITICAL | `apy={7000/(index+1)}` producing fake yield rates |
| Hardcoded token amounts | `\b\d{4,}\b` in financial display context (exclude CSS z-index, port numbers, pixel dimensions, timestamps) | HIGH | Random raffle numbers displayed as real entry IDs |

#### Dead Code Patterns

| Pattern | Regex | Severity |
|---------|-------|----------|
| Props accepted but never used | Component accepts `data`/`value` prop but renders hardcoded values | HIGH |
| Commented-out data sources | `//.*fetch\|//.*api\|//.*query` near active display code | MEDIUM |
| TODO placeholders | `TODO.*data\|FIXME.*source\|HACK.*hardcod` | MEDIUM |

For each detection, record:
- File path and line number(s)
- Exact code snippet
- Why it's problematic for AI agents
- Severity classification

### Phase 2: Trust Layer Analysis

Score each layer on a 0-10 scale based on the checklist items found.

---

#### Layer 1: Source Legitimacy (20% weight)

**Question**: Can AI systems confidently attribute this content?

**Checklist:**
- [ ] **Brand name defined** - Company/product name appears clearly
- [ ] **Entity context** - Legal entity or organization type mentioned
- [ ] **Consistent naming** - Same brand name used throughout (no "we" without antecedent)
- [ ] **About/company link** - Reference to who is making these claims

**Scoring:**
- 4/4 items = 10 points
- 3/4 items = 7.5 points
- 2/4 items = 5 points
- 1/4 items = 2.5 points
- 0/4 items = 0 points

---

#### Layer 2: Claim Verifiability (25% weight)

**Question**: Can claims be verified or falsified?

**Checklist:**
- [ ] **Evidence adjacency** - Claims have nearby links to proof (docs, audits, status page)
- [ ] **Specific numbers** - Quantitative claims include methodology/date
- [ ] **Falsifiable statements** - Claims that could be proven wrong (vs vague marketing)
- [ ] **No orphan superlatives** - "Best", "leading", etc. have context or are avoided

**Scoring:**
- 4/4 items = 10 points
- 3/4 items = 7.5 points
- 2/4 items = 5 points
- 1/4 items = 2.5 points
- 0/4 items = 0 points

---

#### Layer 3: Cross-Source Consistency (20% weight)

**Question**: Does this content contradict other pages?

**Checklist:**
- [ ] **Internal consistency** - Pricing/features match other pages on site
- [ ] **No outdated content** - No old blog posts with conflicting information
- [ ] **Temporal coherence** - Dates are consistent across pages
- [ ] **Canonical signals** - Page indicates if it's the authoritative source

**Scoring:**
- 4/4 items = 10 points
- 3/4 items = 7.5 points
- 2/4 items = 5 points
- 1/4 items = 2.5 points
- 0/4 items = 0 points

**Note**: This layer may require checking other pages. If unable to verify, score conservatively and note "Unable to verify cross-source consistency."

- [ ] **Contradiction cluster detection** - Multiple pages simultaneously asserting and denying the same feature state (e.g., "Feature X DISCONTINUED" banner + "Earning Feature X" label on the same or adjacent pages)

---

#### Layer 4: Contextual Integrity (25% weight)

**Question**: Will claims be misleading if quoted out of context?

**Checklist:**
- [ ] **Scoped claims** - "Applies to: [specific plans/tiers/regions]" present
- [ ] **Temporal markers** - "As of [date]" or "Current as of [date]" present
- [ ] **Exception clarity** - "Does NOT include" or limitations stated
- [ ] **Self-contained paragraphs** - Key claims include enough context to stand alone

**Scoring:**
- 4/4 items = 10 points
- 3/4 items = 7.5 points
- 2/4 items = 5 points
- 1/4 items = 2.5 points
- 0/4 items = 0 points

---

#### Layer 5: Structural Cues (10% weight)

**Question**: Does the structure signal factual vs marketing content?

**Checklist:**
- [ ] **Descriptive headers** - Headers describe content (not just "Overview", "Features")
- [ ] **Structured data** - Lists/tables for comparable information
- [ ] **Code blocks** - Technical content in proper formatting
- [ ] **Low marketing ratio** - Superlatives < 10% of copy
- [ ] **Code-level structural cues** - No random number generators in data display paths, no hardcoded financial values disconnected from data sources

**Scoring:**
- 4/4 items = 10 points
- 3/4 items = 7.5 points
- 2/4 items = 5 points
- 1/4 items = 2.5 points
- 0/4 items = 0 points

---

### Phase 3: Calculate Overall Score

```
Overall Score = (L1 × 0.20) + (L2 × 0.25) + (L3 × 0.20) + (L4 × 0.25) + (L5 × 0.10)
```

**Risk Level Mapping:**
| Score Range | Risk Level | Meaning |
|-------------|------------|---------|
| 0.0 - 4.0 | **High** | Content likely to be misrepresented |
| 4.0 - 7.0 | **Medium** | Some claims vulnerable to misquoting |
| 7.0 - 10.0 | **Low** | Content designed for AI retrieval |

### Phase 4: Identify High-Risk Claims

Scan the content for these patterns:

| Pattern | Risk | Detection |
|---------|------|-----------|
| Absolute claims | High | "we don't", "never", "always" without scope |
| Unscoped numbers | High | Numbers without date/methodology nearby |
| Vague superlatives | Medium | "best", "leading", "world-class", "enterprise-grade" |
| Missing temporal | Medium | Claims without "as of" or date reference |
| Orphan facts | Medium | Important claims mentioned once, never linked |

For each high-risk claim, record:
- Line number
- Exact claim text
- Issue type
- Specific recommendation

### Phase 4.5: Severity Classification

Classify all findings using this criteria:

| Severity | Criteria | Action |
|----------|----------|--------|
| **CRITICAL** | Fabricated data presented as real (Math.random, hardcoded financials). Active contradiction clusters. Raw transaction calldata exposed without auth. | Must fix before AI readiness claim. Block deployment if possible. |
| **HIGH** | Missing rate limiting on sensitive endpoints. Brand inconsistencies. Props rendering stale/disconnected data. | Fix in current sprint. |
| **MEDIUM** | Missing temporal markers. Vague superlatives. Orphan facts without links. | Fix in next sprint. |
| **LOW** | Structural improvements. Missing canonical signals. Marketing language in technical pages. | Backlog. |

Count findings per severity for the executive summary.

### Phase 5: Generate Output

Write the audit report to: `grimoires/beacon/audits/{page-slug}-audit.md`

Use the template from `resources/templates/audit-report.md`.

### Phase 5.5: Full-Site Audit Mode

When invoked as `/audit-llm --all`:

1. **Discover all pages** — Glob `app/**/page.tsx`, `app/**/page.mdx`
2. **Discover all API routes** — Glob `app/api/**/route.ts`
3. **Run per-page audits in parallel** — Each page gets a trust layer analysis
4. **Run API route assessment** — For each route, evaluate:

| Check | Method | Scoring |
|-------|--------|---------|
| Authentication | Grep for auth middleware, header checks | None=0, Basic=5, Full=10 |
| Rate limiting | Grep for Upstash, rate-limit imports | None=0, Present=10 |
| Cache policy | Check for `revalidate`, `cache` exports | None=0, Configured=10 |
| Agent utility | Manual assessment of endpoint purpose | Low/Medium/High |
| Security exposure | Check for raw calldata, private keys, admin ops | Critical/Safe |

5. **Synthesize** — Aggregate per-page scores into single full-site report
6. **Score progression table** — Include in output:

| State | Score | Description |
|-------|-------|-------------|
| Current | {score}/10 | As-is assessment |
| Post-P0 | {estimate}/10 | After fixing CRITICAL findings |
| Post-P1 | {estimate}/10 | After fixing HIGH findings |
| AI-Ready | 7.0+/10 | Threshold for agent consumption |

Write full-site report to: `grimoires/beacon/audits/{app}-full-audit.md`

Use the template from `resources/templates/full-audit-report.md`.

### Phase 6: Update State

Update `grimoires/beacon/state.yaml`:
```yaml
audits:
  count: {increment}
  last_audit: "{timestamp}"
  pages:
    {path}:
      score: {overall_score}
      risk: {high|medium|low}
      audited: "{timestamp}"
```

## Output Format

See `resources/templates/audit-report.md` for the full template.

Key sections:
1. **Summary** - Overall score, risk level, timestamp
2. **Trust Layer Analysis** - Score and findings for each layer
3. **High-Risk Claims** - Table of specific issues
4. **Recommendations** - Priority-ordered fixes
5. **Next Steps** - Links to `/optimize-chunks` and `/add-markdown`

## Examples

### Example 1: Marketing Page (Low Score)

```
/audit-llm /pricing
```

Typical findings:
- "Enterprise-grade security" (no evidence link)
- "99.9% uptime" (no date range)
- "We don't store your data" (no scope on what data)

Expected score: 3-5/10

### Example 2: Documentation Page (High Score)

```
/audit-llm docs/api-reference.md
```

Typical findings:
- Clear API versioning with dates
- Code examples with specific versions
- Links to changelog

Expected score: 7-9/10

## Edge Cases

### File Not Found
If the target path doesn't exist:
1. Report "Content not found at {path}"
2. Suggest checking the path or trying alternative locations

### Non-Text Content
If the page is primarily images/video:
1. Note "Limited text content available for audit"
2. Score based on available text
3. Recommend adding text alternatives

### Dynamic Content
If content is fetched client-side:
1. Note "Dynamic content detected - audit may be incomplete"
2. Recommend providing static content or API response samples

## Dual-Nature Contract

### As an agent executing this skill:
- **Input**: Page path or `--all` flag
- **Phases**: 1 → 1.5 → 1.75 → 2 → 3 → 4 → 4.5 → 5 → 5.5 (if --all) → 6
- **Decisions**: If `--all`, run pages in parallel. If single page, run sequentially.
- **Escalation**: If score < 4.0, recommend immediate `/optimize-chunks` follow-up.
- **Output**: Audit report in `grimoires/beacon/audits/`

### As output consumed by other agents:
- **Format**: Markdown with structured tables and severity tags
- **Machine-readable fields**: Overall score, per-layer scores, severity counts, file:line references
- **Cross-references**: Each finding links to file path and line number for automated fixing
- **Temporal markers**: Audit timestamp, "as of" dates on all time-sensitive findings
