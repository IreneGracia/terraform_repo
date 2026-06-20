# No `project` is set here: this config *creates* the project, and every resource
# sets its own `project` explicitly, so there is no sensible default to pin.
provider "google" {
  region = var.region
}


provider "github" {
  owner = var.github_owner
  token = var.github_token
}
