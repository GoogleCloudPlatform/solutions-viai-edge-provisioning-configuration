resource "google_container_registry" "registry" {
  project  = var.google_viai_project_id
  location = var.viai_storage_buckets_location

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
