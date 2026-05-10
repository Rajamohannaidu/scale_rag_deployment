# 🛠️ Helper Commands Reference

A single-stop reference for all GCP diagnostic, inspection, and management commands used throughout the Enterprise Agentic RAG project.

> **Note:** All commands assume your active project is `dmtxpress` and region is `us-central1`.
> Run `gcloud config set project dmtxpress` if not already set.

---

## 📦 Cloud Build & Artifact Registry

### Submit a new build (rebuild all Docker images)
```bash
gcloud builds submit --config cloudbuild.yaml .
```

### List recent builds and their status
```bash
gcloud builds list --limit=5
```

### Stream logs of the latest build
```bash
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")
```

### List all images in Artifact Registry
```bash
gcloud artifacts docker images list us-central1-docker.pkg.dev/dmtxpress/enterprise-rag-repo
```

---

## 🚀 Cloud Run Services

### List all deployed services
```bash
gcloud run services list --region=us-central1
```

### Describe backend service (annotations, VPC, env)
```bash
gcloud run services describe enterprise-rag-backend --region=us-central1 --format="value(spec.template.metadata.annotations)"
```

### Describe UI service
```bash
gcloud run services describe enterprise-rag-ui --region=us-central1 --format="value(spec.template.metadata.annotations)"
```

### Get the live URLs of all services
```bash
gcloud run services list --region=us-central1 --format="table(name,status.url)"
```

### View live backend logs
```bash
gcloud run services logs read enterprise-rag-backend --region=us-central1 --limit=50
```

### View live ingestion worker logs
```bash
gcloud run services logs read enterprise-rag-ingestion --region=us-central1 --limit=50
```

### Stream logs in real-time
```bash
gcloud alpha run services logs tail enterprise-rag-backend --region=us-central1
```

---

## 🗄️ Redis Memorystore

### List all Redis instances
```bash
gcloud redis instances list --region=us-central1
```

### Describe a specific Redis instance
```bash
gcloud redis instances describe rag-cache --region=us-central1
```

### Get just the Redis host IP
```bash
gcloud redis instances describe rag-cache --region=us-central1 --format="value(host)"
```

---

## 🐘 Cloud SQL (Postgres)

### List all Cloud SQL instances
```bash
gcloud sql instances list
```

### Describe the RAG Postgres instance
```bash
gcloud sql instances describe enterprise-rag-db
```

### Connect to the database (for manual inspection)
```bash
gcloud sql connect enterprise-rag-db --user=postgres --database=postgres
```

### Check databases inside the instance
```bash
gcloud sql databases list --instance=enterprise-rag-db
```

---

## 🌐 VPC & Networking

### List all VPC networks
```bash
gcloud compute networks list
```

### List all VPC Access Connectors (for Cloud Run)
```bash
gcloud compute networks vpc-access connectors list --region=us-central1
```

### Describe a specific VPC connector
```bash
gcloud compute networks vpc-access connectors describe rag-vps --region=us-central1
```

---

## ⚡ Eventarc (GCS Triggers)

### List all Eventarc triggers
```bash
gcloud eventarc triggers list --location=us-central1
```

### Describe the GCS ingestion trigger
```bash
gcloud eventarc triggers describe rag-gcs-trigger --location=us-central1
```

---

## 🪣 Cloud Storage (GCS)

### List all buckets in the project
```bash
gcloud storage buckets list
```

### List files in the raw data bucket
```bash
gcloud storage ls gs://dmtxpress-rag-raw/
```

### List files in the processed data bucket
```bash
gcloud storage ls gs://dmtxpress-rag-processed/
```

### Upload a file to the raw bucket (triggers ingestion)
```bash
gcloud storage cp ./DATA/your_file.pdf gs://dmtxpress-rag-raw/
```

---

## 🔐 IAM & Service Accounts

### List all service accounts in the project
```bash
gcloud iam service-accounts list
```

### Check roles assigned to the backend service account
```bash
gcloud projects get-iam-policy dmtxpress --flatten="bindings[].members" --filter="bindings.members:rag-backend-sa@dmtxpress.iam.gserviceaccount.com" --format="table(bindings.role)"
```

### Check roles assigned to the ingestion service account
```bash
gcloud projects get-iam-policy dmtxpress --flatten="bindings[].members" --filter="bindings.members:rag-ingestion-sa@dmtxpress.iam.gserviceaccount.com" --format="table(bindings.role)"
```

---

## 🏗️ Terraform

### Initialize Terraform (first time only)
```bash
cd terraform && terraform init
```

### Preview infrastructure changes
```bash
cd terraform && terraform plan
```

### Apply infrastructure changes
```bash
cd terraform && terraform apply -auto-approve
```

### Destroy all infrastructure (⚠️ DANGER)
```bash
cd terraform && terraform destroy
```

### Show current Terraform state
```bash
cd terraform && terraform show
```

---

## 🔍 Quick Health Check (Run All at Once)

Use these three commands for a fast sanity check of the whole stack:

```bash
# 1. Are all Cloud Run services live?
gcloud run services list --region=us-central1 --format="table(name,status.url)"

# 2. Is Redis up?
gcloud redis instances list --region=us-central1 --format="table(name,host,status)"

# 3. Is Postgres up?
gcloud sql instances list --format="table(name,state,ipAddresses[0].ipAddress)"
```

---

*Reference this document whenever you need to inspect, debug, or manage your GCP infrastructure.*
