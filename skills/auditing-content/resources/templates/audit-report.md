# LLM Readiness Audit: {path}

**Overall Score:** {overall_score}/10
**Retrieval Risk:** {risk_level}
**Audited:** {timestamp}

---

## Summary

{summary_paragraph}

---

## Trust Layer Analysis

### 1. Source Legitimacy ({layer1_score}/10) — 20% weight

{layer1_findings}

**Checklist:**
- [{brand_check}] Brand name defined clearly
- [{entity_check}] Entity context present
- [{naming_check}] Consistent naming throughout
- [{about_check}] About/company link present

---

### 2. Claim Verifiability ({layer2_score}/10) — 25% weight

{layer2_findings}

**Checklist:**
- [{evidence_check}] Evidence adjacency for claims
- [{numbers_check}] Specific numbers with methodology
- [{falsifiable_check}] Falsifiable statements
- [{superlatives_check}] No orphan superlatives

---

### 3. Cross-Source Consistency ({layer3_score}/10) — 20% weight

{layer3_findings}

**Checklist:**
- [{internal_check}] Internal consistency verified
- [{outdated_check}] No outdated conflicting content
- [{temporal_check}] Temporal coherence
- [{canonical_check}] Canonical signals present

---

### 4. Contextual Integrity ({layer4_score}/10) — 25% weight

{layer4_findings}

**Checklist:**
- [{scope_check}] Claims have scope (who/what/where)
- [{temporal_marker_check}] Temporal markers present
- [{exception_check}] Exception clarity
- [{standalone_check}] Self-contained paragraphs

---

### 5. Structural Cues ({layer5_score}/10) — 10% weight

{layer5_findings}

**Checklist:**
- [{headers_check}] Descriptive headers
- [{structured_check}] Structured data (lists/tables)
- [{code_check}] Code blocks for technical content
- [{marketing_check}] Low marketing ratio (<10%)

---

## High-Risk Claims

| Line | Claim | Issue | Recommendation |
|------|-------|-------|----------------|
{high_risk_claims_table}

---

## Recommendations (Priority Order)

{recommendations_list}

---

## Score Calculation

```
Layer 1 (Source Legitimacy):     {layer1_score} × 0.20 = {layer1_weighted}
Layer 2 (Claim Verifiability):   {layer2_score} × 0.25 = {layer2_weighted}
Layer 3 (Cross-Source):          {layer3_score} × 0.20 = {layer3_weighted}
Layer 4 (Contextual Integrity):  {layer4_score} × 0.25 = {layer4_weighted}
Layer 5 (Structural Cues):       {layer5_score} × 0.10 = {layer5_weighted}
─────────────────────────────────────────────────────────
Overall Score:                                    {overall_score}/10
```

---

## Beyond Your Codebase

Source code auditing can only influence a subset of AI citation factors. These off-site signals also affect how AI platforms cite your content:

| Signal | Correlation with AI Citation | Action |
|--------|------------------------------|--------|
| Brand mentions (YouTube, Reddit, Wikipedia) | 0.66 (Ahrefs Nov 2025) | Build brand presence on platforms AI models reference |
| Backlinks from authoritative domains | 0.218 (Ahrefs Nov 2025) | Less impactful than brand mentions for AI, but still relevant for Google AIO |
| `sameAs` in Schema.org | N/A (structural signal) | Link your site to official social/Wikipedia profiles via JSON-LD `sameAs` property |

> **Note:** Brand mentions correlate 3x more strongly with AI citation than traditional backlinks. This inverts the SEO assumption that link-building is the primary off-site lever.
>
> See `resources/references/platform-citation-profiles.md` for per-platform citation behaviors.

---

## Next Steps

1. **Fix high-risk claims**: Run `/optimize-chunks {path}` to get rewrite recommendations
2. **Add markdown export**: Run `/add-markdown {path}` to enable AI-friendly retrieval
3. **Re-audit after fixes**: Run `/audit-llm {path}` again to verify improvements

---

## Risk Level Reference

| Score | Risk | Meaning |
|-------|------|---------|
| 0-4 | **High** | Content likely to be misrepresented by AI |
| 4-7 | **Medium** | Some claims vulnerable to misquoting |
| 7-10 | **Low** | Content optimized for AI retrieval |
