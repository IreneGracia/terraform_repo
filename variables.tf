
# Exactly one of org_id / folder_id should be set, depending on the customer's
# resource hierarchy. Both are optional so the config also works for a project
# created under a bare organization-less account.
variable "org_id" {
  description = "Organization ID to create the project under. Leave null if using folder_id."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder ID to create the project under. Leave null if using org_id."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID (format XXXXXX-XXXXXX-XXXXXX) to link to the new project. Required for BigQuery and most APIs to work."
  type        = string
}

variable "quota_project_id" {
  description = "An EXISTING project of yours used only as the API quota/billing launchpad (project creation can't bill against the not-yet-created project). No resources are deployed into it."
  type        = string
}

# -----------------------------------------------------------------------------
# BigQuery datasets
# -----------------------------------------------------------------------------
variable "staging_dataset_id" {
  description = "Dataset ID for dbt staging models."
  type        = string
  default     = "staging"
}


# -----------------------------------------------------------------------------
# Location / environment
# -----------------------------------------------------------------------------
variable "region" {
  description = "Default GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "bigquery_location" {
  description = <<-EOT
    BigQuery location for the datasets. MUST match the location of the source
    public dataset that dbt reads from. `bigquery-public-data.crypto_bitcoin_cash`
    lives in the US multi-region, and BigQuery cannot join across locations, so
    this has to stay "US" for the Part 2 dbt models to run.
  EOT
  type        = string
  default     = "US"
}



# -----------------------------------------------------------------------------
# Service account for dbt / CI
# -----------------------------------------------------------------------------
variable "dbt_service_account_id" {
  description = "Account ID (the part before @) for the dbt runner service account."
  type        = string
  default     = "dbt-runner"
}


variable "mart_dataset_id" {
  description = "Dataset ID for dbt data-mart models."
  type        = string
  default     = "mart"
}




variable "github_token" {
  type      = string
  ephemeral = true
  sensitive = true
}

variable "github_owner" {
  type = string
}


variable "dbt_repository" {
  type    = string
  default = "dbt_repo"
}


# -----------------------------------------------------------------------------
# Workload Identity Federation (keyless GitHub Actions -> GCP auth)
# -----------------------------------------------------------------------------
variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool that trusts GitHub's OIDC issuer."
  type        = string
  default     = "github-pool"
}
