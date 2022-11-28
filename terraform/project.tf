resource "google_project_service" "google-cloud-apis" {
  project = var.google_viai_project_id
  for_each = toset([
    "aiplatform.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "anthos.googleapis.com",
    "anthosaudit.googleapis.com",
    "anthosgke.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "eventarc.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "iap.googleapis.com",
    "monitoring.googleapis.com",
    "networkmanagement.googleapis.com",
    "opsconfigmonitoring.googleapis.com",
    "pubsub.googleapis.com",
    "serviceusage.googleapis.com",
    "sourcerepo.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com"
  ])
  disable_dependent_services = false
  disable_on_destroy         = false
  service                    = each.key
}
data "google_project" "project" {}
