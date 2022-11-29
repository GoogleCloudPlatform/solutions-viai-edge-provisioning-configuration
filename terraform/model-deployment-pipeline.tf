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

module "model_deployment_pipeline" {
  anthos_target_cluster_membership  = var.anthos_target_cluster_membership
  google_default_region             = var.google_default_region
  google_viai_project_id            = var.google_viai_project_id
  source                            = "./model-deployment-pipeline"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
