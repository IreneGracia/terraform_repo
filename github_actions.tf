# Publishes CI config into the dbt repo: GCP project id & location as Actions variables, WIF provider & SA email as secrets.
#
#have to be resources, not variables, because TF creates (and manages) them, as opposed to variables
#which are user fed

resource "github_actions_variable" "project_id" {
  repository    = var.dbt_repository
  variable_name = "GCP_PROJECT_ID"
  value         = google_project.blockchain_cash_analysis.project_id
}

resource "github_actions_variable" "location" {
  repository    = var.dbt_repository
  variable_name = "BQ_LOCATION"
  value         = var.bigquery_location
}


#Could use WO arguments
resource "github_actions_secret" "wif_provider" {
  repository  = var.dbt_repository
  secret_name = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

resource "github_actions_secret" "service_account" {
  repository  = var.dbt_repository
  secret_name = "GCP_SERVICE_ACCOUNT"
  value       = google_service_account.dbt.email
}
