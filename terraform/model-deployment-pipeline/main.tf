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

resource "google_clouddeploy_delivery_pipeline" "delivery_pipeline"{
    for_each    = toset(var.anthos_target_cluster_membership)
    location    = var.google_default_region
    name        = "${var.google_viai_project_id}-${each.key}"
    description = "${each.key} delivery pipeline."
    project     = var.google_viai_project_id
    serial_pipeline {
        stages {
            profiles  = []
            target_id = google_clouddeploy_target.dev[each.key].name
        }
    }
}

resource "google_clouddeploy_target" "dev" {
    for_each    = toset(var.anthos_target_cluster_membership)
    location        = var.google_default_region
    name            = each.key
    project         = var.google_viai_project_id
    anthos_cluster {
        membership = "projects/${var.google_viai_project_id}/locations/global/memberships/${each.key}"
    }
    require_approval    = false
    execution_configs {
        usages          = [ "RENDER", "DEPLOY" ]
        service_account  = "viai-abm-service@${var.google_viai_project_id}.iam.gserviceaccount.com"
    }
}

resource "google_workflows_workflow" "event-trigger-destination" {
    for_each    = toset(var.anthos_target_cluster_membership)
    name    = "workflow-${each.key}"
    project = var.google_viai_project_id
    region  = var.google_default_region
    source_contents = <<-EOF
main:
  params: [event]
  steps:
    - init:
        assign:
          - project_id: ${var.google_viai_project_id}
          - location_id: ${var.google_default_region}
          - pipeline: ${var.google_viai_project_id}-${each.key}
    - decode_pubsub_message:
        assign:
            - data: $${event.data}
            - action: $${data.protoPayload.methodName}
            - resource_name: $${event.resourceName}
            - image_url_path_array: $${text.split(resource_name, "/")}
            - image_tag: $${image_url_path_array[len(image_url_path_array) - 1]}
            - repository_name: $${image_url_path_array[len(image_url_path_array) - 3]}
            - image_location: $${location_id + "-docker.pkg.dev/" + project_id + "/" + repository_name + "/" + image_tag}
            - target_cluster: ${each.key}
            - time_string: $${text.replace_all(text.replace_all(text.split(time.format(sys.now()), ".")[0], "-", ""), ":", "")}
            - tag_string: $${text.split(image_tag, "@")[0]}
            - requestId: $${text.to_lower(tag_string) + text.to_lower(time_string)}
    - log_variables_action:
        call: sys.log
        args: [$${null}, "INFO", $${action}]
    - log_variables_image_tag:
        call: sys.log
        args: [$${null}, "INFO", $${image_tag}]
    - log_variables_requestid:
        call: sys.log
        args: [$${null}, "INFO", $${requestId}]
    - log_variables_image_location:
        call: sys.log
        args: [$${null}, "INFO", $${image_location}]
    - cloud_deploy:
        call: http.post
        args:
          url: $${"https://clouddeploy.googleapis.com/v1/projects/${var.google_viai_project_id}/locations/${var.google_default_region}/deliveryPipelines/${google_clouddeploy_delivery_pipeline.delivery_pipeline[each.key].name}/releases?releaseId=" + requestId}
          auth:
            type: OAuth2
            scopes: https://www.googleapis.com/auth/cloud-platform
          body:
            buildArtifacts:
              - image: viai-inference-module
                tag: $${image_location}
            skaffoldConfigUri: $${"gs://" + project_id + "_cloudbuild/viai-models/" + tag_string + ".tar.gz" }
            skaffoldConfigPath: /skaffold.yaml
    - the_end:
        return: "SUCCESS"
    EOF
}

resource "google_eventarc_trigger" "artifact_registry_trigger" {
    for_each    = toset(var.anthos_target_cluster_membership)
    location    = var.google_default_region
    name        = "${each.key}-event-trigger"
    project     = var.google_viai_project_id

    matching_criteria {
        attribute = "type"
        value = "google.cloud.audit.log.v1.written"
    }
    matching_criteria {
        attribute = "serviceName"
        value = "artifactregistry.googleapis.com"
    }
    matching_criteria {
        attribute = "methodName"
        value = "Docker-PutManifest"
    }
    matching_criteria {
        attribute   = "resourceName"
        operator    = "match-path-pattern"
        value       = "/projects/${var.google_viai_project_id}/locations/${var.google_default_region}/repositories/${var.google_default_region}-viai-models/dockerImages/*"
    }
    destination {
        workflow = google_workflows_workflow.event-trigger-destination[each.key].id
    }
    service_account = "viai-model-deploy-service@${var.google_viai_project_id}.iam.gserviceaccount.com"
    depends_on = [
        google_workflows_workflow.event-trigger-destination,
        google_clouddeploy_delivery_pipeline.delivery_pipeline
    ]
}
