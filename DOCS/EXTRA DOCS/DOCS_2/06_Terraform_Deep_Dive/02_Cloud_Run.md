# 🏗️ Terraform Deep Dive: cloud_run.tf

This file defines the two main user-facing microservices: the **Backend API** and the **Streamlit UI**.

## 1. Backend Service (`google_cloud_run_v2_service.backend`)
This is the most complex resource in our Terraform.
* **VPC Egress:** We set `egress = "PRIVATE_RANGES_ONLY"`. This forces the Backend to use our secure VPC tunnel to talk to Redis.
* **Volumes (Cloud SQL):** This was a major fix! We added a `cloud_sql_instance` volume. Without this, the `/cloudsql` folder wouldn't exist, and the database connection would fail.
* **Environment Variables:** We inject 11 different variables (Qdrant URLs, DB passwords, Redis IPs) directly into the container so the code knows where to look.

## 2. UI Service (`google_cloud_run_v2_service.ui`)
The frontend service.
* **Container Port (8501):** A critical fix. Since Streamlit doesn't use the standard port 8080, we had to explicitly tell Terraform to route traffic to 8501.
* **Backend URL:** We dynamically fetch the URL of the Backend service and hand it to the UI, so they are always "connected."

## 3. IAM Public Access
We added `google_cloud_run_v2_service_iam_member` to both services.
* **Role:** `roles/run.invoker`
* **Member:** `allUsers`
* **Why:** This makes the URLs public so you can share the link with anyone for testing.
