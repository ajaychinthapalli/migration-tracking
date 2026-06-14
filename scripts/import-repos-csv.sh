#!/usr/bin/env bash
# =============================================================================
# import-repos-csv.sh
# Reads a CSV file of repositories and creates GitHub migration-tracking issues
# for each row. Optionally adds created issues to a GitHub Project.
#
# CSV format (header row required):
#   repo_name,team,scheduled_date,repo_size_mb,priority,type
#
# Columns:
#   repo_name        Full GHES path, e.g. "platform/auth-service"
#   team             Owning team, e.g. "platform-engineering"
#   scheduled_date   YYYY-MM-DD or "TBD"
#   repo_size_mb     Size in MB (number or empty)
#   priority         critical | high | medium | low
#   type             app | library | infra | docs | archive
#
# Usage:
#   ./scripts/import-repos-csv.sh <csv-file> [owner/repo] [project-number]
#
#   csv-file        Path to the CSV file
#   owner/repo      Repository to create issues in (default: current repo)
#   project-number  GitHub Project number to add issues to (optional)
#
# Requires: gh CLI authenticated with issues:write + project:write access
# =============================================================================
set -euo pipefail

CSV_FILE="${1:-}"
REPO="${2:-}"
PROJECT_NUMBER="${3:-}"

# ─────────────────────────────────────────────────────────────────────────────
# Validate inputs
# ─────────────────────────────────────────────────────────────────────────────
if [[ -z "$CSV_FILE" ]]; then
  echo "ERROR: CSV file path is required as the first argument."
  echo "Usage: $0 <csv-file> [owner/repo] [project-number]"
  exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "ERROR: CSV file not found: $CSV_FILE"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")"
fi
if [[ -z "$REPO" ]]; then
  echo "ERROR: Could not determine repository. Pass owner/repo as second argument."
  exit 1
fi

OWNER="${REPO%%/*}"
GHEC_ORG="${GHEC_ORG:-$OWNER}"
GHES_DOMAIN="${GHES_DOMAIN:-ghes.example.com}"

echo "Importing migration issues from: $CSV_FILE"
echo "Repository:  $REPO"
echo "GHES domain: $GHES_DOMAIN"
[[ -n "$PROJECT_NUMBER" ]] && echo "Project number: #$PROJECT_NUMBER"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Helper: map priority → label name
# ─────────────────────────────────────────────────────────────────────────────
priority_label() {
  local p="${1,,}"   # lowercase
  case "$p" in
    critical) echo "priority: critical" ;;
    high)     echo "priority: high"     ;;
    medium)   echo "priority: medium"   ;;
    low)      echo "priority: low"      ;;
    *)        echo "priority: medium"   ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Helper: map type → label name
# ─────────────────────────────────────────────────────────────────────────────
type_label() {
  local t="${1,,}"
  case "$t" in
    library|lib) echo "type: library" ;;
    infra|iac)   echo "type: infra"   ;;
    docs|doc)    echo "type: docs"    ;;
    archive)     echo "type: archive" ;;
    *)           echo "type: app"     ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Helper: strip carriage returns and surrounding whitespace from a string
# ─────────────────────────────────────────────────────────────────────────────
trim_field() {
  local v="$1"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  echo "$v"
}

# ─────────────────────────────────────────────────────────────────────────────
# Helper: determine migration phase label from scheduled_date
# ─────────────────────────────────────────────────────────────────────────────
phase_label() {
  local date="$1"
  if [[ -z "$date" || "${date,,}" == "tbd" ]]; then
    echo "preparation"
  else
    echo "scheduled"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Helper: create one issue and optionally add it to the project
# ─────────────────────────────────────────────────────────────────────────────
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"

  local args=(
    --repo "$REPO"
    --title "$title"
    --body "$body"
    --label "$labels"
  )

  ISSUE_URL=$(gh issue create "${args[@]}")
  echo "  ✓ $title"
  echo "    $ISSUE_URL"

  if [[ -n "$PROJECT_NUMBER" ]]; then
    gh project item-add "$PROJECT_NUMBER" \
      --owner "$OWNER" \
      --url "$ISSUE_URL" 2>/dev/null || true
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Parse CSV and create issues
# ─────────────────────────────────────────────────────────────────────────────
CREATED=0
SKIPPED=0
LINE_NUM=0

while IFS=',' read -r repo_name team scheduled_date repo_size_mb priority type || [[ -n "$repo_name" ]]; do
  LINE_NUM=$(( LINE_NUM + 1 ))

  # Strip carriage returns (Windows line endings) and surrounding whitespace
  repo_name="$(trim_field "$repo_name")"
  team="$(trim_field "$team")"
  scheduled_date="$(trim_field "$scheduled_date")"
  repo_size_mb="$(trim_field "$repo_size_mb")"
  priority="$(trim_field "$priority")"
  type="$(trim_field "$type")"

  # Skip header row (any row where first column is literally "repo_name")
  if [[ "${repo_name,,}" == "repo_name" ]]; then
    continue
  fi

  # Skip blank lines
  if [[ -z "$repo_name" ]]; then
    continue
  fi

  # Defaults
  team="${team:-unknown}"
  scheduled_date="${scheduled_date:-TBD}"
  repo_size_mb="${repo_size_mb:-}"
  priority="${priority:-medium}"
  type="${type:-app}"

  PRIO_LABEL="$(priority_label "$priority")"
  TYPE_LABEL="$(type_label "$type")"
  PHASE_LABEL="$(phase_label "$scheduled_date")"

  SHORT_NAME="${repo_name##*/}"
  GHES_URL="https://ghes.example.com/${repo_name}"
  GHEC_URL="https://github.com/${GHEC_ORG}/${SHORT_NAME}"
  SIZE_DISPLAY="${repo_size_mb:+${repo_size_mb} MB}"
  SIZE_DISPLAY="${SIZE_DISPLAY:-N/A}"

  ISSUE_BODY="## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | ${GHES_URL} |
| **Target GHEC URL** | ${GHEC_URL} |
| **Scheduled Date** | ${scheduled_date} |
| **Team** | ${team} |
| **Repo Size** | ${SIZE_DISPLAY} |
| **Priority** | ${priority^} |

### Pre-Migration Checklist
- [ ] Repository inventory confirmed
- [ ] Repo owner / stakeholders notified
- [ ] CI/CD pipelines identified and documented
- [ ] Secrets / environment variables inventoried
- [ ] Branch protection rules documented
- [ ] Webhooks and integrations documented
- [ ] Target GHEC org and visibility confirmed
- [ ] Migration trial run completed

### Post-Migration / Validation Checklist
- [ ] Repository accessible on GHEC
- [ ] All branches migrated
- [ ] All PRs / issues migrated
- [ ] CI/CD pipelines updated and passing
- [ ] Secrets / environment variables configured in GHEC
- [ ] Branch protection rules re-applied
- [ ] Webhooks and integrations re-configured
- [ ] Team permissions set correctly
- [ ] GHES repository archived / redirected"

  LABELS="migration,${PHASE_LABEL},${PRIO_LABEL},${TYPE_LABEL}"

  create_issue "[MIGRATION] ${repo_name}" "$ISSUE_BODY" "$LABELS"
  CREATED=$(( CREATED + 1 ))

done < "$CSV_FILE"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  CSV import complete!                                    ║"
printf "║  Issues created: %-44s║\n" "$CREATED"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
if [[ -n "$PROJECT_NUMBER" ]]; then
  echo "Issues added to project #${PROJECT_NUMBER}."
  echo "Next: open the project and set 'Migration Status' and 'Migration Date' fields."
fi
