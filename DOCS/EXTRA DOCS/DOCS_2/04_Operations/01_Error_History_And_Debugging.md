# 🐛 Error History & Debugging Log

Building a production-grade cloud system is a battle. Here are the major roadblocks we hit during development and how we conquered them.

## 1. The Qdrant "Import Time" Crash
**The Problem:** When deploying to Cloud Run, the container would crash immediately on startup.
**The Cause:** Our Python code was trying to connect to Qdrant the exact millisecond the file was imported (`client = QdrantClient(...)` at the top of the file). If the network was even slightly slow, Cloud Run killed the container.
**The Fix:** We implemented **Lazy Initialization**. We wrapped the connection in a function (`get_qdrant_client()`) so it only connects *when a query is actually made*.

## 2. Cloud SQL Connection Chaos (`psycopg` vs `pg8000`)
**The Problem:** The app crashed when trying to connect to Postgres.
**The Cause:** We had a major driver mismatch. We were using the Google Cloud SQL Connector library configured for the `pg8000` driver, but our `ConnectionPool` was built using `psycopg3`. They didn't speak the same language.
**The Fix:** We stripped out the complex Google Connector library entirely. Since we were on Cloud Run, we used the native **Unix Socket** (`/cloudsql/...`) directly with the standard `psycopg3` driver. Simple and bulletproof.

## 3. The "Port 8080" Cloud Run Timeout (UI Crash)
**The Problem:** The UI service kept returning `Error Code 9: container failed to start and listen on port 8080`.
**The Cause:** By default, Cloud Run expects all web apps to listen on port `8080`. However, Streamlit (our UI framework) hardcodes its server to listen on port `8501`. Cloud Run was knocking on 8080, getting no answer, and killing the app.
**The Fix:** In Terraform (`cloud_run.tf`), we added a `ports { container_port = 8501 }` block to explicitly tell Cloud Run where to look.

## 4. The LangGraph `NotImplementedError`
**The Problem:** `500 Internal Server Error` when asking a question. The logs showed `NotImplementedError` in `aget_tuple`.
**The Cause:** We were trying to execute the agent asynchronously (`await rag_agent.ainvoke()`), but we had attached a *Synchronous* database saver (`PostgresSaver`). 
**The Fix:** We switched the FastAPI endpoint to run synchronously (`rag_agent.invoke()`), properly aligning the execution flow with the database driver.

## 5. The LangGraph `UndefinedTable` Error
**The Problem:** Another `500 Internal Server Error` stating that the table "checkpoints" did not exist.
**The Cause:** When connecting to a brand new Cloud SQL database, the tables required by LangGraph to store conversation memory don't exist yet. 
**The Fix:** We added `checkpointer.setup()` to the initialization sequence in `graph.py`, telling LangGraph to auto-create its tables (`IF NOT EXISTS`) on startup.

## 6. The Logfire 500 Crash
**The Problem:** The app crashed randomly on startup with an "Authentication Required" error from Logfire.
**The Cause:** Locally, the developer was logged in via `logfire auth`. In the cloud container, there was no session. Because Logfire couldn't authenticate, it crashed the whole app.
**The Fix:** 
1. We wrapped `logfire.configure()` in a "Safety Shield" (`try-except`) so the app would survive even if observability failed.
2. We added the `LOGFIRE_TOKEN` to Terraform and injected it as an Environment Variable.

## 7. Eventarc 403 Permission Denied
**The Problem:** Terraform refused to create the Eventarc trigger, throwing a `storage.buckets.get permission denied` error.
**The Cause:** Google Cloud requires strict security handshakes. Cloud Storage didn't have permission to publish events, and Eventarc didn't have permission to look at Cloud Storage.
**The Fix:** In Terraform, we granted `roles/pubsub.publisher` to the Storage Service Account, and `roles/eventarc.serviceAgent` to the internal Eventarc agent, effectively unlocking the communication bridge.

---

## 8. GCP Environment Variables Not Reaching Cloud Run
**The Problem:** The app was running in the cloud but behaving as if `PROJECT_ID`, `LOCATION`, and bucket names were `None`. Vertex AI calls were failing silently.
**The Cause:** While the code was loading these values from environment variables, the Terraform `cloud_run.tf` file for the **backend service** was missing the `env {}` blocks that explicitly inject these values into the container.
**The Fix:** Added explicit `env` blocks for `PROJECT_ID`, `LOCATION`, `GCP_RAW_BUCKET`, and `GCP_PROCESSED_BUCKET` to the backend service definition in `terraform/cloud_run.tf` and ran `terraform apply`.

---

## 9. Vertex AI Not Initialized on Cloud Startup
**The Problem:** Embedding and generative model calls were throwing `DefaultCredentialsError` or "not initialized" errors in Cloud Run, even though it worked locally.
**The Cause:** `vertexai.init(project=..., location=...)` was never being called. Locally, the SDK picks up credentials from `gcloud auth`. In Cloud Run, it needs to be explicitly told which project to target.
**The Fix:** Added `vertexai.init(project=settings.PROJECT_ID, location=settings.LOCATION)` as the very first call inside `app/main.py`, before any other imports can trigger model usage.

---

## 10. Logfire Always on "Standby (No Token)" in UI
**The Problem:** The Streamlit UI sidebar always showed `Logfire: Standby (No Token)` even after the backend was tracing correctly.
**The Cause:** The `LOGFIRE_TOKEN` was correctly added to the **Backend** and **Ingestion** Cloud Run services in Terraform, but not the **UI** service. Since each Cloud Run service is an independent container, environment variables do not transfer between them.
**The Fix:** Added `LOGFIRE_TOKEN`, `LANGSMITH_API_KEY`, `LANGSMITH_PROJECT`, and `LANGSMITH_ENDPOINT` env blocks to the `google_cloud_run_v2_service "ui"` resource in `terraform/cloud_run.tf`.

---

## 11. LangSmith Variable Naming Mismatch (`LANGCHAIN_` vs `LANGSMITH_`)
**The Problem:** LangSmith tracing was not working. The variables were defined in `.env` but traces were not appearing in the LangSmith dashboard.
**The Cause:** The newer LangSmith SDK uses `LANGSMITH_` prefixed variables (`LANGSMITH_API_KEY`, `LANGSMITH_TRACING`, etc.), but the codebase and Terraform were using the older `LANGCHAIN_` prefix (`LANGCHAIN_API_KEY`, `LANGCHAIN_TRACING_V2`).
**The Fix:** Renamed all variables consistently to `LANGSMITH_` prefix across `.env`, `config.py`, `terraform/variables.tf`, `terraform/terraform.tfvars`, `terraform/cloud_run.tf`, and `terraform/ingestion.tf`. Added a bridge in `app/main.py` that maps the new names to what the underlying LangChain library still expects internally.

---

## 12. Redis Semantic Cache Failing with `HFTextVectorizer` Error
**The Problem:** Logfire showed `❌ Failed to init Redis Semantic Cache: HFTextVectorizer requires the sentence-transformers library` on every single request in Cloud Run. Redis was completely inactive.
**The Cause:** The `redisvl` `SemanticCache` defaults to using a HuggingFace local model (`HFTextVectorizer`) to generate embeddings for semantic comparison. The `sentence-transformers` library (which that model requires) was not included in `requirements.txt`, so it crashed silently on every initialization attempt. This was not caught locally because `LOCAL_MODE=true` skips the cache entirely on developer machines.
**The Fix:** Created a `_vertex_embed` adapter function in `semantic_cache.py` that wraps the existing `embed_query` Vertex AI function. Passed it to `redisvl` via `CustomTextVectorizer(embed=_vertex_embed)`. This eliminates the `sentence-transformers` dependency and keeps the entire pipeline using the same embedding model (`text-embedding-004`).

---

## 13. Password with `@` Symbol Causes DB Connection Failure Locally
**The Problem:** When running locally without `LOCAL_MODE=true`, the app throws `failed to resolve host '000@localhost': getaddrinfo failed`.
**The Cause:** The Postgres password `Divesh.sql@000` contains an `@` symbol. When the app builds a standard TCP connection string like `postgresql://user:password@host/db`, the `@` in the password confuses the URL parser — it thinks `000` is the beginning of the hostname.
**The Fix (Local):** Set `LOCAL_MODE=true` in `.env` for local development. The app is designed to use in-memory storage when in local mode, bypassing the Postgres connection entirely.
**The Fix (Cloud):** This is a non-issue on Cloud Run because the app uses Unix Socket format (`host=/cloudsql/...`) which does not parse the password as part of a URL.
