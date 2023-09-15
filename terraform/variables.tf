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
variable "anthos_target_cluster_membership" {
  type        = list
  description = "Anthos Membership name of the target environment."
}

variable "cloud_function_source_path" {
  type        = string
  description = "Cloud Function Source Code Path."
}
variable "google_default_region" {
  type        = string
  description = "The default Google Cloud region."
}

variable "google_default_zone" {
  type        = string
  description = "The default Google Cloud zone."
}

variable "google_viai_project_id" {
  type        = string
  description = "Google Cloud project ID."
}

variable "google_cloud_console_user_email" {
  type        = string
  description = "Google Cloud Console User Email"
}
variable "viai_storage_buckets_location" {
  type        = string
  description = "Location where to create VIAI storage buckets."
}
variable "viai_bigquery_dataset_name" {
  type        = string
  description = "Name of the VIAI model inferencing result Bigquery dataset."
  default     = "inference_results"
}
variable "create_sandbox" {
  type        = string
  description = "Should provision a GCE sandbox machine."
  default     = "false"
}
