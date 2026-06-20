resource "google_iam_workload_identity_pool" "github_pook" {
  project                   = google_project.blockchain_cash_analysis.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "Github pool"

  # Wait for the IAM API. The provider and the SA IAM member reference this pool,
  # so they inherit this dependency transitively.
  depends_on = [google_project_service.required]
}



resource "google_iam_workload_identity_pool_provider" "github" {
  project = google_project.blockchain_cash_analysis.project_id
  # Reference the pool resource (not the raw var) so Terraform creates the pool
  # before the provider that lives inside it.
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pook.workload_identity_pool_id
  workload_identity_pool_provider_id = "dbt-repo"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Hard restriction: only tokens from the configured repository are accepted.
  # GitHub's `assertion.repository` is in `owner/repo` form, so we compose it
  # from the two vars. Without an attribute_condition the provider would trust
  # the entire GitHub OIDC issuer, so this is required for a secure setup.
  attribute_condition = "assertion.repository == '${var.github_owner}/${var.dbt_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}



# Let GitHub Actions runs from the dbt repo impersonate the dbt service account
# (keyless). The principalSet is the set of identities from this pool whose
# `repository` attribute matches owner/repo.
resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pook.name}/attribute.repository/${var.github_owner}/${var.dbt_repository}"
}
