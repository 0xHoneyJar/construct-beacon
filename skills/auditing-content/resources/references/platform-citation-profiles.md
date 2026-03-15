# Platform Citation Profiles

> How major AI platforms cite and attribute content.
>
> Use these profiles to calibrate audit expectations per platform. A page scoring well on one platform's citation model may score poorly on another.

**Last Updated:** 2026-03-14

---

## Citation Density by Platform

| Platform | Avg Citations/Answer | Citation Style | Source Preference |
|----------|---------------------|----------------|-------------------|
| Perplexity | ~22 | Inline numbered references | Authoritative domains, recent content, structured data |
| ChatGPT (Browse) | ~8 | Inline links with title | Training data + live search, prefers canonical pages |
| Google AI Overviews | 3-5 | Collapsed source cards | Google index, schema.org markup, E-E-A-T signals |
| Bing Copilot | ~10 | Footnoted references | Bing index, structured data, page freshness |

**Source:** Qwairy Q3 2025 AI citation study; Ahrefs Nov 2025 analysis. **Confidence: MEDIUM** — citation counts shift with model updates.

---

## Platform Behaviors

### Perplexity

- **Highest citation density** — routinely cites 15-30 sources per answer
- **Follows robots.txt** — respects `PerplexityBot` directives
- **Prefers structured content** — lists, tables, and headed sections get cited more frequently than prose
- **Recency bias** — recent content weighted heavily; include `dateModified` in schema.org
- **Implication for Beacon:** High-citability paragraphs (self-contained, dated, sourced) have the best chance of being cited here

### ChatGPT (Browse Mode)

- **Moderate citation density** — typically 5-12 sources per answer
- **Training data + live search hybrid** — may cite from parametric knowledge without linking
- **Canonical page preference** — prefers `/about`, `/pricing`, `/docs` over deep pages
- **robots.txt:** Respects `GPTBot` and `OAI-SearchBot` directives
- **Implication for Beacon:** Source Legitimacy (Layer 1) matters most here — clear brand attribution increases citation probability

### Google AI Overviews

- **Low citation density** — 3-5 collapsed source cards
- **Schema.org dependent** — JSON-LD markup directly influences inclusion
- **Does NOT respect robots.txt for AI Overviews** — blocking crawlers does not prevent inclusion in AI-generated summaries (content may be sourced from Google's existing index)
- **E-E-A-T signals** — Experience, Expertise, Authoritativeness, Trustworthiness drive selection
- **Implication for Beacon:** Structural Cues (Layer 5) and claim verifiability (Layer 2) are the primary drivers

### Bing Copilot

- **Moderate citation density** — typically 8-12 sources
- **Bing index dependent** — if not indexed by Bing, won't be cited
- **Structured data bonus** — FAQ schema, HowTo schema increase citation probability
- **Temporal signals** — `datePublished` and `dateModified` influence freshness ranking
- **Implication for Beacon:** Cross-source consistency (Layer 3) matters — contradicting information across pages reduces citation likelihood

---

## Citation Factors Matrix

| Factor | Perplexity | ChatGPT | Google AIO | Bing Copilot |
|--------|-----------|---------|------------|--------------|
| Schema.org markup | HIGH | MEDIUM | CRITICAL | HIGH |
| Page freshness | HIGH | MEDIUM | MEDIUM | HIGH |
| Brand mentions (off-site) | MEDIUM | LOW | HIGH | MEDIUM |
| Self-contained paragraphs | HIGH | MEDIUM | MEDIUM | MEDIUM |
| Temporal markers | HIGH | LOW | MEDIUM | HIGH |
| Backlinks | LOW | LOW | HIGH | MEDIUM |
| robots.txt compliance | YES | YES | NO (for AIO) | YES |

---

## How to Use in Audits

When running `/audit-llm`, reference these profiles to contextualize scores:

1. **Multi-platform citability is the goal** — optimize for the common denominator (structured data, temporal markers, self-contained paragraphs)
2. **Platform-specific warnings** — flag when content relies on factors that only work on one platform
3. **robots.txt contradictions** — if x402 endpoints are enabled but AI crawlers are blocked, flag this as HIGH severity (Task 3: crawler reachability check)

---

## Limitations

- Citation behaviors change with model updates — these profiles are point-in-time observations
- Citation count alone doesn't indicate quality of attribution
- Source code auditing can only influence a subset of AI citation factors — off-site signals (backlinks, brand mentions, YouTube presence) are outside Beacon's scope
