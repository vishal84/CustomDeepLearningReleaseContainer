data "google_project" "project" {
  project_id = var.gcp_project_id
}

locals {
  service_account = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_project_service_identity" "ai_platform_service_identity" {
  provider = google-beta

  project = var.gcp_project_id
  service = ["aiplatform.googleapis.com"]
}

# Introduce a JIT delay for API enablement
## Add a Delay before creating a Workbench instance
resource "time_sleep" "wait_identity_delay" {
  create_duration = var.identity_create_duration
  depends_on      = [google_project_service_identity.tlf]
}

resource "google_project_iam_member" "tlf" {
  for_each = {
    for idx, role in ["roles/aiplatform.user", "roles/aiplatform.serviceAgent", "roles/storage.admin"] : idx => {
      member = google_project_service_identity.ai_platform_service_identity.member
      role   = role
    }
  }

  project = var.gcp_project_id
  member  = google_project_service_identity.ai_platform_service_identity.member
  role    = each.value.role
}
