module "model_deployment_pipeline" {
  anthos_target_cluster_membership  = var.anthos_target_cluster_membership
  google_default_region             = var.google_default_region
  google_viai_project_id            = var.google_viai_project_id
  source                            = "./model-deployment-pipeline"

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
