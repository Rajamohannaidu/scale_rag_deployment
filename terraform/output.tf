output "backend_url" {
  value = google_cloud_run_v2_service.backend.uri
}

output "ui_url" {
  value = google_cloud_run_v2_service.ui.uri
}

output "db_public_ip" {
  value = google_sql_database_instance.postgres.public_ip_address
}

output "artifact_repo" {
  value = google_artifact_registry_repository.repo.name
}
