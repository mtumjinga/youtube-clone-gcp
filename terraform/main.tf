terraform {
  backend "gcs" {
    bucket = "${gcp_project_id}-terraform"
    prefix = "/state/youtube"
  }
}