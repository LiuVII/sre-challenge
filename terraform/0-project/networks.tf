# terraform/0-project/networks.tf
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"

  project_id   = google_project.todo_app.project_id
  network_name = "${google_project.todo_app.name}-network"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = local.subnet_name_prod
      subnet_ip             = "10.0.0.0/20"
      subnet_region         = local.region
      subnet_private_access = true
    },
    {
      subnet_name           = local.subnet_name_staging
      subnet_ip             = "10.10.0.0/20"
      subnet_region         = local.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    (local.subnet_name_prod) = [
      {
        range_name    = "pods-prod"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "services-prod"
        ip_cidr_range = "10.2.0.0/16"
      }
    ]
    (local.subnet_name_staging) = [
      {
        range_name    = "pods-staging"
        ip_cidr_range = "10.11.0.0/16"
      },
      {
        range_name    = "services-staging"
        ip_cidr_range = "10.12.0.0/16"
      }
    ]
  }
}
