output "bucket_name" {
  value = google_storage_bucket.data_bucket.name
}

output "artifact_registry" {
  value = google_artifact_registry_repository.docker_repo.repository_id
}

output "vm_external_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "gke_cluster_name" {
  value = google_container_cluster.gke.name
}