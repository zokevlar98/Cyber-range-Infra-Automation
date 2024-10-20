terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
  credentials = "keys/my-credentials.json"
  project     = var.project_id
  region      = "europe-southwest1"
}

resource "google_storage_bucket" "data-lake-bucket" {
  name          = "${var.project_name}-terra-bucket"
  location      = "EU"
  force_destroy = true

  # Optional, but recommended settings:
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 // days
    }
  }
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "demo_dataset"
  project    = var.project_id
  location   = "EU"
}