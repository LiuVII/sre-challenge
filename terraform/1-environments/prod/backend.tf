# terraform/1-environments/prod/backend.tf
terraform {
  backend "gcs" {
    bucket = "sre-challenge-b71f132d-tf-state"
    prefix = "terraform/environments/prod"
  }
}
