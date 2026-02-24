#!/bin/bash
#
# install.sh - Install Beacon pack for a project
#
# Usage:
#   ./install.sh [PROJECT_ROOT]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

PROJECT_ROOT="${1:-.}"

echo "╭───────────────────────────────────────────────────────╮"
echo "│  SIGIL OF THE BEACON - INSTALLER                      │"
echo "╰───────────────────────────────────────────────────────╯"
echo ""

# Create grimoire structure
GRIMOIRE_DIR="$PROJECT_ROOT/grimoires/beacon"
mkdir -p "$GRIMOIRE_DIR/audits"
mkdir -p "$GRIMOIRE_DIR/exports"
mkdir -p "$GRIMOIRE_DIR/optimizations"
mkdir -p "$GRIMOIRE_DIR/discovery"
mkdir -p "$GRIMOIRE_DIR/sync"

echo "✓ Created grimoire structure at $GRIMOIRE_DIR"

# Initialize state.yaml if not exists
STATE_FILE="$GRIMOIRE_DIR/state.yaml"
if [ ! -f "$STATE_FILE" ]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$STATE_FILE" << YAML
# Beacon State
# Tracks audits, exports, and optimizations

version: "1.0.0"
initialized: "$TIMESTAMP"
last_activity: null

audits:
  count: 0
  last_audit: null
  pages: {}

exports:
  count: 0
  last_generation: null
  pages: {}

optimizations:
  count: 0
  last_optimization: null
  pages: {}

discovery:
  count: 0
  last_generation: null

actions:
  schemas_generated: 0
  last_generation: null

payments:
  middleware_generated: false
  last_generation: null

layer_scores:
  source_legitimacy: null
  claim_verifiability: null
  cross_source_consistency: null
  contextual_integrity: null
  structural_cues: null

critical_findings: []

artifacts:
  llms_txt:
    status: pending
  api_schemas:
    status: pending
  content_chunks:
    status: pending

recommendations:
  p0_count: 0
  p1_count: 0
  p2_count: 0
  estimated_score_after_p0: null
  ai_ready_threshold: 7.0
YAML
    echo "✓ Initialized state.yaml"
else
    echo "✓ Preserved existing state.yaml"
fi

echo ""
echo "╭───────────────────────────────────────────────────────╮"
echo "│  INSTALLATION COMPLETE                                │"
echo "╰───────────────────────────────────────────────────────╯"
echo ""
echo "Available commands:"
echo "  /audit-llm [path]           - Audit page for LLM trust signals"
echo "  /audit-llm --all            - Full-site audit (all pages + API routes)"
echo "  /add-markdown [path]        - Add markdown export capability"
echo "  /add-markdown llms.txt      - Generate machine-readable site description"
echo "  /optimize-chunks [path]     - Optimize content for AI retrieval"
echo "  /beacon-discover            - Generate x402 discovery endpoint"
echo "  /beacon-actions             - Generate JSON Schema + OpenAPI specs"
echo "  /beacon-pay                 - Add x402 payment middleware"
echo ""
echo "Quick start:"
echo "  1. /audit-llm --all            # Full-site audit"
echo "  2. /optimize-chunks --from-audit # Fix audit findings"
echo "  3. /add-markdown llms.txt       # Machine-readable site description"
echo "  4. /beacon-discover             # x402 discovery endpoint"
echo "  5. /beacon-actions              # API schemas"
echo "  6. /beacon-pay                  # Payment middleware"
echo ""
echo "Grimoire location: $GRIMOIRE_DIR"
echo ""
