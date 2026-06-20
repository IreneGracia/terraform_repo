# API enablement.

# A brand-new GCP project has nearly every API disabled, so each must be turned
# on (via the Service Usage API) before Terraform can create resources that use
# it. Enabling is itself an API call, so these depend implicitly on the project
# existing (via project_id), and every API-using resource elsewhere depends on
# this block: see the `depends_on` on the datasets, service account, and WIF
# pool.

resource "google_project_service" "required" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com", # the project + project-level IAM bindings
    "bigquery.googleapis.com",             # staging / mart datasets and dbt jobs
    "iam.googleapis.com",                  # service account + IAM, WIF pool/provider
    "iamcredentials.googleapis.com",       # short-lived SA token minting (keyless CI)
    "sts.googleapis.com",                  # OIDC -> Google token exchange (keyless CI)
  ])

  project = google_project.blockchain_cash_analysis.project_id
  service = each.value

  # Don't disable the API if this resource is destroyed — disabling an API can
  # break unrelated things still using it, and is rarely the intent.
  disable_on_destroy = false
}

# Cloud Billing API must be enabled on the existing launchpad project so Terraform
# can link the billing account when it creates the new project. The new project
# depends on this (see gcp_project.tf).
resource "google_project_service" "billing_api" {
  project            = var.quota_project_id
  service            = "cloudbilling.googleapis.com"
  disable_on_destroy = false
}
