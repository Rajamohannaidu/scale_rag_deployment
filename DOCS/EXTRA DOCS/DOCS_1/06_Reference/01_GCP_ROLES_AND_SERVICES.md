# GCP Roles & Services: Why and When

This document explains the specific Google Cloud Platform (GCP) services used in this project and the IAM roles required to run them.

## 🏢 Core Services

| Service | Purpose in Project | Why we need it |
| :--- | :--- | :--- |
| **Cloud Run** | Backend API & UI Hosting | To run our Python code in a serverless, scalable environment. |
| **Artifact Registry** | Container Storage | To store the Docker images built by Cloud Build. |
| **Cloud Build** | CI/CD Pipeline | To automate building the Docker image directly in the cloud. |
| **Cloud Storage (GCS)** | Raw & Processed Data | To store the PDFs and processed JSON files for the RAG pipeline. |
| **Cloud SQL (Postgres)** | Metadata & Audit Logs | To store structured logs and persistent session data. |
| **Memorystore (Redis)** | Caching & Memory | To provide fast session memory and cache LLM responses. |
| **Document AI** | PDF Parsing | To extract high-fidelity text from complex PDF documents. |
| **Vertex AI** | Embeddings & Ranking | To convert text into vectors and rerank search results for high precision. |
| **VPC Access** | Private Networking | To allow Cloud Run to talk to private Redis and Cloud SQL instances. |

---

## 🔑 Key IAM Roles

### 👤 For Developers (Local Access)
These roles allow you to run the code on your local machine while authenticated as your own Google account.

*   **`roles/run.admin`**: Full control over Cloud Run services.
*   **`roles/storage.admin`**: Permission to upload/download files from GCS buckets.
*   **`roles/discoveryengine.viewer`**: Allows you to call the Vertex AI Ranking API.
*   **`roles/aiplatform.user`**: Allows you to call Vertex AI Embedding models.
*   **`roles/documentai.apiUser`**: Allows you to send documents to Document AI for parsing.

### 🤖 For Cloud Run (Production)
These roles are assigned to the **Service Account** (e.g., `...-compute@developer.gserviceaccount.com`) that runs your container in the cloud.

*   **`roles/cloudsql.client`**: Allows the container to connect to the Cloud SQL instance.
*   **`roles/discoveryengine.viewer`**: Allows the deployed app to use the Reranker.
*   **`roles/storage.objectViewer`**: Allows the app to read processed files from GCS.

### 🌐 For Networking (Infrastructure)
*   **`roles/vpcaccess.user`**: Specifically required for the **Cloud Run Service Agent** to "plug in" to the VPC Connector. Without this, the app cannot reach Redis or Cloud SQL.

---

## ❓ Common Questions

### Why do I need a VPC Connector?
Cloud Run services live in a shared Google network. Your Redis and Cloud SQL instances live in your private VPC. The **VPC Connector** acts as a secure bridge between them.

### When do I need to enable an API?
Whenever you use a new Google service (like Discovery Engine for ranking), you must "turn on" that service for your project using `gcloud services enable`.
