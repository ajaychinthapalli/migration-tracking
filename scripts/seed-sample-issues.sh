#!/usr/bin/env bash
# =============================================================================
# seed-sample-issues.sh
# Creates 20 sample repository-migration issues to demonstrate the
# GitHub Migration Dashboard across two migration waves (Jun 17 & Jun 18 2026).
#
# Usage:
#   ./scripts/seed-sample-issues.sh [owner/repo] [project-number]
#
#   owner/repo        Repository to create issues in (default: current repo)
#   project-number    GitHub Project number to add issues to (optional)
#
# Requires: gh CLI authenticated with issues:write + project:write access
# =============================================================================
set -euo pipefail

REPO="${1:-}"
PROJECT_NUMBER="${2:-}"

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")"
fi
if [[ -z "$REPO" ]]; then
  echo "ERROR: Could not determine repository. Pass owner/repo as first argument."
  exit 1
fi

OWNER="${REPO%%/*}"
echo "Seeding sample migration issues into: $REPO"
[[ -n "$PROJECT_NUMBER" ]] && echo "Will add issues to project: #$PROJECT_NUMBER"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Helper: create one issue and optionally add it to the project
# ─────────────────────────────────────────────────────────────────────────────
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local assignees="${4:-}"

  local args=(
    --repo "$REPO"
    --title "$title"
    --body "$body"
    --label "$labels"
  )
  [[ -n "$assignees" ]] && args+=(--assignee "$assignees")

  ISSUE_URL=$(gh issue create "${args[@]}")
  echo "  ✓ $title"
  echo "    $ISSUE_URL"

  # Add to project if PROJECT_NUMBER was supplied
  if [[ -n "$PROJECT_NUMBER" ]]; then
    gh project item-add "$PROJECT_NUMBER" \
      --owner "$OWNER" \
      --url "$ISSUE_URL" 2>/dev/null || true
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Wave 1 – Jun 17 2026  (Preparation → In Progress)
# ─────────────────────────────────────────────────────────────────────────────
echo "── Wave 1: Scheduled for Jun 17 2026 ──────────────────────────────"

create_issue \
  "[MIGRATION] platform/auth-service" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/platform/auth-service |
| **Target GHEC URL** | https://github.com/myorg/auth-service |
| **Scheduled Date** | 2026-06-17 |
| **Team** | platform-engineering |
| **Repo Size** | 450 MB |
| **Priority** | Critical |

### Pre-Migration Checklist
- [x] Repository inventory confirmed
- [x] Repo owner / stakeholders notified
- [x] CI/CD pipelines identified
- [ ] Secrets inventoried
- [ ] Branch protection rules documented

### Notes
Core authentication service — coordinate with security team before migration.
EOF
)" \
  "migration,in-progress,priority: critical,type: app"

create_issue \
  "[MIGRATION] platform/api-gateway" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/platform/api-gateway |
| **Target GHEC URL** | https://github.com/myorg/api-gateway |
| **Scheduled Date** | 2026-06-17 |
| **Team** | platform-engineering |
| **Repo Size** | 180 MB |
| **Priority** | High |

### Pre-Migration Checklist
- [x] Repository inventory confirmed
- [x] Repo owner / stakeholders notified
- [x] CI/CD pipelines identified
- [x] Secrets inventoried
- [x] Branch protection rules documented

### Notes
API gateway — all downstream teams notified.
EOF
)" \
  "migration,in-progress,priority: high,type: app"

create_issue \
  "[MIGRATION] data/pipeline-etl" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/data/pipeline-etl |
| **Target GHEC URL** | https://github.com/myorg/pipeline-etl |
| **Scheduled Date** | 2026-06-17 |
| **Team** | data-platform |
| **Repo Size** | 320 MB |
| **Priority** | High |

### Pre-Migration Checklist
- [x] Repository inventory confirmed
- [x] Stakeholders notified
- [ ] CI/CD pipelines identified
- [ ] Secrets inventoried

### Notes
ETL pipeline — depends on Airflow DAG configs stored separately.
EOF
)" \
  "migration,preparation,priority: high,type: app"

create_issue \
  "[MIGRATION] infra/terraform-modules" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/infra/terraform-modules |
| **Target GHEC URL** | https://github.com/myorg/terraform-modules |
| **Scheduled Date** | 2026-06-17 |
| **Team** | cloud-infrastructure |
| **Repo Size** | 95 MB |
| **Priority** | Critical |

### Pre-Migration Checklist
- [x] Repository inventory confirmed
- [x] Stakeholders notified
- [x] CI/CD pipelines identified
- [x] Secrets inventoried
- [x] Branch protection rules documented
- [x] Migration trial run completed

### Notes
Terraform modules — state files stored in S3, not in repo.
EOF
)" \
  "migration,complete,priority: critical,type: infra"

create_issue \
  "[MIGRATION] platform/notification-service" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/platform/notification-service |
| **Target GHEC URL** | https://github.com/myorg/notification-service |
| **Scheduled Date** | 2026-06-17 |
| **Team** | platform-engineering |
| **Repo Size** | 210 MB |
| **Priority** | Medium |

### Pre-Migration Checklist
- [x] All pre-migration items complete

### Post-Migration Checklist
- [x] Repository accessible on GHEC
- [x] All branches migrated
- [x] CI/CD pipelines updated and passing
- [ ] Webhooks re-configured
EOF
)" \
  "migration,post-migration,priority: medium,type: app"

create_issue \
  "[MIGRATION] frontend/design-system" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/frontend/design-system |
| **Target GHEC URL** | https://github.com/myorg/design-system |
| **Scheduled Date** | 2026-06-17 |
| **Team** | frontend-platform |
| **Repo Size** | 750 MB |
| **Priority** | High |

### Notes
Large repo due to Storybook build artifacts — clean up before migration.
EOF
)" \
  "migration,preparation,priority: high,type: library"

create_issue \
  "[MIGRATION] platform/user-service" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/platform/user-service |
| **Target GHEC URL** | https://github.com/myorg/user-service |
| **Scheduled Date** | 2026-06-17 |
| **Team** | identity-team |
| **Repo Size** | 340 MB |
| **Priority** | Critical |

### Post-Migration Checklist
- [x] Repository accessible on GHEC
- [x] All branches migrated
- [x] CI/CD pipelines updated and passing
- [x] Secrets configured
- [x] Branch protection re-applied
- [x] Webhooks re-configured
- [x] Team permissions set
- [x] GHES repository archived
EOF
)" \
  "migration,validation,priority: critical,type: app"

# ─────────────────────────────────────────────────────────────────────────────
# Wave 2 – Jun 18 2026
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── Wave 2: Scheduled for Jun 18 2026 ──────────────────────────────"

create_issue \
  "[MIGRATION] backend/payment-processor" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/backend/payment-processor |
| **Target GHEC URL** | https://github.com/myorg/payment-processor |
| **Scheduled Date** | 2026-06-18 |
| **Team** | payments-team |
| **Repo Size** | 290 MB |
| **Priority** | Critical |

### Notes
PCI-DSS compliance review required before migration.
EOF
)" \
  "migration,scheduled,priority: critical,type: app"

create_issue \
  "[MIGRATION] backend/order-management" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/backend/order-management |
| **Target GHEC URL** | https://github.com/myorg/order-management |
| **Scheduled Date** | 2026-06-18 |
| **Team** | commerce-team |
| **Repo Size** | 410 MB |
| **Priority** | High |
EOF
)" \
  "migration,scheduled,priority: high,type: app"

create_issue \
  "[MIGRATION] data/analytics-warehouse" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/data/analytics-warehouse |
| **Target GHEC URL** | https://github.com/myorg/analytics-warehouse |
| **Scheduled Date** | 2026-06-18 |
| **Team** | data-platform |
| **Repo Size** | 520 MB |
| **Priority** | High |
EOF
)" \
  "migration,preparation,priority: high,type: app"

create_issue \
  "[MIGRATION] infra/kubernetes-manifests" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/infra/kubernetes-manifests |
| **Target GHEC URL** | https://github.com/myorg/kubernetes-manifests |
| **Scheduled Date** | 2026-06-18 |
| **Team** | cloud-infrastructure |
| **Repo Size** | 65 MB |
| **Priority** | Critical |
EOF
)" \
  "migration,preparation,priority: critical,type: infra"

create_issue \
  "[MIGRATION] platform/search-service" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/platform/search-service |
| **Target GHEC URL** | https://github.com/myorg/search-service |
| **Scheduled Date** | 2026-06-18 |
| **Team** | discovery-team |
| **Repo Size** | 200 MB |
| **Priority** | Medium |
EOF
)" \
  "migration,scheduled,priority: medium,type: app"

create_issue \
  "[MIGRATION] mobile/ios-app" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/mobile/ios-app |
| **Target GHEC URL** | https://github.com/myorg/ios-app |
| **Scheduled Date** | 2026-06-18 |
| **Team** | mobile-engineering |
| **Repo Size** | 1.2 GB |
| **Priority** | High |

### Notes
Large repo — LFS objects need special handling.
EOF
)" \
  "migration,preparation,priority: high,type: app"

create_issue \
  "[MIGRATION] mobile/android-app" \
  "$(cat <<'EOF'
## Repository Migration Tracking

| Field | Value |
|-------|-------|
| **GHES URL** | https://ghes.example.com/mobile/android-app |
| **Target GHEC URL** | https://github.com/myorg/android-app |
| **Scheduled Date** | 2026-06-18 |
| **Team** | mobile-engineering |
| **Repo Size** | 980 MB |
| **Priority** | High |

### Notes
Large repo — LFS objects need special handling.
EOF
)" \
  "migration,preparation,priority: high,type: app"

# ─────────────────────────────────────────────────────────────────────────────
# Backlog / Future Waves
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── Backlog / Future waves ──────────────────────────────────────────"

for repo_name in \
  "platform/billing-service:billing-team:180:medium:app" \
  "platform/inventory-service:commerce-team:220:medium:app" \
  "data/ml-models:ml-platform:650:high:app" \
  "infra/ci-templates:platform-engineering:45:low:infra" \
  "docs/engineering-handbook:platform-engineering:30:low:docs" \
  "platform/legacy-monolith:core-platform:2100:critical:app" \
; do
  IFS=':' read -r rname team size prio rtype <<< "$repo_name"
  create_issue \
    "[MIGRATION] $rname" \
    "$(printf '## Repository Migration Tracking\n\n| Field | Value |\n|-------|-------|\n| **GHES URL** | https://ghes.example.com/%s |\n| **Target GHEC URL** | https://github.com/myorg/%s |\n| **Scheduled Date** | TBD |\n| **Team** | %s |\n| **Repo Size** | %s MB |\n| **Priority** | %s |' "$rname" "${rname##*/}" "$team" "$size" "$prio")" \
    "migration,preparation,priority: $prio,type: $rtype"
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Sample issues seeded successfully!                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Open the project and set 'Migration Date' and 'Migration Status'"
echo "     fields on each issue."
echo "  2. In Daily Dashboard view: group by 'Migration Date'."
echo "  3. In Monthly Dashboard view: group by 'Migration Month'."
