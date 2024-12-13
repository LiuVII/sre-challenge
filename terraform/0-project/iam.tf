# terraform/0-project/iam.tf
# IAM for external users to play with deployed cluster
resource "google_project_iam_member" "project_editor" {
  for_each = toset([
    # "jordan@gorgias.com"
  ])

  project = google_project.todo_app.project_id
  role    = "roles/editor"
  member  = "user:${each.value}"
}
