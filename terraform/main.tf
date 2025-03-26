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

# Create a post startup script for the Workbench instance
resource "local_file" "notebook_config" {
  content  = <<EOF
  #!/bin/bash -e
  apt-get update && apt-get install -y gsutil

  echo "STARTUP-SCRIPT: START"
  # Copy the notebook and requirements.txt files from the storage bucket
  /usr/bin/gsutil cp gs://${google_storage_bucket.gcs_bucket.name}/${local.full_notebook_name} /home/jupyter/${local.full_notebook_name}
  /usr/bin/gsutil cp gs://${google_storage_bucket.gcs_bucket.name}/requirements.txt /home/jupyter/
  # Install required python packages
  # pip install --upgrade --no-warn-conflicts --no-warn-script-location -r /home/jupyter/requirements.txt
  echo "STARTUP-SCRIPT: END"
  EOF
  filename = "post_startup_script.sh"
}

# Add the local notebook file to the Cloud Storage bucket
resource "google_storage_bucket_object" "notebook_file" {
  name   = local.full_notebook_name
  source = "notebooks/${var.notebook_name}.ipynb"
  bucket = google_storage_bucket.gcs_bucket.name
}

// Add the startup script to the Cloud Storage bucket
resource "google_storage_bucket_object" "post_startup_script" {
  name   = "post_startup_script.sh"
  source = "post_startup_script.sh"
  bucket = google_storage_bucket.gcs_bucket.name
  depends_on = [
    local_file.notebook_config,
    google_storage_bucket_object.notebook_file
  ]
}

resource "google_workbench_instance" "custom_container_instance" {
  name     = "custom-container-instance"
  location = var.gcp_zone

  gce_setup {
    machine_type = "n1-standard-4" // cant be e2 because of accelerator

    shielded_instance_config {
      enable_secure_boot          = true
      enable_vtpm                 = true
      enable_integrity_monitoring = true
    }

    accelerator_configs {
      type       = "NVIDIA_TESLA_T4"
      core_count = 1
    }

    container_image {
      repository = "gcr.io/${var.gcp_project_id}/workbench-custom"
      tag        = "latest"
    }

    boot_disk {
      disk_size_gb = 200
      disk_type    = "PD_SSD"
    }

    data_disks {
      disk_size_gb = 200
      disk_type    = "PD_SSD"
    }

    enable_ip_forwarding = true
    metadata = {
      post-startup-script          = "gs://${module.lab_config_bucket.gcs_bucket_name}/post_startup_script.sh"
      post-startup-script-behavior = "run_every_start"
    }
  }

  disable_proxy_access = false
  desired_state        = "ACTIVE"

  depends_on = [module.la_api_batch, google_storage_bucket_object.notebook_config_script]

  timeouts {
    create = "60m"
    update = "30m"
    delete = "30m"
  }
}
