# --- CLOUD SQL (POSTGRES) ---

resource "google_sql_database_instance" "postgres" {
  name             = "${var.app_name}-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Smallest tier to keep costs low during dev
    
    ip_configuration {
      ipv4_enabled    = true
      # This allows Cloud Run to connect securely
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0" 
      }
    }
  }
  deletion_protection = false # Set to true for production!
}

resource "google_sql_database" "database" {
  name     = "rag_memory"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "users" {
  name     = "rag_admin"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
