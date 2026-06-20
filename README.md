# Terraform — GCP infrastructure for the Bitcoin Cash dbt project

Infrastructure as Code for the challenge. It creates the Google Cloud project,
the BigQuery datasets dbt writes to, the service account dbt runs as, and the
Workload Identity Federation that lets GitHub Actions authenticate without keys.

## What it provisions

| File | Resource |
|------|----------|
| [`gcp_project.tf`](gcp_project.tf) | The GCP project (`blockchain-cash-analysis`). |
| [`bigquery.tf`](bigquery.tf) | `staging` and `mart` BigQuery datasets. |
| [`IAM.tf`](IAM.tf) | The `dbt-runner` service account + least-privilege roles (`bigquery.jobUser`, dataset-scoped `dataEditor`). |
| [`WIF.tf`](WIF.tf) | Workload Identity Pool + GitHub OIDC provider, locked to this repo. |
| [`github_actions.tf`](github_actions.tf) | Pushes the WIF provider name / SA email into the dbt repo as Actions variables & secrets. |

Terraform state is kept **local** for this challenge — see [State](#state) below.

## Prerequisites

Install on your laptop:

- **Terraform** ≥ 1.10 (needed for ephemeral variables) — <https://developer.hashicorp.com/terraform/install>
- **Google Cloud SDK** (`gcloud`) — <https://cloud.google.com/sdk/docs/install>
- **GitHub CLI** (`gh`) *(optional)* — <https://cli.github.com/>, only if you want
  to create the target dbt repo from the terminal (step 2 of *Deploying for real*);
  you can create it in the GitHub UI instead.

> macOS (Homebrew): `brew install terraform google-cloud-sdk gh`.

You also need:

- A Google Cloud **billing account**, and an **organization or folder** ID to
  create the project under (exactly one of the two).
- A **GitHub personal access token** so the github provider can set Actions
  variables/secrets on the dbt repo. **Recommended:** a **fine-grained** token
  scoped to *only* the `dbt_repo` repository, with **Secrets: read/write**,
  **Variables: read/write**, and **Metadata: read** permissions (least privilege).
  A classic token with `repo` + `workflow` also works but is account-wide
  (it can touch *all* your repos), so prefer fine-grained.

Authenticate `gcloud` once so Terraform can use your credentials:

```bash
gcloud auth application-default login
```

## Configuration

This config takes a handful of inputs that are **specific to your environment**.
None of them are committed: `terraform.tfvars` is **git-ignored** (it would hold
real IDs), and the GitHub token is **sensitive** so it's passed via the
environment only. So before running, **you must provide these yourself** — either
by creating a local `terraform.tfvars` or by exporting `TF_VAR_*` environment
variables.

### Required inputs (no defaults)

| Input | What it is | Example |
|-------|-----------|---------|
| `billing_account` | Billing account ID to link to the new project. | `016000-776EF1-B2C555` |
| `quota_project_id` | An **existing** project of yours used only as the API quota/billing launchpad (project creation can't bill against the not-yet-created project). | `my-launchpad-project` |
| `github_owner` | Your GitHub user/org that owns the dbt repo. | `your-gh-user` |
| `github_token` | A **fine-grained PAT** scoped to the dbt repo (Secrets r/w, Variables r/w, Metadata r). **Sensitive — set via env var only, never in tfvars.** | `github_pat_…` |
| **one of** `org_id` / `folder_id` | The numeric org **or** folder to create the project under. Set **exactly one**, or **neither** for a personal account with no organization. | `631604454142` |

### Inputs with sensible defaults (override only if needed)

`staging_dataset_id` (`staging`), `mart_dataset_id` (`mart`),
`bigquery_location` (`US` — must match the public source dataset),
`region` (`us-central1`), `dbt_service_account_id` (`dbt-runner`),
`dbt_repository` (`dbt_repo`), `workload_identity_pool_id` (`github-pool`).
See [`variables.tf`](variables.tf) for the full list.

### How to set them

The clean split: **everything except the token in `terraform.tfvars`** (local,
git-ignored), and the **token in the environment** (so it never lands in a file):

```bash
# 1. Create terraform.tfvars locally (it is git-ignored — safe to hold real IDs):
cat > terraform.tfvars <<'EOF'
billing_account  = "XXXXXX-XXXXXX-XXXXXX"
quota_project_id = "your-launchpad-project-id"
github_owner     = "your-gh-user"
org_id           = "123456789012"   # OR set folder_id instead, OR leave both unset
folder_id        = null
EOF

# 2. Export the sensitive token in your shell (never put it in tfvars).
#    `read -rs` keeps it out of your shell history.
read -rs TF_VAR_github_token && export TF_VAR_github_token
```

> Everything here can alternatively be supplied as `TF_VAR_*` environment
> variables (e.g. `export TF_VAR_billing_account=…`) if you prefer not to write a
> file at all — Terraform reads both.

## Usage

Validation only (no GCP account needed) — this is also what CI runs:

```bash
cd terraform_repo
terraform init
terraform validate
```

### Deploying for real

Run these **in order** — each is a prerequisite for `apply` to succeed.

```bash
# 1. Authenticate gcloud so the Google provider can act as you.
gcloud auth application-default login

# 2. Create the target GitHub repo FIRST. The github_actions_* resources write
#    Actions variables/secrets INTO it, and the fine-grained PAT in step 3 must be
#    scoped to an existing repo — so this has to come before the token.
gh repo create irenegracia/dbt_repo --public      # or create it in the GitHub UI

# 3. Generate a fine-grained PAT scoped to the repo from step 2 (Secrets: r/w,
#    Variables: r/w, Metadata: r) and export it. Sensitive — env only, never tfvars.
#    (`read -rs` keeps it out of your shell history.)
read -rs TF_VAR_github_token && export TF_VAR_github_token

# 4. Set real values in terraform.tfvars:
#      - org_id   : your NUMERIC organization ID (e.g. "123456789012"), or
#                   set folder_id instead, or leave both null for a personal
#                   account with no org.
#      - billing_account : "XXXXXX-XXXXXX-XXXXXX"
#      - github_owner    : your GitHub user/org

# 5. Deploy.
terraform init
terraform plan      # preview — creates nothing
terraform apply
```

> **Why repo-before-token:** a fine-grained PAT is scoped to specific repositories
> you pick from a list at creation time, so the repo must already exist. (A classic
> account-wide token wouldn't have this ordering constraint, but it's broader.)

No state bootstrap is required — state is local (see [State](#state) below).

> You also need the right permissions on your GCP identity:
> `resourcemanager.projectCreator` on the org/folder, and **Billing Account User**
> (`roles/billing.user`) on the billing account so Terraform can link it.

## State

State is kept **local** (`terraform.tfstate` in this directory) for this
single-environment challenge. This keeps the project runnable with a plain
`terraform init` — no external bucket, project, or bootstrap to set up first. The
state files are git-ignored (see [`.gitignore`](.gitignore)) because they can
contain sensitive values and must never be committed.

> **Production note:** for a real, multi-environment, multi-engineer setup you'd
> use a **remote backend** (e.g. GCS) instead. That gives shared state with
> **locking** (so concurrent `apply`s can't corrupt it) and per-environment
> isolation (separate `dev` / `prod` state). It's deliberately omitted here as
> over-engineering for a single-environment take-home.

## CI

[`.github/workflows/tf_ci.yml`](.github/workflows/tf_ci.yml) runs `fmt -check`,
`init -backend=false`, and `validate` on pull requests. These are **static checks
only** — the workflow never runs `plan` or `apply`, never loads state, and never
authenticates to GCP, so a pull request makes **no changes to any cloud
resources**.

### Why CI doesn't `apply`

Applying infrastructure from CI is deliberately avoided here because this config
**creates a GCP project and links a billing account**. To `apply` from CI, the
pipeline's identity would need **org-level `resourcemanager.projectCreator` and
billing permissions** — a very privileged credential to hand to an automated
workflow, and a large blast radius if the repo or a token were ever compromised.

For a single-environment take-home, the safer split is **validate in CI, `apply`
locally**: provisioning is a manual `terraform apply` run by a human with the
appropriate permissions (see [Deploying for real](#deploying-for-real)), while CI
just guards code quality.

> **Production evolution:** a real GitOps setup would run `terraform plan` on the
> PR (posted as a comment for review) and `terraform apply` on merge to `main`,
> backed by a remote state backend with locking and a dedicated, least-privilege
> CI identity gated behind manual approval. That's intentionally out of scope for
> this challenge.

## Design choices

- **Keyless CI auth** via Workload Identity Federation — no long-lived
  service-account JSON keys to leak or rotate.
- **Least privilege** — the runner gets `jobUser` at the project level and
  `dataEditor` only on the two datasets it owns, not project-wide.
- **`auto_create_network = false`** — the default VPC isn't needed and widens
  the attack surface.
- **`US` BigQuery location** — must match the public source dataset; BigQuery
  cannot join across locations.
