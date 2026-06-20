resource "google_project" "blockchain_cash_analysis" {
  name       = "Blockchain Cash Analysis" #human-friendly label shown in console
  project_id = "blockchain-cash-analysis" #what every other resource references, must be globally unique (hyphens only, no underscores)

  billing_account = var.billing_account
  #OJO PROJECTS DO NOT HAVE LOCATION, they are global

  org_id    = var.org_id
  folder_id = var.folder_id

  auto_create_network = false
  #Prevents a default VPC network being created as it is not needed for this project and it often
  #conflicts with organisation policies due to large attack surface of default settings

  # Cloud Billing API must be on (in the launchpad project) before we can link billing.
  depends_on = [google_project_service.billing_api]

  lifecycle {
    precondition {
      condition = !(var.org_id != null && var.folder_id != null)
      #Allow AT MOST ONE parent: reject only the genuinely broken case where both
      #org_id and folder_id are set (a project can sit under an org OR a folder, never both).
      #Both-null is now permitted on purpose: a personal account with no organization has
      #neither an org nor a folder, so the project is created as a standalone (no-parent) project.
      #OJO always refer to variables with .var even if defined within same resource block
      error_message = "Set at most one of org_id or folder_id (or neither, for a personal account with no organization)."
    }
  }
}
