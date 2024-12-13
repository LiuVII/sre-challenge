# terraform/modules/baseline/iam.tf
resource "google_service_account" "gke_sa" {
  project      = local.project_id
  account_id   = "${local.project_name}-gke-sa-${var.env_tier}"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])

  project = local.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Workload identity IAM
resource "google_service_account" "workload_identity" {
  project      = local.project_id
  account_id   = "${local.project_name}-workload-${var.env_tier}"
  display_name = "GKE Workload Identity SA"
}

resource "google_project_iam_member" "workload_identity_roles" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/monitoring.metricWriter"
  ])

  project = local.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workload_identity.email}"
}
