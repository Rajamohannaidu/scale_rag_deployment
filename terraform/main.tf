# -----------------------------------------------------------------------------
# 1. Enable Required APIs
# -----------------------------------------------------------------------------
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "discoveryengine.googleapis.com",
    "pubsub.googleapis.com",
    "eventarc.googleapis.com",
    "redis.googleapis.com",
    "vpcaccess.googleapis.com",
    "compute.googleapis.com",
    "documentai.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# STAGE 1 BUFFER — Wait for APIs to fully initialize before any resource creation
# GCP API enablement is async; service agents are provisioned lazily after this.
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_for_apis" {
  create_duration = "30s"
  depends_on      = [google_project_service.services]
}

# -----------------------------------------------------------------------------
# 2. Get Project Data
# -----------------------------------------------------------------------------
data "google_project" "project" {
  project_id = var.project_id
}

# -----------------------------------------------------------------------------
# 3. Networking (Required for Redis)
# -----------------------------------------------------------------------------
resource "google_compute_network" "rag_vpc" {
  name                    = "rag-vpc"
  auto_create_subnetworks = true
  depends_on              = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 4. Redis Instance (Memorystore)
# -----------------------------------------------------------------------------
resource "google_redis_instance" "cache" {
  name               = "rag-cache"
  tier               = "BASIC"
  memory_size_gb     = 1
  location_id        = "${var.region}-a"
  authorized_network = google_compute_network.rag_vpc.id
  redis_version      = "REDIS_6_X"
  display_name       = "RAG Semantic Cache"

  depends_on = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 5. Service Account for Ingestion
# -----------------------------------------------------------------------------
resource "google_service_account" "ingestion_sa" {
  account_id   = "rag-ingestion-sa"
  display_name = "RAG Ingestion Service Account"
  depends_on   = [time_sleep.wait_for_apis]
}

resource "google_project_iam_member" "ingestion_roles" {
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/logging.logWriter",
    "roles/aiplatform.user",
    "roles/eventarc.eventReceiver",
    "roles/run.invoker",
    "roles/documentai.apiUser"
  ])
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${google_service_account.ingestion_sa.email}"
  depends_on = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 6. GCS → PubSub Publishing Permission (for Eventarc GCS triggers)
# GCS service account must publish to PubSub to fire Eventarc events.
# -----------------------------------------------------------------------------
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project    = var.project_id
  role       = "roles/pubsub.publisher"
  member     = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  depends_on = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 7. Eventarc Service Identity
# Explicitly provisions the Eventarc service agent SA so it exists
# before IAM bindings are applied. Requires google-beta provider.
# -----------------------------------------------------------------------------
resource "google_project_service_identity" "eventarc_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "eventarc.googleapis.com"

  # Must wait for API to be enabled and initialized
  depends_on = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 8. Eventarc Service Agent IAM Binding
# Grants the Eventarc service agent the required role.
# Uses .email output from service_identity (not a hardcoded SA string)
# to guarantee the SA exists before binding.
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "eventarc_service_agent" {
  project    = var.project_id
  role       = "roles/eventarc.serviceAgent"
  member     = "serviceAccount:${google_project_service_identity.eventarc_sa.email}"
  depends_on = [google_project_service_identity.eventarc_sa]
}

# -----------------------------------------------------------------------------
# STAGE 2 BUFFER — Wait for IAM to propagate globally before Eventarc triggers
# GCP IAM is eventually consistent; bindings take up to 60s to propagate.
# Eventarc trigger creation will fail with 400 if it fires too early.
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_for_eventarc_iam" {
  create_duration = "60s"

  depends_on = [
    google_project_iam_member.eventarc_service_agent,
    google_project_iam_member.gcs_pubsub_publishing,
    google_project_iam_member.ingestion_roles,
  ]
}

# -----------------------------------------------------------------------------
# 9. Storage Buckets
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "raw_data" {
  name                        = "${var.project_id}-rag-raw"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  depends_on                  = [time_sleep.wait_for_apis]
}

resource "google_storage_bucket" "processed_data" {
  name                        = "${var.project_id}-rag-processed"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
  depends_on                  = [time_sleep.wait_for_apis]
}

# -----------------------------------------------------------------------------
# 10. Artifact Registry for Docker Images
# -----------------------------------------------------------------------------
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.app_name}-repo"
  description   = "Docker repository for RAG Microservices"
  format        = "DOCKER"
  depends_on    = [time_sleep.wait_for_apis]
}

# =============================================================================
# DEPENDENCY CHAIN SUMMARY
# =============================================================================
#
#   google_project_service.services
#           ↓ (30s)
#   time_sleep.wait_for_apis
#           ↓
#   ┌───────────────────────────────────────────────┐
#   │ google_compute_network.rag_vpc                │
#   │ google_redis_instance.cache                   │
#   │ google_service_account.ingestion_sa           │
#   │ google_project_iam_member.ingestion_roles     │
#   │ google_project_iam_member.gcs_pubsub_...      │
#   │ google_project_service_identity.eventarc_sa   │
#   │ google_storage_bucket.*                       │
#   │ google_artifact_registry_repository.repo      │
#   └───────────────────────────────────────────────┘
#           ↓
#   google_project_iam_member.eventarc_service_agent
#           ↓ (60s)
#   time_sleep.wait_for_eventarc_iam
#           ↓
#   google_eventarc_trigger.gcs_trigger  (defined in ingestion.tf)
#
# =============================================================================
