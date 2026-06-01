provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
