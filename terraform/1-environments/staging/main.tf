# terraform/1-environments/staging/main.tf
module "project" {
  source = "../../modules/baseline"

  env_tier = "s"
  # TODO: enable this once prod is deployed to make sure we catch anythinh new early on
  # gke_release_channel = "RAPID"
}
