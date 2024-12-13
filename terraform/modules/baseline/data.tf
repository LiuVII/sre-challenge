# terraform/modules/baseline/data.tf
data "terraform_remote_state" "project" {
  backend = "gcs"
  config = {
    bucket = "sre-challenge-b71f132d-tf-state"
    prefix = "terraform/project"
  }
}
