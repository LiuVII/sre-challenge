# terraform/modules/baseline/networks.tf
# Global static IP for ingress
resource "google_compute_global_address" "todo_app" {
  name         = "${local.project_name}-ip-${var.env_tier}"
  project      = local.project_id
  description  = "Global static IP for todo-app ingress"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
