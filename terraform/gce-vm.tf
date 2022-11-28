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
