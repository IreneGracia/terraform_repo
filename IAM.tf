# Service account that dbt (locally and in CI) uses to run BigQuery jobs and
# write the staging / data-mart tables. Needed whenever some non-human actor
# needs to interact with our account

resource "google_service_account" "dbt" {
  project      = google_project.blockchain_cash_analysis.project_id
  account_id   = var.dbt_service_account_id
  display_name = "dbt runner"
  description  = "Runs dbt BigQuery jobs from local dev and GitHub Actions CI."

  # Wait for the IAM API. The IAM bindings below reference this SA, so they
  # inherit this dependency transitively and don't need their own depends_on.
  depends_on = [google_project_service.required]
}


# Run query jobs in this project (needed to query the public source dataset).
resource "google_project_iam_member" "dbt_job_user" {
  project = google_project.blockchain_cash_analysis.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}" #Output of SA defined above,
  #generated at runtime. Creates implicit dependency so SA gets made before IAM binging
}


# Write access scoped to each owned dataset only.
resource "google_bigquery_dataset_iam_member" "dbt_staging_editor" {
  project    = google_project.blockchain_cash_analysis.project_id
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_data_mart_editor" {
  project    = google_project.blockchain_cash_analysis.project_id
  dataset_id = google_bigquery_dataset.mart.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt.email}"
}
