# To enable EventArc notifications for GCR and Artifact Repositories
# Should enable pubsub.googleapis.com and artifactregistry.googleapis.com for automation.
resource "google_project_iam_audit_config" "project_audit" {
    project = var.google_viai_project_id
    service = "allServices"
    audit_log_config {
        log_type = "ADMIN_READ"
    }
    audit_log_config {
        log_type = "DATA_WRITE"
    }
    audit_log_config {
        log_type = "DATA_READ"
    }
}
