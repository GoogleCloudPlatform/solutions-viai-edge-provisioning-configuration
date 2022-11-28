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

module "gce_vm" {
  google_default_region             = var.google_default_region
  google_default_zone               = var.google_default_zone
  google_viai_project_id            = var.google_viai_project_id
  source                            = "./gce-vm"
  count                             = var.create_sandbox == "true" ? 1 : 0
  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
