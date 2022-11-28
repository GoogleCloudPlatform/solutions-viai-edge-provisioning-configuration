resource "google_artifact_registry_repository" "viai-mode-repository" {
  location      = var.google_default_region
  repository_id = "${var.google_default_region}-viai-models"
  description   = "Visual Inspection AI model artifact registry"
  format        = "DOCKER"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
