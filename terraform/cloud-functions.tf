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

resource "google_storage_bucket_object" "archive" {
  name   = "cloud-function-${formatdate("YYYY-M-DD-hh-mm", timestamp())}.zip"
  bucket = module.viai_cloud_functions_source_gcs_buckets.name
  source = var.cloud_function_source_path
  depends_on = [
    module.viai_cloud_functions_source_gcs_buckets
  ]
}

resource "google_cloudfunctions_function" "function" {
  name        = "viai-edge-bigquery-integration"
  description = "VIAI Edge BigQuery integration, ingests telemetry from Cloud Pub/Sub to BigQuery"
  runtime     = "python37"
  region      = var.google_default_region

  available_memory_mb   = 512
  source_archive_bucket = module.viai_cloud_functions_source_gcs_buckets.name
  source_archive_object = google_storage_bucket_object.archive.name
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = module.camera_integration_telemetry_pubsub.topic
  }
  entry_point = "pubsub_bigquery_inference_results"
  environment_variables = {
    BIGQUERY_DATASET = module.camera-integration-bigquery.bigquery_dataset.dataset_id
    BIGQUERY_TABLE   = "inference_results"
  }
  depends_on = [
    google_project_service.google-cloud-apis,
    google_storage_bucket_object.archive
  ]
}
