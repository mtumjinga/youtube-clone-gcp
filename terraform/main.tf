terraform {
  backend "gcs" {
    bucket = "banded-meridian-435911-g6-terraform"#change the project id
    prefix = "/state/youtube"
  }
}