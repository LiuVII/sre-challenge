# terraform/modules/baseline/versions.tf
terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13"
    }
  }
}