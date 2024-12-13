# terraform/0-project/artifact-registry.tf
resource "google_artifact_registry_repository" "todo_app" {
  project       = google_project.todo_app.project_id
  location      = local.region
  repository_id = "${google_project.todo_app.name}-repository"
  description   = "Docker repository for application images"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false # Allow tag updates for development
  }

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 3
    }
  }
}
