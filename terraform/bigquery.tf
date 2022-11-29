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

module "camera-integration-bigquery" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "5.4.1"
  dataset_id = "viai_edge"
  delete_contents_on_destroy = true
  project_id = var.google_viai_project_id
  location   = var.google_default_region

  tables = [
    {
      expiration_time    = null,
      clustering         = [],
      labels             = {}
      table_id           = var.viai_bigquery_dataset_name,
      range_partitioning = null,
      schema             = file("files/bq_thermal_table_schema.json")
      time_partitioning  = null
    }
  ]

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
