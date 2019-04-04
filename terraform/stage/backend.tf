terraform {
  required_version = ">=0.11,<0.12"

  backend "gcs" {
    bucket = "tennki-storage-bucket"
    prefix = "stage"
  }
}

