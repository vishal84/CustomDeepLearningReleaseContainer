variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to create resources in."
}

variable "gcp_region" {
  type        = string
  description = "Region to create resources in."
}

variable "gcp_zone" {
  type        = string
  description = "Zone to create resources in."
}

variable "api_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "notebooks.googleapis.com",
    "aiplatform.googleapis.com",
    "datacatalog.googleapis.com",
    "visionai.googleapis.com"
  ]
}

variable "workbench_name" {
  type        = string
  description = "Notebook name"
  default     = "vertex-ai-jupyterlab"
}

variable "notebook_name" {
  type        = string
  description = "Notebook name"
  default     = "Build_Your_Own_Small_Language_Model"
}

variable "requirements_file_path" {
  type        = string
  description = "Path to the requirements file"
  default     = "scripts/requirements.txt"
}

variable "machine_type" {
  type        = string
  description = "The accelerator type to attach to the instance."
  default     = "n1-standard-4"
}

variable "accelerator_type" {
  type        = string
  description = "The accelerator type to attach to the instance."
  default     = "NVIDIA_TESLA_T4"
}


