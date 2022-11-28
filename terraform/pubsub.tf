module "camera_integration_pubsub" {
  project_id = var.google_viai_project_id
  source     = "terraform-google-modules/pubsub/google"
  topic      = "camera-integration"
  version    = "4.0.1"
  message_storage_policy = {
    allowed_persistence_regions = [
      var.google_default_region
    ]
  }
  push_subscriptions = [
    {
      name          = "camera-integration-sub"
      push_endpoint = ""
    }
  ]

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

module "camera_integration_telemetry_pubsub" {
  project_id = var.google_viai_project_id
  source     = "terraform-google-modules/pubsub/google"
  topic      = "camera-integration-telemetry"
  version    = "4.0.1"
  message_storage_policy = {
    allowed_persistence_regions = [
      var.google_default_region
    ]
  }
  push_subscriptions = [
    {
      name          = "camera-integration-telemetry-sub"
      push_endpoint = ""
    }
  ]

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

module "camera_integration_device_state_pubsub" {
  project_id = var.google_viai_project_id
  source     = "terraform-google-modules/pubsub/google"
  topic      = "camera-integration-device-state"
  version    = "4.0.1"
  message_storage_policy = {
    allowed_persistence_regions = [
      var.google_default_region
    ]
  }
  push_subscriptions = [
    {
      name          = "camera-integration-device-state-sub"
      push_endpoint = ""
    }
  ]

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}

# Container Registry and Artifacts Registrt notification
# Topic name must be gcr
# * https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/configure-sa#logmon-config-sa
module "container_images_notifications_pubsub" {
  project_id = var.google_viai_project_id
  source     = "terraform-google-modules/pubsub/google"
  topic      = "gcr"
  version    = "4.0.1"

  push_subscriptions = [
    {
      name          = "gcr-sub"
      push_endpoint = ""
    }
  ]

  depends_on = [
    google_project_service.google-cloud-apis
  ]
}
