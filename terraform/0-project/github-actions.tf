# terraform/0-project/github-actions.tf
locals {
  github_repo = "LiuVII/sre-challenge"
}

resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  project      = google_project.todo_app.project_id
  display_name = "Service Account for GitHub Actions"
}

resource "google_project_iam_member" "github_actions_iam" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountTokenCreator",
  ])

  project = google_project.todo_app.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

module "github_oidc" {
  source  = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  version = "4.0.0"

  project_id  = google_project.todo_app.project_id
  pool_id     = "github-actions-pool"
  provider_id = "github-actions-provider"

  sa_mapping = {
    (google_service_account.github_actions.account_id) = {
      sa_name   = google_service_account.github_actions.name
      attribute = "attribute.repository/${local.github_repo}"
    }
  }

  attribute_condition = "attribute.repository == \"${local.github_repo}\""
}
