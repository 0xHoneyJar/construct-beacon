#!/bin/bash
#
# validate.sh - Validate Beacon construct integrity
#
# Usage:
#   ./validate.sh [PROJECT_ROOT]
#
# Validates:
#   1. construct.yaml is valid YAML with required fields
#   2. All index.yaml files parse correctly and have version 2.0.0
#   3. JSON Schema files are valid JSON
#   4. state.yaml (if exists) matches expected structure
#   5. Report templates contain required sections
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="${1:-.}"

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN + 1)); }

echo "╭───────────────────────────────────────────────────────╮"
echo "│  BEACON VALIDATOR                                      │"
echo "╰───────────────────────────────────────────────────────╯"
echo ""

# --- 1. construct.yaml ---
echo "Checking construct.yaml..."
if python3 -c "import yaml; d=yaml.safe_load(open('$PACK_DIR/construct.yaml')); assert d.get('version')=='2.0.0'; assert d.get('schema_version')==3" 2>/dev/null; then
    pass "construct.yaml: valid YAML, version 2.0.0, schema_version 3"
else
    fail "construct.yaml: invalid or missing required fields"
fi

# Check events count
EVENT_COUNT=$(python3 -c "import yaml; d=yaml.safe_load(open('$PACK_DIR/construct.yaml')); print(len(d.get('events',{}).get('emits',[])))" 2>/dev/null || echo "0")
if [ "$EVENT_COUNT" -eq 6 ]; then
    pass "construct.yaml: 6 events declared"
else
    fail "construct.yaml: expected 6 events, found $EVENT_COUNT"
fi

echo ""

# --- 2. index.yaml files ---
echo "Checking skill index.yaml files..."
for f in "$PACK_DIR"/skills/*/index.yaml; do
    SKILL=$(basename "$(dirname "$f")")
    if python3 -c "import yaml; d=yaml.safe_load(open('$f')); assert d.get('version')=='2.0.0'" 2>/dev/null; then
        pass "$SKILL/index.yaml: valid YAML, version 2.0.0"
    else
        fail "$SKILL/index.yaml: invalid or wrong version"
    fi
done

echo ""

# --- 3. JSON Schema files ---
echo "Checking JSON schemas..."
for f in "$PACK_DIR"/contexts/schemas/*.json "$PACK_DIR"/schemas/state.schema.json; do
    BASENAME=$(basename "$f")
    if [ -f "$f" ] && python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
        pass "$BASENAME: valid JSON"
    elif [ ! -f "$f" ]; then
        fail "$BASENAME: file not found"
    else
        fail "$BASENAME: invalid JSON"
    fi
done

for f in "$PACK_DIR"/contexts/overlays/*.example; do
    BASENAME=$(basename "$f")
    if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
        pass "$BASENAME: valid JSON"
    else
        fail "$BASENAME: invalid JSON"
    fi
done

echo ""

# --- 4. state.yaml validation (if project has one) ---
echo "Checking state.yaml structure..."
STATE_FILE="$PROJECT_ROOT/grimoires/beacon/state.yaml"
if [ -f "$STATE_FILE" ]; then
    REQUIRED_KEYS="schema_version construct_version audits exports optimizations discovery actions payments"
    MISSING=""
    for key in $REQUIRED_KEYS; do
        if ! python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); assert '$key' in d" 2>/dev/null; then
            MISSING="$MISSING $key"
        fi
    done
    if [ -z "$MISSING" ]; then
        pass "state.yaml: all required sections present"
    else
        fail "state.yaml: missing sections:$MISSING"
    fi
else
    warn "state.yaml: not found at $STATE_FILE (run install.sh first)"
fi

echo ""

# --- 5. SKILL.md Dual-Nature Contract ---
echo "Checking Dual-Nature Contract in SKILL.md files..."
for f in "$PACK_DIR"/skills/*/SKILL.md; do
    SKILL=$(basename "$(dirname "$f")")
    if grep -q "Dual-Nature Contract" "$f" 2>/dev/null; then
        pass "$SKILL/SKILL.md: Dual-Nature Contract present"
    else
        fail "$SKILL/SKILL.md: missing Dual-Nature Contract"
    fi
done

echo ""

# --- 6. Report templates ---
echo "Checking report templates..."
TEMPLATE_DIR="$PACK_DIR/skills/auditing-content/resources/templates"
if [ -f "$TEMPLATE_DIR/full-audit-report.md" ]; then
    pass "full-audit-report.md: exists"
else
    fail "full-audit-report.md: missing"
fi

if [ -f "$TEMPLATE_DIR/api-assessment.md" ]; then
    pass "api-assessment.md: exists"
else
    fail "api-assessment.md: missing"
fi

echo ""

# --- Summary ---
echo "╭───────────────────────────────────────────────────────╮"
echo "│  RESULTS                                               │"
echo "╰───────────────────────────────────────────────────────╯"
echo ""
echo "  Passed:   $PASS"
echo "  Failed:   $FAIL"
echo "  Warnings: $WARN"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "VALIDATION FAILED"
    exit 1
else
    echo "VALIDATION PASSED"
    exit 0
fi
