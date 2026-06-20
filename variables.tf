# Organisation to create the project under (set this OR folder_id, or neither for a personal account)
variable "org_id" {
  description = "Organisation ID to create the project under. Leave null if using folder_id."
  type        = string
  default     = null
}

# Folder to create the project under (set this OR org_id, or neither for a personal account).
variable "folder_id" {
  description = "Folder ID to create the project under. Leave null if using org_id."
  type        = string
  default     = null
}

# Billing account linked to the new project; required for BigQuery and most APIs.
variable "billing_account" {
  description = "Billing account ID (format XXXXXX-XXXXXX-XXXXXX) to link to the new project."
  type        = string
}

# Existing project used only as the API/billing launchpad while the new project is created.
variable "quota_project_id" {
  description = "An existing project used only as the API quota/billing launchpad"
  type        = string
}

# BigQuery dataset where dbt materialises the staging model
variable "staging_dataset_id" {
  description = "Dataset ID for dbt staging models."
  type        = string
  default     = "staging"
}

# BigQuery dataset where dbt materialises the mart model
variable "mart_dataset_id" {
  description = "Dataset ID for dbt data-mart models."
  type        = string
  default     = "mart"
}

# Default GCP region for regional resources.
variable "region" {
  description = "Default GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

# BigQuery location for the datasets; must match the public source (US multi-region).
variable "bigquery_location" {
  description = <<-EOT
    BigQuery location for the datasets. Must match the location of the source
    public dataset that dbt reads from. `bigquery-public-data.crypto_bitcoin_cash`
    lives in the US multi-region, and BigQuery cannot join across locations, so
    this has to stay "US" for the dbt models to run.
  EOT
  type        = string
  default     = "US"
}

# Account ID (the part before @) for the service account dbt runs as.
variable "dbt_service_account_id" {
  description = "Account ID (the part before @) for the dbt runner service account."
  type        = string
  default     = "dbt-runner"
}

# GitHub PAT used to set Actions secrets/variables on the dbt repo
variable "github_token" {
  type      = string
  ephemeral = true
  sensitive = true
}

# GitHub user or org that owns the dbt repository
variable "github_owner" {
  type = string
}

# Name of the dbt GitHub repository this config writes CI secrets/variables into
variable "dbt_repository" {
  type    = string
  default = "dbt_repo"
}

# ID for the Workload Identity Pool that trusts GitHub's OIDC issuer (keyless CI auth)
variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool that trusts GitHub's OIDC issuer."
  type        = string
  default     = "github-pool"
}
