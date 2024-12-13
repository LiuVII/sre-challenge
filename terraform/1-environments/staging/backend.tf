# terraform/1-environments/staging/backend.tf
terraform {
  backend "gcs" {
    bucket = "sre-challenge-b71f132d-tf-state"
    prefix = "terraform/environments/staging"
  }
}
