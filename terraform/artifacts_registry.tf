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

resource "google_artifact_registry_repository" "viai-mode-repository" {
  location      = var.google_default_region
  repository_id = "${var.google_default_region}-viai-models"
  description   = "Visual Inspection AI model artifact registry"
  format        = "DOCKER"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

resource "google_artifact_registry_repository" "viai-application-repository" {
  location      = var.google_default_region
  repository_id = "${var.google_default_region}-viai-applications"
  description   = "Visual Inspection AI applications container image registry"
  format        = "DOCKER"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
