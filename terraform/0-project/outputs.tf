# terraform/0-project/outputs.tf
output "project_id" {
  description = "The ID of the created project"
  value       = google_project.todo_app.project_id
}

output "project_name" {
  description = "The name of the created project"
  value       = google_project.todo_app.name
}

output "project_number" {
  description = "The number of the created project"
  value       = google_project.todo_app.number
}

output "state_bucket_name" {
  description = "The name of the bucket that contains TF state"
  value       = google_storage_bucket.terraform_state.name
}

output "network_config" {
  description = "Network configuration object for environments"
  value = {
    environments = {
      prod = {
        network_name           = module.vpc.network_name
        subnet_name            = local.subnet_name_prod
        pods_ip_range_name     = local.subnet_pods_range_name_prod
        services_ip_range_name = local.subnet_services_range_name_prod
        region                 = local.region
      }
      staging = {
        network_name           = module.vpc.network_name
        subnet_name            = local.subnet_name_staging
        pods_ip_range_name     = local.subnet_pods_range_name_staging
        services_ip_range_name = local.subnet_services_range_name_staging
        region                 = local.region
      }
    }
  }
}

output "artifact_registry" {
  description = "Artifact Registry configuration"
  value = {
    repository_id  = google_artifact_registry_repository.todo_app.repository_id
    location       = google_artifact_registry_repository.todo_app.location
    repository_url = "${google_artifact_registry_repository.todo_app.location}-docker.pkg.dev/${google_project.todo_app.project_id}/${google_artifact_registry_repository.todo_app.repository_id}"
  }
}

output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = module.github_oidc.provider_name
}

output "service_account_email" {
  description = "Service Account email for GitHub Actions"
  value       = google_service_account.github_actions.email
}
