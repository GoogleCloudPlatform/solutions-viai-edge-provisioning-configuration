# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_service_account" "viai-camera-integration-client" {
  account_id   = "viai-camera-integration-client"
  display_name = "VIAI camera integration client"
  description  = "Camera integration client access to Google Cloud backend services for Visual Inspection AI Intelligent Edge"
}
resource "google_service_account_key" "viai-camera-integration-client_service_account_key" {
  service_account_id = google_service_account.viai-camera-integration-client.name
  depends_on = [
    google_service_account.viai-camera-integration-client
  ]
}

resource "local_file" "viai-camera-integration-client-service-account-key-json" {
  content  = base64decode(google_service_account_key.viai-camera-integration-client_service_account_key.private_key)
  filename = "${path.module}/../tmp/viai-camera-integration-client_service_account_key-service-account-key.json"
  depends_on = [
    google_service_account_key.viai-camera-integration-client_service_account_key
  ]
}

resource "google_service_account" "viai-cloud-deploy" {
  account_id   = "viai-cloud-deploy-sa"
  display_name = "Visual Inspection AI Cloud Deplpy Service Account"
}

resource "google_project_iam_member" "viai-cloud-deploy-serviceAccountUser" {
  project = var.google_viai_project_id
  for_each = toset([
    "roles/clouddeploy.jobRunner",
    "roles/container.developer"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.viai-cloud-deploy.email}"
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

resource "google_project_iam_member" "viai-camera-integration-client-pubsub-publisher" {
  project = var.google_viai_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.viai-camera-integration-client.email}"
}

# service account for anthos bare metal to communicate with cloud backend
resource "google_service_account" "anthos_device_service_account" {
  account_id   = "viai-abm-service"
  display_name = "Anthos Baremetal Service Account"
  depends_on = [
    google_project_service.google-cloud-apis
  ]
  project = var.google_viai_project_id
}

resource "google_service_account_key" "anthos_device_service_account_key" {
  service_account_id = google_service_account.anthos_device_service_account.name
  depends_on = [
    google_service_account.anthos_device_service_account
  ]
}

resource "google_project_iam_member" "anthos-bare-metal-serviceAccountUser" {
  project = var.google_viai_project_id
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/iam.serviceAccountUser",
    "roles/gkehub.gatewayAdmin",
    "roles/gkehub.viewer",
    "roles/container.viewer",
    "roles/storage.admin",
    "roles/source.admin",
    "roles/cloudfunctions.admin",
    "roles/iam.securityAdmin",
    "roles/pubsub.admin"
  ])
  role   = each.key
  member = "user:${var.google_cloud_console_user_email}"
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
################################################
# Anthos Service Required Roles
# Ref: https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/reference/cluster-config-ref
# ==============================================
# * Reads and Writes to Artifact Registry, not necessary for Anthos Bare Metal.
#   For container images access, not required by Anthos.
#   - "roles/artifactregistry.reader",
#   - "roles/artifactregistry.writer",
# * For logging monitoring
#   https://cloud.google.com/anthos/clusters/docs/on-prem/1.11/how-to/service-accounts
#   - roles/stackdriver.resourceMetadata.writer
#   - roles/opsconfigmonitoring.resourceMetadata.writer
#   - roles/logging.logWriter
#   - roles/monitoring.metricWriter
#   - roles/monitoring.dashboardEditor
# * The connect register service account must be granted the gkehub.admin
#   https://cloud.google.com/anthos/clusters/docs/on-prem/1.11/how-to/service-accounts
#   https://cloud.google.com/anthos/clusters/docs/on-prem/latest/release-notes
#   - roles/gkehub.editor
# * To register a cluster in a fleet
#   https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/configure-sa
#   - roles/gkehub.admin
# * To connect to fleets
#   https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/configure-sa
#   - roles/gkehub.connect
# * Some registration options outside Google Cloud require you to set up a service account
#   for the cluster to use to authenticate to Google instead of Workload Identity.
#   https://cloud.google.com/anthos/fleet-management/docs/before-you-begin#grant_iam_roles
#   - roles/gkehub.admin
#   - roles/iam.serviceAccountAdmin
#   - roles/iam.serviceAccountKeyAdmin
#   - roles/resourcemanager.projectIamAdmi
# * Set up connect gateway
#   https://cloud.google.com/anthos/multicluster-management/gateway/setup
#   - roles/serviceusage.serviceUsageAdmin
#   - roles/resourcemanager.projectIamAdmin
# * Minimally, users and service accounts need the following IAM roles to use kubectl to interact with clusters through the Connect gateway, unless the user has roles/owner in the project
#   https://cloud.google.com/anthos/multicluster-management/gateway/setup
#   - roles/gkehub.gatewayAdmin
#   - roles/gkehub.viewer
# * Grante access through the GCP console
#   https://cloud.google.com/anthos/multicluster-management/gateway/setup#grant_roles_for_access_through_the_cloud_console
#   - roles/container.viewer
#   - roles/gkehub.viewer
# * Grant access to push/pull from Google Container Registry
#   https://cloud.google.com/container-registry/docs/access-control
#   - roles/storage.objectViewer",
#   - roles/storage.admin",
# * The service account used to install Anthos have to login to gcloud, which is required to have compute.viewer role
#   https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/configure-sa#logmon-config-sa\
#   - roles/compute.viewers
#   - "roles/iam.serviceAccountAdmin",
#   - "roles/iam.serviceAccountKeyAdmin",
#   - "roles/resourcemanager.projectIamAdmin",
#   - "roles/serviceusage.serviceUsageAdmin",
# ==============================================
# "roles/compute.admin"
# "roles/compute.serviceAgent",
# "roles/iam.serviceAccountUser"
# "roles/source.reader",
# "roles/source.writer",
# "roles/storage.objectAdmin",
################################################
resource "google_project_iam_binding" "anthos_service_account-iam-register" {
  project = var.google_viai_project_id
  for_each = toset([
    # Reads and Writes to Artifact Registry, not necessary for Anthos Bare Metal
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
    "roles/compute.viewer",
    "roles/container.viewer",
    "roles/gkehub.connect",
    "roles/gkehub.editor",
    "roles/gkehub.gatewayAdmin",
    "roles/gkehub.viewer",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.dashboardEditor",
    "roles/opsconfigmonitoring.resourceMetadata.writer",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/storage.admin",
  ])
  role = each.key

  members = [
    "serviceAccount:${google_service_account.anthos_device_service_account.email}"
  ]
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
resource "google_project_iam_binding" "cloud_functions_service_agent_iam-binding" {
  project = var.google_viai_project_id
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.user"
  ])
  role = each.key

  members = [
    "serviceAccount:${var.google_viai_project_id}@appspot.gserviceaccount.com"
  ]
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

# Service account key file will be created and downloaded when deploying camrea applications.
resource "local_file" "service-account-key-json" {
  content  = base64decode(google_service_account_key.anthos_device_service_account_key.private_key)
  filename = "${path.module}/../tmp/service-account-key.json"
  depends_on = [
    google_service_account_key.anthos_device_service_account_key
  ]
}

# service account for EventArc/Workflow
# Required Role: https://cloud.google.com/eventarc/docs/workflows/create-triggers#pubsub-messages
resource "google_service_account" "viai-mode-deploy_service_account" {
  account_id   = "viai-model-deploy-service"
  display_name = "VIAI Model deploy Service Account"
  depends_on = [
    google_project_service.google-cloud-apis
  ]
  project = var.google_viai_project_id
}

# Permissions for Workflows
# https://cloud.google.com/workflows/docs/authentication#sa-permissions
# https://cloud.google.com/deploy/docs/iam-roles-permissions
resource "google_project_iam_member" "viai-mode-deploy" {
  project = var.google_viai_project_id
  for_each = toset([
    "roles/eventarc.eventReceiver",
    "roles/workflows.invoker",
    "roles/eventarc.serviceAgent",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/clouddeploy.releaser"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.viai-mode-deploy_service_account.email}"
  depends_on = [
    google_project_service.google-cloud-apis
  ]

}
