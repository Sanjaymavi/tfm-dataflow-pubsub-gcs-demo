############ Bucket Creation Code

resource "google_storage_bucket" "data_bucket" {
  name                        = "sanjay-demo-data-bucket-001"
  location                    = "ASIA"
  uniform_bucket_level_access = true
  project                     = var.project_id

  versioning {
    enabled = true
  }
}

########## Artifact Registry Code

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "docker-repo"
  description   = "Docker images repository"
  format        = "DOCKER"
  project       = var.project_id
}

######## VPC Code

resource "google_compute_network" "vpc" {
  name                    = "demo-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

######## subnet Code

resource "google_compute_subnetwork" "subnet" {
  name          = "demo-subnet"
  ip_cidr_range = "10.10.0.0/24"
  project       = var.project_id

  region  = var.region
  network = google_compute_network.vpc.id
}


########## Firewall code

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}



########## Virtual machine code

resource "google_compute_instance" "vm" {
  name         = "terraform-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }

  tags = ["ssh"]
}

############ GKE Cluster

resource "google_container_cluster" "gke" {
  name     = "demo-gke-cluster"
  location = var.region
  project  = var.project_id

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1
}

######## Node Pool

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.gke.name
  location = var.region
  project  = var.project_id

  node_count = 1

  node_config {
    machine_type = "e2-small"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}