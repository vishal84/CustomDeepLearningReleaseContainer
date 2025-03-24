# Set the notebook file name with the semantic version suffix
locals {
  full_notebook_name = "${var.notebook_name}.ipynb"
}

resource "google_project_service" "tlf" {
  ## https://developer.hashicorp.com/terraform/language/functions/toset
  ## Removes duplicates
  for_each = toset(var.api_services)

  project = var.gcp_project_id
  service = each.key

  disable_dependent_services = false
}

# Reference:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "gcs_bucket" {
  name          = var.gcp_project_id
  location      = var.gcp_region
  project       = var.gcp_project_id
  storage_class = "STANDARD"
  force_destroy = true
}

// Create a post startup script for the Workbench instance
resource "local_file" "notebook_config" {
  content  = <<EOF
  #!/bin/bash -e
  echo "STARTUP-SCRIPT: START"
  # Copy the notebook and requirements.txt files from the storage bucket
  /usr/bin/gsutil cp gs://${google_storage_bucket.gcs_bucket.name}/${local.full_notebook_name} /home/jupyter/${local.full_notebook_name}
  /usr/bin/gsutil cp gs://${google_storage_bucket.gcs_bucket.name}/requirements.txt /home/jupyter/
  # Install required python packages
  pip install --upgrade --no-warn-conflicts --no-warn-script-location -r /home/jupyter/requirements.txt
  echo "STARTUP-SCRIPT: END"
  EOF
  filename = "post_startup_script.sh"
}
