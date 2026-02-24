# API Route Assessment — {{APP_NAME}}

**Generated**: {{TIMESTAMP}}
**Base URL**: {{BASE_URL}}
**Total Endpoints**: {{ENDPOINT_COUNT}}

## Endpoint Inventory

| # | Path | Method | Auth | Rate Limit | Cache | Description |
|---|------|--------|------|------------|-------|-------------|
{{ENDPOINT_TABLE}}

## Security Assessment

### Authentication Coverage
- Authenticated endpoints: {{AUTH_COUNT}} / {{ENDPOINT_COUNT}}
- Open endpoints: {{OPEN_COUNT}} / {{ENDPOINT_COUNT}}

### Rate Limiting Coverage
- Rate-limited endpoints: {{RATELIMIT_COUNT}} / {{ENDPOINT_COUNT}}
- Unprotected endpoints: {{UNPROTECTED_COUNT}} / {{ENDPOINT_COUNT}}

### High-Risk Endpoints
{{HIGH_RISK_ENDPOINTS}}

## Agent Utility Classification

| Tier | Description | Endpoints |
|------|-------------|-----------|
| **Tier 1** | Direct agent value (data retrieval, actions) | {{TIER1_ENDPOINTS}} |
| **Tier 2** | Supporting infrastructure (auth, analytics) | {{TIER2_ENDPOINTS}} |
| **Tier 3** | Internal/admin only | {{TIER3_ENDPOINTS}} |

## x402 Payment Candidates

Endpoints suitable for x402 monetization:
{{PAYMENT_CANDIDATES}}
