# Terraform — GCP infrastructure

Infrastructure as Code for the challenge: creates the Google Cloud project, the
BigQuery datasets dbt writes to, the service account dbt runs as, and the keyless
GitHub Actions → GCP authentication.

## What it provisions

| File | Resource(s) |
|------|-------------|
| [`gcp_project.tf`](gcp_project.tf) | The GCP project `blockchain-cash-analysis`. |
| [`services.tf`](services.tf) | Enables the required APIs (BigQuery, IAM, IAM Credentials, STS, Cloud Resource Manager). |
| [`bigquery.tf`](bigquery.tf) | The `staging` and `mart` BigQuery datasets. |
| [`IAM.tf`](IAM.tf) | The `dbt-runner` service account + least-privilege roles: `bigquery.jobUser` (project) and `bigquery.dataEditor` (scoped per dataset). |
| [`WIF.tf`](WIF.tf) | Workload Identity Pool + GitHub OIDC provider, locked to this repo — lets Actions impersonate the SA with **no key**. |
| [`github_actions.tf`](github_actions.tf) | Writes the WIF provider, SA email, project id, and location into the dbt repo as Actions secrets & variables. |

## Prerequisites

- **Terraform ≥ 1.10**, **gcloud**, optional **gh** — `brew install terraform google-cloud-sdk gh`
- A GCP **billing account** and rights to create projects: `resourcemanager.projectCreator` on the org/folder and `roles/billing.user` on the billing account.
- A GitHub **fine-grained PAT** scoped to the dbt repo (Secrets r/w, Variables r/w, Metadata r).
- `gcloud auth application-default login` so Terraform can act as you.

## Configuration

Inputs are **not committed** — `terraform.tfvars` is git-ignored, and the token is
env-only. Set them via a local `terraform.tfvars` and one env var:

**Required (no defaults):**

| Input | Description |
|-------|-------------|
| `billing_account` | Billing account ID to link to the new project. |
| `quota_project_id` | An **existing** project of yours, used only as the API/billing launchpad (project creation can't bill against the not-yet-created project). |
| `github_owner` | GitHub user/org that owns the dbt repo. |
| `github_token` | Fine-grained PAT — **env var only**, never in a file. |
| `org_id` **or** `folder_id` | Where to create the project. Set **exactly one**, or **neither** for a personal account with no organization. |

**Defaulted** (override only if needed): `staging_dataset_id=staging`,
`mart_dataset_id=mart`, `bigquery_location=US` (must match the public source),
`region=us-central1`, `dbt_service_account_id=dbt-runner`,
`dbt_repository=dbt_repo`, `workload_identity_pool_id=github-pool`. See
[`variables.tf`](variables.tf).

```bash
cat > terraform.tfvars <<'EOF'
billing_account  = "XXXXXX-XXXXXX-XXXXXX"
quota_project_id = "your-launchpad-project"
github_owner     = "your-gh-user"
org_id           = "123456789012"   # OR folder_id, OR leave both null
folder_id        = null
EOF
read -rs TF_VAR_github_token && export TF_VAR_github_token   # keeps it out of shell history
```

## Deploy

Order matters: the dbt repo must exist **before** the PAT (a fine-grained PAT is
scoped to an existing repo) and **before** `apply` (it writes secrets into that repo).

```bash
gcloud auth application-default login                      # 1. authenticate
gh repo create <owner>/dbt_repo --public                   # 2. create the dbt repo
read -rs TF_VAR_github_token && export TF_VAR_github_token  # 3. scoped PAT
#                                                            4. fill terraform.tfvars (above)
terraform init
terraform plan      # preview — creates nothing
terraform apply     # create everything
```

Validate only (no GCP/account needed — this is also what CI runs):
`terraform init -backend=false && terraform validate`.

## State

Kept **local** (`terraform.tfstate`, git-ignored) for this single-environment
challenge — runnable with a plain `terraform init`, no bootstrap. Production would
use a **remote GCS backend** with state locking and per-environment isolation.

## CI

<<<<<<< Updated upstream
[`.github/workflows/tf_ci.yml`](.github/workflows/tf_ci.yml) runs `fmt`, `init`,
and `validate` on pull requests.
=======
[`.github/workflows/tf_ci.yml`](.github/workflows/tf_ci.yml) runs `fmt -check`,
`init -backend=false`, and `validate` on pull requests — **static checks only**.
It never runs `plan`/`apply`, never loads state, and never authenticates to GCP,
so a pull request changes nothing in the cloud.

**Why no apply-on-merge:** this config *creates a project and links billing*,
which needs org-level `projectCreator` + billing permissions — too privileged to
hand an automated pipeline. Provisioning is therefore a manual, local
`terraform apply`. (A production GitOps setup would do plan-on-PR + apply-on-merge
with a remote backend and a dedicated least-privilege identity behind manual approval.)
>>>>>>> Stashed changes

## Design choices

- **Keyless CI auth (WIF)** — no long-lived service-account JSON keys to leak or rotate.
- **Least privilege** — `jobUser` at project level; `dataEditor` only on the two owned datasets.
- **`auto_create_network = false`** — the default VPC isn't needed and widens the attack surface.
- **`US` BigQuery location** — must match the public source dataset (BigQuery can't join across locations).
