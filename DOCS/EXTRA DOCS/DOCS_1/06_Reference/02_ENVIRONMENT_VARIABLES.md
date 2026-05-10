# Environment Variables Guide

This document details every environment variable used in the Enterprise Agentic RAG system.

## 🌍 Global Configuration

| Variable | Description | Example |
| :--- | :--- | :--- |
| **`PROJECT_ID`** | Your Google Cloud Project ID. | `dmtxpress` |
| **`LOCATION`** | The GCP region for your services. | `us-central1` |

## 🧠 AI & Vector DB

| Variable | Description | Source |
| :--- | :--- | :--- |
| **`GROQ_API_KEY`** | API key for Llama 3.3 models. | [Groq Console](https://console.groq.com/) |
| **`QDRANT_API_KEY`** | API key for Qdrant Cloud. | [Qdrant Cloud](https://cloud.qdrant.io/) |
| **`QDRANT_CLUSTER_ENDPOINT`**| The URL for your Qdrant cluster. | [Qdrant Cloud](https://cloud.qdrant.io/) |
| **`GCP_DOC_AI_PROCESSOR_ID`** | The ID of your Document AI OCR processor. | [GCP Console](https://console.cloud.google.com/ai/document-ai) |

## 📥 Data Pipeline

| Variable | Description | Default |
| :--- | :--- | :--- |
| **`GCP_RAW_BUCKET`** | GCS Bucket for raw PDFs. | `dmtxpress-rag-raw` |
| **`GCP_PROCESSED_BUCKET`** | GCS Bucket for processed JSON. | `dmtxpress-rag-processed` |

## 🔌 Infrastructure & Networking

| Variable | Description | Note |
| :--- | :--- | :--- |
| **`REDIS_HOST`** | Private IP of your Redis instance. | Required for session memory. |
| **`REDIS_PORT`** | Port for Redis. | Default: `6379` |
| **`VPC_CONNECTOR`** | Name of the VPC Access Connector. | e.g., `rag-vps` |
| **`DB_CONNECTION_NAME`** | The Cloud SQL connection string. | `project:region:instance` |

## 🕵️ Observability

| Variable | Description | Source |
| :--- | :--- | :--- |
| **`LOGFIRE_TOKEN`** | Token for Pydantic Logfire. | [Logfire Dashboard](https://logfire.pydantic.dev/) |
| **`LANGSMITH_API_KEY`** | API key for LangChain tracing. | [LangSmith](https://smith.langchain.com/) |
| **`LANGSMITH_TRACING`** | Set to `true` to enable tracing. | `true` |
| **`LANGSMITH_PROJECT`** | Name of the project in LangSmith. | `rag_scale_test` |

---

## 💡 Best Practices
*   **Security**: Never commit your `.env` file to version control.
*   **Cloud Run**: For production, set these variables using the `--set-env-vars` flag in the `gcloud run deploy` command.
*   **Streamlit Cloud**: Use the "Secrets" dashboard to store these variables.
