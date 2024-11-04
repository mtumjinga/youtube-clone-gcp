### GCP
variable "gcp_project_id" {
  type = string
}

variable "gcp_machine_type" {
  type = string
}

variable "domain_name" {
  description = "Domain name for SSL and DNS configuration"
  type        = string
}

### General
variable "app_name" {
  type = string
}

