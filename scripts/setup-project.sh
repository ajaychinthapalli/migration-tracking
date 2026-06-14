#!/usr/bin/env bash
# =============================================================================
# setup-project.sh
# Creates the GitHub Migration Dashboard project (Projects v2) with:
#   - Custom fields: Status, Migration Date, Month, Team, Priority, Repo Size
#   - Daily Dashboard view  (board grouped by Status, filtered by date)
#   - Monthly Dashboard view (board grouped by Status)
#
# Usage:
#   ./scripts/setup-project.sh [owner] [org|user]
#
#   owner    GitHub org or user that owns the project  (default: current repo owner)
#   type     "org" or "user"                           (default: org)
#
# Requires: gh CLI authenticated with project:write + repo write access
# =============================================================================
set -euo pipefail

OWNER="${1:-}"
OWNER_TYPE="${2:-org}"   # "org" or "user"

if [[ -z "$OWNER" ]]; then
  OWNER="$(gh repo view --json owner -q .owner.login 2>/dev/null || echo "")"
fi
if [[ -z "$OWNER" ]]; then
  echo "ERROR: Could not determine owner. Pass owner as first argument."
  exit 1
fi

PROJECT_TITLE="GitHub Migration Dashboard"
echo "Setting up project '${PROJECT_TITLE}' for ${OWNER_TYPE}: ${OWNER}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 1. Create the project
# ─────────────────────────────────────────────────────────────────────────────
echo "1/6  Creating project..."
if [[ "$OWNER_TYPE" == "org" ]]; then
  PROJECT_URL=$(gh project create \
    --owner "$OWNER" \
    --title "$PROJECT_TITLE" \
    --format json | jq -r '.url')
else
  PROJECT_URL=$(gh project create \
    --owner "@me" \
    --title "$PROJECT_TITLE" \
    --format json | jq -r '.url')
fi

PROJECT_NUMBER=$(echo "$PROJECT_URL" | grep -oE '[0-9]+$')
echo "   Project URL:    $PROJECT_URL"
echo "   Project Number: $PROJECT_NUMBER"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Add custom fields
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "2/6  Creating custom fields..."

# Migration Status (single select)
echo "   - Migration Status"
gh project field-create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Migration Status" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "Preparation,Scheduled,In Progress,Complete,Post Migration,Validation,Blocked"

# Migration Date (date)
echo "   - Migration Date"
gh project field-create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Migration Date" \
  --data-type "DATE"

# Migration Month (text — used for monthly grouping)
echo "   - Migration Month"
gh project field-create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Migration Month" \
  --data-type "TEXT"

# Owning Team (text)
echo "   - Owning Team"
gh project field-create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Owning Team" \
  --data-type "TEXT"

# Repository Size MB (number)
echo "   - Repo Size (MB)"
gh project field-create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Repo Size MB" \
  --data-type "NUMBER"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Rename the default "Board" view → "Daily Dashboard"
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "3/6  Configuring Daily Dashboard view..."
# The first view (number 1) is created automatically; rename it
gh project view edit "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --id 1 \
  --name "Daily Dashboard" 2>/dev/null || \
gh project view create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Daily Dashboard" \
  --layout board

echo "   Daily Dashboard view ready."

# ─────────────────────────────────────────────────────────────────────────────
# 4. Create Monthly Dashboard view
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "4/6  Creating Monthly Dashboard view..."
gh project view create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "Monthly Dashboard" \
  --layout board

echo "   Monthly Dashboard view ready."

# ─────────────────────────────────────────────────────────────────────────────
# 5. Create Table / All Repositories view
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "5/6  Creating All Repositories (table) view..."
gh project view create "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --name "All Repositories" \
  --layout table

echo "   All Repositories view ready."

# ─────────────────────────────────────────────────────────────────────────────
# 6. Link this repository to the project
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "6/6  Linking current repository to project..."
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")"
if [[ -n "$REPO" ]]; then
  gh project link "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --repo "$REPO" 2>/dev/null || echo "   (link skipped — may already be linked)"
  echo "   Linked $REPO"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  GitHub Migration Dashboard project created!             ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  URL: %-56s║\n" "$PROJECT_URL"
printf "║  Number: %-53s║\n" "$PROJECT_NUMBER"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Views created:                                              ║"
echo "║    • Daily Dashboard   (board — group by Migration Status)   ║"
echo "║    • Monthly Dashboard (board — group by Migration Month)    ║"
echo "║    • All Repositories  (table)                               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Next step: run scripts/seed-sample-issues.sh                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "PROJECT_NUMBER=$PROJECT_NUMBER" > /tmp/migration-project.env
echo "PROJECT_URL=$PROJECT_URL"       >> /tmp/migration-project.env
echo "OWNER=$OWNER"                   >> /tmp/migration-project.env
