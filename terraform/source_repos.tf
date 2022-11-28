resource "google_sourcerepo_repository" "acm-repo" {
  name = "acm-repo"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
