# GitHub Migration Dashboard

A turnkey GitHub Project dashboard for tracking repository migrations from **GitHub Enterprise Server (GHES)** to **GitHub Enterprise Cloud (GHEC)**.

---

## 📐 Dashboard Structure

### Daily Dashboard (board view)
Tracks every repository migration day-by-day. Each column represents a migration phase:

| Column | Description |
|--------|-------------|
| 📋 **Preparation** | Repository is being catalogued and pre-migration tasks are running |
| 📅 **Scheduled** | Migration date is set; team is ready |
| 🔄 **In Progress** | Active migration underway (GEI / `gh-migration-audit` running) |
| ✅ **Complete** | Data transfer finished |
| 🔍 **Post Migration** | Post-migration tasks (CI/CD, secrets, webhooks) being re-configured |
| 🎯 **Validation** | Testing and sign-off happening on GHEC |
| 🚫 **Blocked** | Migration is stuck — needs immediate attention |

**Example — Wave view for Jun 17 2026:**

```
Jun 17 2026
┌───────────────┬───────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
│ Preparation   │ Scheduled     │ In Progress   │ Complete      │ Post Migration│ Validation    │
├───────────────┼───────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ design-system │               │ auth-service  │ terraform-mod │ notification- │ user-service  │
│ frontend/…    │               │ api-gateway   │ ules          │ service       │               │
└───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┘
```

### Monthly Dashboard (board view)
Rolls up all waves within a calendar month. Columns are simplified:

| Column | Description |
|--------|-------------|
| 📅 **Scheduled** | Migrations planned within this month |
| 🔄 **In Progress** | Migrations actively running |
| ✅ **Complete** | Migrations that finished this month |

**Example — June 2026:**
```
June 2026
┌───────────────────┬──────────────────────┬───────────────────────┐
│ Scheduled         │ In Progress          │ Complete              │
├───────────────────┼──────────────────────┼───────────────────────┤
│ payment-processor │ auth-service         │ terraform-modules     │
│ order-management  │ api-gateway          │ user-service          │
│ analytics-wh      │ notification-svc     │                       │
│ …                 │ …                    │                       │
└───────────────────┴──────────────────────┴───────────────────────┘
```

---

## 🗂️ Repository Structure

```
.github/
├── ISSUE_TEMPLATE/
│   └── repository-migration.yml         # Issue template for each migrating repo
└── workflows/
    ├── bootstrap-migration-dashboard.yml  # One-time project setup
    ├── import-repos-csv.yml               # Bulk import repos from CSV
    └── migration-automation.yml           # Daily sync + status comments

scripts/
├── create-labels.sh        # Creates all migration phase labels
├── import-repos-csv.sh     # Creates issues from a CSV list of repositories
├── setup-project.sh        # Creates the GitHub Project + views + fields
└── seed-sample-issues.sh   # Creates 20 sample migration issues (demo)

docs/
└── (see below)

README.md
```

---

## 📥 Importing Repositories from CSV

The fastest way to populate the dashboard is to import a CSV list of repositories.

### CSV format

```csv
repo_name,team,scheduled_date,repo_size_mb,priority,type
platform/auth-service,platform-engineering,2026-06-17,450,critical,app
infra/terraform-modules,cloud-infrastructure,2026-06-17,95,critical,infra
data/analytics-warehouse,data-platform,2026-06-18,520,high,app
mobile/ios-app,mobile-engineering,2026-06-18,1200,high,app
platform/legacy-monolith,core-platform,TBD,2100,critical,app
```

| Column | Required | Description |
|--------|----------|-------------|
| `repo_name` | ✅ | Full GHES path (e.g. `platform/auth-service`) |
| `team` | ✅ | Owning team or contact |
| `scheduled_date` | ✅ | `YYYY-MM-DD` or `TBD` |
| `repo_size_mb` | — | Approximate size in MB |
| `priority` | — | `critical` \| `high` \| `medium` \| `low` (default: `medium`) |
| `type` | — | `app` \| `library` \| `infra` \| `docs` \| `archive` (default: `app`) |

> Rows with `scheduled_date` set to a date get the **`scheduled`** label.
> Rows with `TBD` get the **`preparation`** label.

### Option A: Import via GitHub Actions (recommended)

1. Go to **Actions → Import Repositories from CSV**.
2. Click **Run workflow** and paste your CSV content into the **csv_content** field.
3. Optionally provide your **Project number** (from the URL of your GitHub Project) to have issues added automatically.
4. Click **Run workflow** — a tracking issue will be created for every repository row.

### Option B: Import locally

```bash
# 1. Create your CSV file (e.g. repos.csv)
# 2. Run the import script
./scripts/import-repos-csv.sh repos.csv myorg/migration-tracking <project-number>

# Override the GHES domain (default: ghes.example.com) and target GHEC org:
GHES_DOMAIN=ghes.mycompany.com GHEC_ORG=myorg \
  ./scripts/import-repos-csv.sh repos.csv myorg/migration-tracking <project-number>
```

---



### Prerequisites
- `gh` CLI installed and authenticated (`gh auth login`)
- A GitHub organisation (or user account) where the project will be created
- A classic Personal Access Token with scopes: `repo`, `project`, `admin:org` (for org-level projects)
  — store it as the repository secret **`PROJECT_TOKEN`**

### Option A: Run via GitHub Actions (recommended)

1. Go to **Actions → Bootstrap Migration Dashboard**.
2. Click **Run workflow** and fill in:
   - **Owner type**: `org` or `user`
   - **Seed sample issues**: ✅ (recommended for first run)
3. The workflow will:
   - Create all labels
   - Create the project with all custom fields and three views
   - Optionally seed 20 sample migration issues

### Option B: Run scripts locally

```bash
# 1. Authenticate
gh auth login

# 2. Create labels
./scripts/create-labels.sh myorg/migration-tracking

# 3. Create the project (org owner)
./scripts/setup-project.sh myorg org

# 4. Seed sample issues (optional)
./scripts/seed-sample-issues.sh myorg/migration-tracking <project-number>
```

---

## 📋 Tracking a Repository Migration

1. Open a new issue using the **Repository Migration** template.
2. Fill in: repository name, GHES URL, scheduled date, team owner.
3. The issue is automatically added to the project.
4. Update the **Migration Status** label as the repo moves through phases — the automation workflow will comment and update the project field automatically.
5. When all post-migration checklist items are ticked and validated, close the issue.

### Label-to-Phase Mapping

| Label | Project Status |
|-------|---------------|
| `preparation` | Preparation |
| `scheduled` | Scheduled |
| `in-progress` | In Progress |
| `complete` | Complete |
| `post-migration` | Post Migration |
| `validation` | Validation |
| `blocked` | Blocked |

---

## ⚙️ Automation

| Trigger | Action |
|---------|--------|
| Issue labeled | Status comment added to issue |
| Daily at 06:00 UTC | Summary report generated in Actions |
| Daily (if blockers > 0) | Alert issue automatically opened |

---

## 🔑 Secrets

| Secret | Required for | Description |
|--------|-------------|-------------|
| `GITHUB_TOKEN` | Issues, labels | Auto-provided by GitHub Actions |
| `PROJECT_TOKEN` | Project creation | Classic PAT with `project` + `read:org` scopes |

---

## 📊 Sample Migration Wave Schedule

| Wave | Date | Repositories |
|------|------|-------------|
| Wave 1 | Jun 17 2026 | auth-service, api-gateway, pipeline-etl, terraform-modules, notification-service, design-system, user-service |
| Wave 2 | Jun 18 2026 | payment-processor, order-management, analytics-warehouse, kubernetes-manifests, search-service, ios-app, android-app |
| Backlog | TBD | billing-service, inventory-service, ml-models, ci-templates, engineering-handbook, legacy-monolith |