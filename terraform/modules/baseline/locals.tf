# terraform/modules/baseline/locals.tf
locals {
  project_id   = data.terraform_remote_state.project.outputs.project_id
  project_name = data.terraform_remote_state.project.outputs.project_name
}
