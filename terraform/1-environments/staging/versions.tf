# terraform/1-environments/staging/versions.tf
terraform {
  required_version = "~> 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.13"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.13"
    }
  }
}
