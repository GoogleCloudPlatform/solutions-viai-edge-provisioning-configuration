# Copyright 2021 Google LLC
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
variable "anthos_target_cluster_membership" {
  type = list
  description = "Anthos Membership name of the target environment."
}

variable "google_default_region" {
  type = string
  description = "The default Google Cloud region."
}

variable "google_viai_project_id" {
  type = string
  description = "Google Cloud project ID."
}
