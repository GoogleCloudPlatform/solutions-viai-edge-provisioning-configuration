resource "google_gke_hub_feature" "feature" {
  name = "configmanagement"
  location = "global"
  provider = google-beta
  project = var.google_viai_project_id
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

resource "google_service_account" "acm-repo-reader" {
  account_id   = "viai-acm-repo-reader"
  display_name = "Visual Inspection AI Edge ACM Source Repository Reader"
  project = var.google_viai_project_id
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

resource "google_project_iam_member" "acm-repo-reader" {
  project = var.google_viai_project_id
  role   = "roles/source.reader"
  member =  "serviceAccount:${google_service_account.acm-repo-reader.email}"
  depends_on = [
    google_service_account.acm-repo-reader
  ]
}
