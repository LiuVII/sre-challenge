# terraform/modules/baseline/gke.tf
locals {
  network_config = var.env_tier == "p" ? (
    data.terraform_remote_state.project.outputs.network_config.environments.prod
    ) : (
    data.terraform_remote_state.project.outputs.network_config.environments.staging
  )
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "~> 34.0"

  project_id = local.project_id
  name       = "${local.project_name}-cluster-${var.env_tier}"
  region     = local.network_config.region
  # Note: this could've been done more intelligently but we'll keep it like this for simplicity
  zones           = ["europe-west1-b", "europe-west1-c"]
  network         = local.network_config.network_name
  subnetwork      = local.network_config.subnet_name
  service_account = google_service_account.gke_sa.email

  # Note: we'd control extra maintenance window to make sure the cluster in not under maintenance when we really need it
  release_channel = var.gke_release_channel

  ip_range_pods          = local.network_config.pods_ip_range_name
  ip_range_services      = local.network_config.services_ip_range_name
  master_ipv4_cidr_block = "172.16.0.0/28"
  enable_private_nodes   = true
  # TODO: make it private after initial development
  enable_private_endpoint = false

  # TODO: restrict after initial development
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0" # Temporary for development
      display_name = "Temporary public access"
      # cidr_block   = "10.0.0.0/8" # Adjust to your admin IP range
      # display_name = "Admin Network"
    }
  ]

  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke.id
  }]

  enable_vertical_pod_autoscaling = true
  horizontal_pod_autoscaling      = true

  remove_default_node_pool = true
  node_pools = [
    {
      name         = "system-pool"
      machine_type = "e2-small"
      min_count    = 1
      max_count    = 1
      disk_size_gb = 10
      disk_type    = "pd-standard"
      auto_repair  = true
      auto_upgrade = true
      preemptible  = false
      spot         = false
    },
    {
      name         = "db-pool"
      machine_type = "e2-small"
      min_count    = 1 # Will give us 2 nodes total (1 per zone)
      max_count    = 1
      disk_size_gb = 20
      disk_type    = "pd-ssd" # SSD for better DB performance
      auto_repair  = true
      auto_upgrade = true
      preemptible  = false
      spot         = false
    },
    {
      name         = "app-pool"
      machine_type = "e2-small"
      min_count    = 1 # Will give us 2 nodes total (1 per zone)
      max_count    = 4 # Scale based on load
      disk_size_gb = 20
      disk_type    = "pd-standard"
      auto_repair  = true
      auto_upgrade = true
      preemptible  = false
      spot         = true
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only", # For pulling images
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/cloud-platform" # For Artifact Registry
    ]
  }

  node_pools_labels = {
    all = {}
    system-pool = {
      workload = "system"
    }
    db-pool = {
      workload = "database"
    }
    app-pool = {
      workload = "application"
    }
  }

  node_pools_taints = {
    system-pool = [{
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "PREFER_NO_SCHEDULE"
    }]
    db-pool = [{
      key    = "workload"
      value  = "database"
      effect = "NO_SCHEDULE"
    }]
    app-pool = [{
      key    = "workload"
      value  = "application"
      effect = "NO_SCHEDULE"
    }]
  }
}
