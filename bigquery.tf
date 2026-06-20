resource "google_bigquery_dataset" "staging" {
  dataset_id                 = var.staging_dataset_id
  location                   = var.bigquery_location
  friendly_name              = "Staging"
  project                    = google_project.blockchain_cash_analysis.project_id
  deletion_policy            = "DELETE"
  delete_contents_on_destroy = true

  # Tables are created by dbt and terraform therefore does not know about them,
  #so with a different policy any attempt at deleting a dataset will encoutner tables inside and fail

  # Wait until the BigQuery API is enabled (no implicit ref to it otherwise).
  depends_on = [google_project_service.required]
}



resource "google_bigquery_dataset" "mart" {
  dataset_id                 = var.mart_dataset_id
  location                   = var.bigquery_location
  friendly_name              = "Mart"
  project                    = google_project.blockchain_cash_analysis.project_id
  deletion_policy            = "DELETE"
  delete_contents_on_destroy = true

  depends_on = [google_project_service.required]
}
