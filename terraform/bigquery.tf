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
