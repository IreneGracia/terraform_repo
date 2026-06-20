
# Provider configuration: the google and github providers used to create this project's resources.
provider "google" {
  region = var.region
}


provider "github" {
  owner = var.github_owner
  token = var.github_token
}
