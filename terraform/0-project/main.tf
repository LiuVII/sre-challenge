# terraform/0-project/main.tf
# Note: comment out this during init
terraform {
  backend "gcs" {
    bucket = "sre-challenge-b71f132d-tf-state"
    prefix = "terraform/project"
  }
}

provider "google" {
  region          = local.region
  request_timeout = "60s"
}

resource "random_id" "project_id" {
  byte_length = 4
  prefix      = "${local.project_name}-"
}

resource "google_project" "todo_app" {
  name            = local.project_name
  project_id      = random_id.project_id.hex
  billing_account = "01F57D-AD05F5-321E4C"

  labels = {
    app = "todo"
  }
}

resource "google_project_service" "apis" {
  for_each = toset([
    "cloudkms.googleapis.com",          # For KMS
    "compute.googleapis.com",           # Compute Engine API
    "container.googleapis.com",         # Kubernetes Engine API
    "servicenetworking.googleapis.com", # Service Networking API
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com", # For federation and OIDC
    "stackdriver.googleapis.com",    # Cloud Monitoring API
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "artifactregistry.googleapis.com", # For container images
    "sts.googleapis.com",              # For OIDC
  ])

  project = google_project.todo_app.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

# Create state bucket
resource "google_storage_bucket" "terraform_state" {
  name          = "${google_project.todo_app.project_id}-tf-state"
  project       = google_project.todo_app.project_id
  location      = "EU"
  force_destroy = false

  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
}
