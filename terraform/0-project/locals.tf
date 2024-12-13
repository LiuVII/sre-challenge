# terraform/0-project/locals.tf
locals {
  project_name = "sre-challenge"
  region       = "europe-west1"

  subnet_name_prod                = "${google_project.todo_app.name}-subnet-prod"
  subnet_pods_range_name_prod     = "pods-prod"
  subnet_services_range_name_prod = "services-prod"

  subnet_name_staging                = "${google_project.todo_app.name}-subnet-staging"
  subnet_pods_range_name_staging     = "pods-staging"
  subnet_services_range_name_staging = "services-staging"
}
