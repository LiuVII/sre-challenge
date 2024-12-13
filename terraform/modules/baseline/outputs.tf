# terraform/modules/baseline/outputs.tf
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.name
}

output "workload_identity_email" {
  description = "The email address of the Workload Identity service account used by GKE workloads"
  value       = google_service_account.workload_identity.email
}

output "app_static_ip" {
  description = "The global static IP address for accessing the application"
  value       = google_compute_global_address.todo_app.address
}
