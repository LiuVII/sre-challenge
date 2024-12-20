# terraform/modules/baseline/variables.tf
variable "env_tier" {
  description = "Environment tier to use for resource names and labels"
  type        = string
}

variable "gke_release_channel" {
  description = "The release channel of the GKE cluster"
  type        = string
  default     = "REGULAR"
}

variable "k8s_namespace" {
  description = "k8s namespace that contains app"
  type        = string
  default     = "todo-app"
}
