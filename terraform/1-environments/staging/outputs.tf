# terraform/1-environments/staging/outputs.tf
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.project.cluster_name
}

output "app_static_ip" {
  description = "The global static IP address for accessing the application"
  value       = module.project.app_static_ip
}
