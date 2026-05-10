# 🏗️ Terraform Deep Dive: main.tf

The `main.tf` file is the foundational blueprint of our entire cloud project. It handles the "Global" settings that everything else relies on.

## 1. Required APIs (`google_project_service`)
Before you can use a service in Google Cloud (like Cloud Run or Redis), you must "Enable" the API.
* **Why it's here:** We enabled 11 different APIs (Run, SQL, Pub/Sub, Eventarc, etc.). By putting them in Terraform, we ensure that the infrastructure never fails because someone forgot to turn on a switch in the GCP Console.

## 2. Networking (`google_compute_network`)
This creates the **VPC (Virtual Private Cloud)** named `rag-vpc`.
* **What it is:** This is our private "mini-internet" inside Google Cloud. It allows our Backend to talk to our Redis cache securely without the traffic ever touching the public web.

## 3. Redis Instance (`google_redis_instance`)
This creates the **Memorystore (Redis)** instance for our Semantic Cache.
* **Key Config:** It is attached specifically to the `rag-vpc` network and is set to `BASIC` tier with 1GB of RAM to keep costs low.

## 4. Service Accounts & IAM
This is the security guard of our app.
* **`ingestion_sa`**: A dedicated identity for our Ingestion worker.
* **IAM Roles**: We granted this identity permission to read from the bucket, write logs, and use Vertex AI. 
* **Critical Fix:** We also granted the GCS service account the `pubsub.publisher` role so it could talk to Eventarc!

## 5. Storage Buckets (`google_storage_bucket`)
Creates the `raw` and `processed` buckets.
* **Special Config:** We added `force_destroy = true`. This allows you to delete the project even if you have gigabytes of PDFs still in the buckets.
