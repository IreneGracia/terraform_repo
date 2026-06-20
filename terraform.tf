terraform {

  required_version = ">= 1.10.0" # >= 1.10 needed for ephemeral input variables (github_token)

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # State is kept LOCAL (terraform.tfstate) for this single-environment challenge
  # — it keeps the project runnable with a plain `terraform init` and no external
  # bootstrap. For a real multi-environment, multi-engineer setup you'd switch to
  # a remote backend (e.g. GCS) with state locking and per-environment isolation.
  # The local state files are git-ignored (see .gitignore).
}
