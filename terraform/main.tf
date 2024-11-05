terraform {
  backend "gcs" {
    bucket = "anothertest-440718-terraform"
    prefix = "/state/youtube"
  }
}
