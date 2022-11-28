locals {
  viai_model_training_data_bucket_name = "model-training-data"
  cloud_function_source_bucket_name = "viai-cloud-function-src"
}
# For storing Cloud build and Cloud Deploy assets
module "cloud_build_gcs_buckets" {
  location         = var.viai_storage_buckets_location
  names            = [
    "${var.google_viai_project_id}_cloudbuild"
  ]
  project_id       = var.google_viai_project_id
  prefix           = ""
  randomize_suffix = false
  source           = "terraform-google-modules/cloud-storage/google"
  version          = "3.4.0"
  force_destroy    = {
    ("${var.google_viai_project_id}_cloudbuild") = true
  }

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
module "viai_gcs_buckets" {
  location         = var.viai_storage_buckets_location
  names            = [local.viai_model_training_data_bucket_name]
  project_id       = var.google_viai_project_id
  prefix           = ""
  randomize_suffix = true
  source           = "terraform-google-modules/cloud-storage/google"
  version          = "3.4.0"

  force_destroy = {
    (local.viai_model_training_data_bucket_name) = true
  }

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

######################################################
# This bucket is used by Cloud Functions Deployment
######################################################
module "viai_cloud_functions_source_gcs_buckets" {
  location         = var.viai_storage_buckets_location
  names            = [local.cloud_function_source_bucket_name]
  project_id       = var.google_viai_project_id
  prefix           = ""
  randomize_suffix = true
  source           = "terraform-google-modules/cloud-storage/google"
  version          = "3.4.0"
  force_destroy = {
    (local.cloud_function_source_bucket_name) = true
  }
  depends_on = [
    module.cloud_build_gcs_buckets
  ]
}

resource "google_storage_bucket_object" "service_yaml_folder"{
    name   = "viai-models/"
    content = "FOR VIAI MODEL MANIFEST FILES"
    bucket = "${var.google_viai_project_id}_cloudbuild"
    depends_on = [
      module.cloud_build_gcs_buckets
  ]
}
