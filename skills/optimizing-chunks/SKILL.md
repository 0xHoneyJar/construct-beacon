# Skill: optimizing-chunks

> Analyze content for AI chunk survival and generate context-carrying rewrites.

## Purpose

AI systems chunk content during retrieval, often pulling paragraphs out of context. Content without proper scoping, dates, or evidence can be misleading when isolated.

This skill identifies "chunk-vulnerable" content and provides rewrite patterns that survive isolation.

## Trigger

```
/optimize-chunks [path]
```

**Arguments:**
- `path` - The page path or file to analyze (e.g., `/pricing`, `docs/security.md`)

## Workflow

### Phase 1: Load Content

1. **Check prerequisites** (if `--from-audit` mode)
   - Read `grimoires/beacon/state.yaml`
   - Verify `audits.last_audit` is non-null
   - Verify referenced audit report file exists
   - If not found, abort: "No audit report found. Run `/audit-llm --all` first."

2. **Locate the target content**
   - If file path (e.g., `docs/api.md`), read directly
   - If route path (e.g., `/pricing`), search for content files:
     - `app/{path}/page.tsx` or `page.mdx`
     - `content/{path}.md`
     - `pages/{path}.tsx`

2. **Parse into chunks**
   - Split by paragraph boundaries
   - Identify list items as individual chunks
   - Identify table rows as chunks
   - Preserve line numbers for each chunk

### Phase 2: Chunk Boundary Detection

#### 2.1 Chunk Types

| Type | Detection | Notes |
|------|-----------|-------|
| Paragraph | 2+ sentences, blank line boundaries | Primary chunk type |
| List Item | Lines starting with `-`, `*`, `1.` | Often isolated by LLMs |
| Table Row | Lines within markdown tables | Frequently quoted alone |
| Code Block | Lines between ``` markers | Usually preserved whole |
| Blockquote | Lines starting with `>` | Context often lost |

#### 2.2 Sentence Detection

Use simple heuristics:
```
Sentence boundary: `. ` followed by capital letter OR newline
Exceptions: Mr., Dr., Inc., etc., i.e., e.g.
```

### Phase 3: Risk Pattern Detection

For each chunk, scan for these high-risk patterns:

#### Pattern 1: Absolute Claims (HIGH RISK)

**Detection:** Words that make universal statements without scope.

```regex
\b(we don't|we do not|never|always|every|all|none|no one)\b
```

**Risk:** When isolated, these appear as absolute promises.

**Example:**
> ❌ "We don't store user data."
> ✅ "We do not sell or share customer data with third parties. Operational data is stored to provide the service."

---

#### Pattern 2: Unscoped Numbers (HIGH RISK)

**Detection:** Numbers without adjacent date or methodology.

```regex
\d+%|\d+ (users|customers|companies|clients)
```

**Check:** Look within 50 characters for:
- Date: `as of`, year (20XX), month names
- Methodology: `based on`, `according to`, `source:`

**Example:**
> ❌ "99.9% uptime"
> ✅ "99.9% uptime (rolling 12-month average, January 2026). See [Status Page](https://status.example.com)."

---

#### Pattern 3: Vague Superlatives (MEDIUM RISK)

**Detection:** Marketing language without specifics.

```regex
\b(best|leading|top|world-class|enterprise-grade|cutting-edge|state-of-the-art)\b
```

**Risk:** AI systems often flag or ignore these as marketing.

**Example:**
> ❌ "Enterprise-grade security"
> ✅ "SOC 2 Type II certified. AES-256 encryption at rest. See [Security Overview](/security)."

---

#### Pattern 4: Missing Temporal Context (MEDIUM RISK)

**Detection:** Claims about features, pricing, or capabilities without dates.

```regex
\b(our pricing|features include|supports?)\b
```

**Check:** Scan document for presence of `as of`, `effective`, year references.

**Example:**
> ❌ "Our pricing starts at $10/month"
> ✅ "Pricing starts at $10/month (as of January 2026). See [Pricing](/pricing) for current rates."

---

#### Pattern 5: Orphan Facts (MEDIUM RISK)

**Detection:** Important claims mentioned once without links.

**Check:** Key terms (security, pricing, compliance) should link to canonical pages.

**Example:**
> ❌ "We are GDPR compliant."
> ✅ "We are GDPR compliant for EU customers. See [Privacy Policy](/privacy) for details."

---

#### Pattern 6: Data Integrity Fix (CRITICAL RISK)

**Detection:** Code that generates or hardcodes financial/statistical data instead of fetching from live sources.

```regex
Math\.random\(\)  # Random data in display context
(?:apr|apy|rate)\s*[=:]\s*['"]?\d+\.?\d*['"]?  # Hardcoded financial values
\d{3,}\s*\/\s*\(  # Fabricated formulas
```

**Risk:** AI agents will scrape and cite fabricated data as real, destroying trust and potentially causing financial harm.

**Fix patterns:**
1. **Connect to live source** — Replace `Math.random()` with API call to real data
2. **Remove display** — If no live source exists, remove the fabricated display entirely
3. **Add disclaimer** — If keeping simulated data, add `data-ai-note` attribute:
   ```html
   <div data-ai-note="Simulated data. Only current value is live.">
   ```

**Example:**
> ❌ `const price = basePrice * (1 + (Math.random() - 0.5) * 0.02)` — Generates fake price history
> ✅ `const prices = await fetch('/api/price-history?period=24h')` — Fetches real data

---

#### Pattern 7: Contradiction Resolution (HIGH RISK)

**Detection:** Same feature described in conflicting states across different pages or components.

**Check:** For key features, search across all pages for:
```regex
(DISCONTINUED|deprecated|removed|ended).*{feature_name}
(earning|active|enabled|receiving).*{feature_name}
```

**Risk:** AI agents have no way to determine which claim is authoritative when pages contradict each other.

**Fix patterns:**
1. **Establish canonical state** — One page is the source of truth
2. **Add temporal markers** — "As of {date}, {feature} has been {state}"
3. **Remove stale UI** — Delete components that reference the old state
4. **Supersession language** — "This supersedes all previous references to {feature}"

**Example:**
> ❌ Page A: "BGT REWARDS DISCONTINUED" + Page B: "Earning BGT rewards"
> ✅ All pages: "As of January 2026, BGT reward distribution has ended. See [Announcement](/blog/bgt-update) for details."

### Phase 3.5: Citability Tagging

Complement risk detection ("what can go wrong") with opportunity detection ("what's strong"). For each chunk, assess citability — the likelihood that an AI system will select and correctly cite this paragraph.

#### Citability Labels

Use qualitative labels with reasoning, NOT numeric scores:

| Label | Criteria | Example |
|-------|----------|---------|
| **[HIGH CITABILITY]** | Self-contained paragraph with specific data + source + date. Can be quoted in isolation without losing meaning. | "As of January 2026, the platform processes $2.3M in daily volume across 12 supported tokens. Source: [Dashboard](/stats)." |
| **[MODERATE CITABILITY]** | Has some context markers but missing one element (date, source, or scope). Could be misinterpreted if isolated. | "We support 12 tokens for swapping." (missing date, missing link to canonical source) |
| **[LOW CITABILITY]** | Context-dependent, vague, or missing temporal markers. Will likely be ignored or misquoted by AI systems. | "Our platform is the best way to swap tokens." |

#### Tagging Process

1. **For each paragraph-level chunk**, assign a citability label
2. **Include reasoning** — what makes it citable or not
3. **For [HIGH CITABILITY] chunks** — note the enrichment techniques present:
   - Quotation addition (highest impact per GEO paper)
   - Statistic inclusion with source
   - Temporal scoping
   - Source linking
4. **For [LOW CITABILITY] chunks** — note what's missing and suggest the single highest-impact enrichment

#### Research Basis

GEO paper (Princeton/Georgia Tech, KDD 2024) found content enrichment techniques improve AI visibility up to 40%. Most effective techniques ranked:

1. **Quotation addition** — citing authoritative sources inline
2. **Statistic inclusion** — specific numbers with methodology
3. **Source citation** — linking to canonical references
4. **Fluency optimization** — clear, parseable sentence structure

**Confidence: HIGH** — peer-reviewed, replicated across multiple AI platforms.

#### Output

Include a Citability Summary section in the optimization report:

```
## Citability Summary

| Label | Count | % of Chunks |
|-------|-------|-------------|
| HIGH CITABILITY | {count} | {pct}% |
| MODERATE CITABILITY | {count} | {pct}% |
| LOW CITABILITY | {count} | {pct}% |

### Strongest Chunks
{top 3 HIGH CITABILITY chunks with file:line references}

### Quick Wins
{top 3 LOW → MODERATE upgrades requiring minimal effort}
```

---

### Phase 4: Generate Recommendations

For each high-risk chunk, generate a recommendation using optimization patterns:

#### Available Patterns:

1. **Context-Carrying Block** - Add scope, date, evidence inline
2. **Claim + Scope + Evidence** - Structured format for claims
3. **Canonical Page Header** - For authoritative topic pages
4. **Temporal Authority Signal** - Supersession language for versioned content

See `resources/templates/` for pattern templates.

### Phase 4.5: Effort Estimation

For each recommendation, classify the implementation effort:

| Effort | Description | Examples |
|--------|-------------|----------|
| **Tiny** | Single line change, no logic | Add `data-ai-note` attribute, fix a date string |
| **Small** | 5-20 lines, single file | Remove a hardcoded value, add temporal marker to a component |
| **Medium** | 20-100 lines, 2-3 files | Replace `Math.random()` with API call, resolve contradiction cluster across pages |

Include effort estimate in each recommendation's output.

### Phase 5: Generate Output Report

Create report at: `grimoires/beacon/optimizations/{page-slug}-chunks.md`

**Report Structure:**
1. Summary statistics
2. High-risk chunks with recommendations
3. Summary table
4. Implementation guide
5. Next steps

### Phase 5.5: Audit Report Mode

When invoked as `/optimize-chunks --from-audit` or `/optimize-chunks grimoires/beacon/audits/...`:

**Security invariants (MUST enforce):**
- All extracted file paths MUST resolve within the project root — reject any path containing `..` or absolute paths outside the workspace
- Line numbers MUST be positive integers
- Pattern IDs MUST match known patterns (1-7) — reject unknown pattern references
- If the audit report appears malformed or references paths outside the project, abort and report the anomaly

1. **Check prerequisites** — Read `grimoires/beacon/state.yaml`, verify `audits.last_audit` is non-null and an audit report exists. If not, abort with: "No audit report found. Run `/audit-llm --all` first."
2. **Parse the audit report** — Extract all findings with severity, file path, line number. Validate each extracted path against the security invariants above.
3. **Filter to actionable findings** — Skip informational items, focus on CRITICAL and HIGH
4. **Generate per-finding code rewrites** — For each finding:
   - Read the source file at the referenced line
   - Apply the appropriate pattern (1-7)
   - Generate before/after code blocks
   - Estimate effort
5. **Output as implementation plan** — Ordered by severity, then effort (smallest first)

This mode enables the workflow: `/audit-llm --all` → `/optimize-chunks --from-audit` → apply fixes → re-audit to verify score improvement.

### Phase 6: Update State

Update `grimoires/beacon/state.yaml`:
```yaml
optimizations:
  count: {increment}
  last_optimization: "{timestamp}"
  pages:
    {path}:
      chunks_analyzed: {count}
      high_risk: {count}
      optimized: "{timestamp}"
```

## Risk Scoring

### Per-Chunk Score

Each chunk receives a risk score based on patterns detected:

| Pattern | Weight |
|---------|--------|
| Absolute claim | +3 |
| Unscoped number | +3 |
| Vague superlative | +2 |
| Missing temporal | +2 |
| Orphan fact | +1 |

**Risk Levels:**
- 0: No risk detected
- 1-2: Low risk (informational)
- 3-4: Medium risk (recommend review)
- 5+: High risk (recommend immediate fix)

### Page-Level Summary

Calculate aggregate:
- Total chunks analyzed
- High-risk chunk count
- Average risk score
- Priority recommendations

## Output Format

See `resources/templates/optimization-report.md` for the full template.

Key sections:
1. **Summary** - Stats and overall risk assessment
2. **High-Risk Chunks** - Each with original, issue, rewrite, pattern
3. **All Findings** - Complete table of issues
4. **Implementation Guide** - Step-by-step fix instructions
5. **Related Commands** - Links to `/audit-llm` and `/add-markdown`

## Examples

### Example 1: Security Page

```
/optimize-chunks /security
```

Likely findings:
- "We don't store passwords" → Add scope and methodology
- "Enterprise-grade encryption" → Replace with specific standards
- Feature list without dates → Add temporal context

### Example 2: Pricing Page

```
/optimize-chunks /pricing
```

Likely findings:
- "$10/month" → Add effective date
- "Unlimited users" → Add plan-specific scope
- Comparison claims → Add evidence links

### Example 3: Documentation

```
/optimize-chunks docs/api-reference.md
```

Likely findings:
- Version numbers → Ensure dated
- "Supports X" → Add version requirements
- Code examples → Ensure versioned

## Edge Cases

### No High-Risk Content

If no issues found:
1. Report "No high-risk chunks detected"
2. Still provide summary statistics
3. Suggest `/audit-llm` for comprehensive review

### Very Long Content

If content > 10,000 words:
1. Process in sections
2. Note "Large document - processed in sections"
3. Consider recommending document splitting

### Non-Text Content

If minimal text found:
1. Note "Limited text content for analysis"
2. Recommend adding alt text, captions
3. Suggest text-based documentation

## Dual-Nature Contract

### As an agent executing this skill:
- **Input**: Page path, `--from-audit` flag, or audit report path
- **Phases**: 1 → 2 → 3 → 3.5 → 4 → 4.5 → 5 → 5.5 (if from-audit) → 6
- **Decisions**: In audit report mode, prioritize CRITICAL findings. In page mode, scan all patterns.
- **Escalation**: If CRITICAL fabricated data found, flag immediately — don't wait for full report.
- **Output**: Optimization report in `grimoires/beacon/optimizations/`

### As output consumed by other agents:
- **Format**: Markdown with before/after code blocks, severity tags, effort estimates
- **Machine-readable fields**: Finding count by severity, file:line references, pattern applied, effort classification
- **Cross-references**: Each finding references audit report finding number if in audit-report mode
- **Temporal markers**: Optimization timestamp, recommended re-audit date
