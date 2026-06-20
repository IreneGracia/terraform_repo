resource "google_project" "blockchain_cash_analysis" {
  name       = "Blockchain Cash Analysis"
  project_id = "blockchain-cash-analysis" #must be globally unique

  billing_account = var.billing_account

  org_id    = var.org_id
  folder_id = var.folder_id

  auto_create_network = false
  #Prevents a default VPC network being created as it is not needed for this project and it often
  #conflicts with organisation policies due to large attack surface of default settings

  # Cloud Billing API must be on before we can link billing.
  depends_on = [google_project_service.billing_api]

  lifecycle {
    precondition {
      condition = !(var.org_id != null && var.folder_id != null)
      # A project lives under an org OR a folder OR neither (personal account); never both.
      error_message = "Set at most one of org_id or folder_id (or neither, for a personal account with no organization)."
    }
  }
}
