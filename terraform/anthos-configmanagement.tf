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
