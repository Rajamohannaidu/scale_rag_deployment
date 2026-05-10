# GCP Configuration & Step-by-Step Setup

Follow these steps on the [Google Cloud Console](https://console.cloud.google.com) to prepare your environment for the target architecture. This guide assumes you are using an **existing project**.

## Step 1: APIs to Enable
Go to **APIs & Services > Library** and search for/enable the following:

| Service | Why? |
| :--- | :--- |
| **Vertex AI API** (`aiplatform.googleapis.com`) | Embedding generation and Gemini LLM. |
| **Cloud Storage** (`storage.googleapis.com`) | Storing documents and vector store backups. |
| **Cloud Run** (`run.googleapis.com`) | Deployment of your main FastAPI RAG service. |
| **Cloud SQL Admin API** (`sqladmin.googleapis.com`) | Managing your PostgreSQL database. |
| **Cloud Memorystore for Redis** (`redis.googleapis.com`) | Query caching layer for performance. |
| **Secret Manager API** (`secretmanager.googleapis.com`) | Securely storing Neo4j and Qdrant credentials. |
| **Cloud Logging API** (`logging.googleapis.com`) | Storing and searching application logs. |
| **Cloud Monitoring API** (`monitoring.googleapis.com`) | Tracking performance metrics and dashboards. |
| **Service Usage API** (`serviceusage.googleapis.com`) | To manage API usage across the project. |

---

## Step 2: Service Account & Permissions
Create a dedicated Service Account (e.g., `rag-enterprise-engine`) and grant it only the roles it needs.

### 2.1 Create the Account
1.  Go to **IAM & Admin > Service Accounts**.
2.  Click **Create Service Account**.
3.  Name it `rag-engine-service-account`.

### 2.2 Grant these IAM Roles
Go to **IAM & Admin > IAM** and ensure the Service Account has the following roles:

| Role Name | ID | Purpose |
| :--- | :--- | :--- |
| **Vertex AI User** | `roles/aiplatform.user` | Call embedding and generative models. |
| **Storage Object Admin** | `roles/storage.objectAdmin` | Read/write access to your GCS bucket. |
| **Secret Manager Secret Accessor** | `roles/secretmanager.secretAccessor` | Retrieve Qdrant/Neo4j keys. |
| **Cloud SQL Client** | `roles/cloudsql.client` | Connect to the Postgres database. |
| **Redis Editor** | `roles/redis.editor` | Manage/connect to Memorystore (Redis). |
| **Logs Writer** | `roles/logging.logWriter` | Write application logs to Cloud Logging. |
| **Monitoring Metric Writer** | `roles/monitoring.metricWriter` | Send performance metrics to Cloud Monitoring. |

---

## Step 3: Secure Asset Configuration (Secret Manager)
Instead of putting Neo4j/Qdrant passwords in plain text in `.env`, we use **Secret Manager**.

1.  Go to **Security > Secret Manager**.
2.  Create a secret named `Neo4jPassword`.
3.  Create a secret named `QdrantApiKey`.
4.  Your code will now pull these at runtime using the `google-cloud-secret-manager` library.

---

## Step 4: Cloud Storage Bucket
1.  Go to **Cloud Storage > Buckets**.
2.  Create a bucket (e.g., `rag-enterprise-bucket`).
3.  Create the following folder hierarchy:
    - `raw/`: For original document uploads.
    - `chunks/`: For JSON/Text chunks.
    - `backups/`: For FAISS/Vector store snapshots.

---

## Step 5: Updated Environment Variables (.env)
Your `.env` should now looks like this for a production-grade setup:
```env
# GCP Basic
PROJECT_ID="your-existing-project-id"
LOCATION="us-central1"
BUCKET_NAME="rag-enterprise-bucket"

# Service Account
GOOGLE_APPLICATION_CREDENTIALS="path/to/your/service-account.json"

# Vector Store (Qdrant Cloud)
QDRANT_URL="https://your-qdrant-cluster-url"
QDRANT_API_KEY="managed-via-secret-manager-or-local-for-dev"

# Graph DB (Neo4j Aura)
NEO4J_URI="neo4j+s://your-instance-id.databases.neo4j.io"
NEO4J_USER="neo4j"
NEO4J_PASSWORD="managed-via-secret-manager"
```

## Step 6: Verification
To ensure everything is set up correctly, run these commands in your console:
- `gcloud services list --enabled --filter="name:aiplatform.googleapis.com"` (Check Vertex AI)
- `gcloud iam service-accounts describe rag-engine-service-account@your-project.iam.gserviceaccount.com` (Check SA)
