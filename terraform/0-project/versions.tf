# terraform/0-bootstrap/versions.tf
terraform {
  required_version = "~> 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
