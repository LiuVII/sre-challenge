resource "google_kms_key_ring" "gke" {
  name     = "gke-keyring"
  location = "europe-west1"
  project  = local.project_id
}

resource "google_kms_crypto_key" "gke" {
  name     = "gke-key"
  key_ring = google_kms_key_ring.gke.id
}

resource "google_kms_crypto_key_iam_binding" "gke" {
  crypto_key_id = google_kms_crypto_key.gke.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:service-${data.terraform_remote_state.project.outputs.project_number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:${google_service_account.gke_sa.email}"
  ]
}
