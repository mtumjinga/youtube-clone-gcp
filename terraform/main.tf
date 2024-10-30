terraform {
  backend "gcs" {
    bucket = "banded-meridian-435911-g6-terraform"
    prefix = "/state/youtube"
  }
}