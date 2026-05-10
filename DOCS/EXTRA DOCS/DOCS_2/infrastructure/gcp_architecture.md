# ☁️ Google Cloud Infrastructure & Architecture

This document explains the Google Cloud Platform (GCP) services used in the **Enterprise Agentic RAG Platform**, the roles they play, and how they interact to provide a scalable, event-driven system.

---

## 🏗️ Architecture Diagram

The diagram below illustrates how each service is connected via secure networking and event triggers.

```mermaid
graph TD
    %% Users & Entry
    User([User]) -->|HTTPS| UI[Streamlit UI<br/><i>Cloud Run</i>]
    UI -->|Internal HTTPS| API[Backend API<br/><i>Cloud Run</i>]
    
    %% Storage & Events
    Admin([Admin]) -->|Upload PDF| GCS_Raw[(Cloud Storage<br/><i>rag-raw</i>)]
    GCS_Raw -->|Pub/Sub Notification| Eventarc((Eventarc))
    Eventarc -->|POST /| Ingest[Ingestion Worker<br/><i>Cloud Run</i>]
    
    %% Processing & AI
    Ingest -->|Embeddings| VertexAI[[Vertex AI]]
    Ingest -->|Index| Qdrant[(Qdrant Cloud)]
    
    %% Backend Services
    API -->|Search| Qdrant
    API -->|Prompt| Groq((Groq API))
    
    %% Private Networking (VPC)
    subgraph "Secure Private VPC"
        API -->|Cache| Redis[(Memorystore Redis)]
        API -->|Memory| Postgres[(Cloud SQL Postgres)]
        Ingest -->|Save Status| Postgres
    end
    
    %% Connectors
    API -.->|VPC Connector| Redis
    API -.->|Unix Socket| Postgres
```

---

## 🛠️ Service Breakdown

### 1. Cloud Run (Compute)
*   **Role:** Hosts our Backend API, UI, and Ingestion Worker.
*   **Why:** It is **Serverless**, meaning it only runs when needed and scales automatically to zero when idle. This significantly reduces costs while providing high availability.

### 2. Cloud Storage (GCS)
*   **Role:** Acts as our "Data Lake."
*   **Why:** It provides highly durable object storage. We use two buckets: one for **Raw** files (PDFs) and one for **Processed** metadata (JSON).

### 3. Eventarc (Event Orchestration)
*   **Role:** The "Glue" between Storage and Compute.
*   **Why:** It allows for an **Event-Driven Architecture**. Instead of our code constantly checking the bucket for new files, Eventarc "wakes up" the Ingestion Worker only when a new file is actually uploaded.

### 4. Cloud SQL (PostgreSQL)
*   **Role:** Persistent Conversation Memory.
*   **Why:** LangGraph requires a "checkpointer" to save the state of conversation threads. We use a managed Postgres instance for reliability and automatic backups.

### 5. Memorystore (Redis)
*   **Role:** Semantic Cache.
*   **Why:** To reduce LLM costs and latency, we cache common answers. Redis is an extremely fast in-memory database perfectly suited for this high-speed lookup.

### 6. Vertex AI
*   **Role:** High-Performance Embeddings.
*   **Why:** We use Google's `text-embedding-004` model to convert text chunks into numerical vectors. It offers state-of-the-art precision for enterprise retrieval.

### 7. Serverless VPC Access (Networking)
*   **Role:** Secure Internal Bridge.
*   **Why:** To ensure our data never leaves the private Google network, we use a VPC Connector. This allows our Cloud Run services to talk directly to Cloud SQL and Redis without using public IP addresses.

---

## 🔐 IAM Roles & Permissions

To make this architecture secure, we use **Least Privilege** service accounts:

| Service Account | Role | Purpose |
| :--- | :--- | :--- |
| `backend-sa` | `Cloud SQL Client` | Connect to Postgres memory. |
| `backend-sa` | `Vertex AI User` | Generate embeddings for search queries. |
| `ingestion-sa` | `Storage Object Viewer` | Read new files from GCS. |
| `ingestion-sa` | `Storage Object Creator` | Save processed JSON to the results bucket. |
| `eventarc-sa` | `Eventarc Event Receiver` | Authorized to trigger the Ingestion Worker. |

---
*Built with Security and Scalability in mind.*
