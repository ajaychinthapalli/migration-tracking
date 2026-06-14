#!/usr/bin/env bash
# =============================================================================
# create-labels.sh
# Creates all labels needed for the GitHub Migration Dashboard.
# Usage: ./scripts/create-labels.sh [owner/repo]
# Requires: gh CLI authenticated with repo write access
# =============================================================================
set -euo pipefail

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")"
fi
if [[ -z "$REPO" ]]; then
  echo "ERROR: Could not determine repository. Pass owner/repo as first argument."
  exit 1
fi

echo "Creating labels for: $REPO"

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if gh label list --repo "$REPO" --json name -q '.[].name' | grep -qx "$name"; then
    echo "  [UPDATE] $name"
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$description" 2>/dev/null || true
  else
    echo "  [CREATE] $name"
    gh label create "$name" --repo "$REPO" --color "$color" --description "$description"
  fi
}

# ── Migration phase labels ────────────────────────────────────────────────────
create_label "migration"         "0075ca" "Repository is part of GHES → GHEC migration"
create_label "preparation"       "e4e669" "Repo is being prepared for migration"
create_label "scheduled"         "fef2c0" "Migration date is scheduled"
create_label "in-progress"       "f9d0c4" "Migration is actively in progress"
create_label "complete"          "0e8a16" "Migration has been completed"
create_label "post-migration"    "c5def5" "Post-migration tasks underway"
create_label "validation"        "bfd4f2" "Migration is in the validation phase"
create_label "blocked"           "d93f0b" "Migration is blocked"

# ── Priority labels ───────────────────────────────────────────────────────────
create_label "priority: critical" "b60205" "Must migrate immediately"
create_label "priority: high"     "e11d48" "High priority migration"
create_label "priority: medium"   "f97316" "Normal priority migration"
create_label "priority: low"      "84cc16" "Low priority, migrate when convenient"

# ── Type labels ───────────────────────────────────────────────────────────────
create_label "type: app"          "1d76db" "Application repository"
create_label "type: library"      "0052cc" "Library / package repository"
create_label "type: infra"        "5319e7" "Infrastructure / IaC repository"
create_label "type: docs"         "006b75" "Documentation repository"
create_label "type: archive"      "ededed" "Repository will be archived after migration"

echo ""
echo "✅  All labels created/updated for $REPO"
