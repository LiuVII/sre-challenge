# terraform/1-environments/staging/provider.tf
provider "google" {
  request_timeout = "60s"
}

provider "google-beta" {
  request_timeout = "60s"
}
