# terraform/1-environments/prod/main.tf
module "project" {
  source = "../../modules/baseline"

  env_tier = "p"
}
