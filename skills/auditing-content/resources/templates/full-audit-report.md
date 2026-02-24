# {{APP_NAME}} — LLM Readiness Audit (Full)

**Auditor**: Beacon Auditor Agent
**Date**: {{TIMESTAMP}}
**Scope**: {{SCOPE_DESCRIPTION}}
**Framework**: 5-Layer Trust Model for AI Content Consumption
**Sub-audits synthesized**: {{SUB_AUDIT_COUNT}}

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| **Overall Agent Readiness Score** | **{{OVERALL_SCORE}} / 10** |
| **Risk Level** | **{{RISK_LEVEL}}** |
| **Pages Audited** | {{PAGES_COUNT}} |
| **Components Deep-Audited** | {{COMPONENTS_COUNT}} |
| **API Routes Audited** | {{API_ROUTES_COUNT}} |
| **High-Risk Claims Found** | {{HIGH_RISK_COUNT}} |
| **Critical Fabricated Data** | {{CRITICAL_FABRICATED_COUNT}} |
| **Critical Gaps** | {{CRITICAL_GAPS}} |

### Key Findings

{{KEY_FINDINGS_LIST}}

---

## 2. Per-Page Analysis

{{PER_PAGE_SECTIONS}}

---

## 3. API Route Assessment

| # | Path | Method | Auth | Rate Limit | Cache | Agent Utility | Risk |
|---|------|--------|------|------------|-------|---------------|------|
{{API_ROUTE_TABLE}}

---

## 4. Contradiction Clusters

{{CONTRADICTION_CLUSTERS}}

---

## 5. Score Progression

| State | Score | Description |
|-------|-------|-------------|
| Current | {{CURRENT_SCORE}}/10 | As-is assessment |
| Post-P0 | {{POST_P0_SCORE}}/10 | After fixing CRITICAL findings |
| Post-P1 | {{POST_P1_SCORE}}/10 | After fixing HIGH findings |
| Post-P2 | {{POST_P2_SCORE}}/10 | After fixing MEDIUM findings |
| AI-Ready | 7.0+/10 | Threshold for reliable agent consumption |

---

## 6. Recommendations by Priority

### P0 — CRITICAL (Fix immediately)
{{P0_RECOMMENDATIONS}}

### P1 — HIGH (Fix this sprint)
{{P1_RECOMMENDATIONS}}

### P2 — MEDIUM (Fix next sprint)
{{P2_RECOMMENDATIONS}}

### P3 — LOW (Backlog)
{{P3_RECOMMENDATIONS}}

---

## 7. Next Steps

1. Run `/optimize-chunks --from-audit` to generate code rewrites for P0 findings
2. Apply P0 fixes and re-audit to verify score improvement
3. Run `/add-markdown llms.txt` to generate machine-readable site description
4. Run `/beacon-discover` to set up agent discovery endpoint
