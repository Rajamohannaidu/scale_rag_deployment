# 🚢 Deployment Strategy (CI/CD)

Our deployment strategy is optimized for speed, reliability, and automation using Google Cloud Build and Terraform.

## 1. Container Building (CI)
We do not build Docker images locally. We offload this to **Google Cloud Build**.
By running `gcloud builds submit --config cloudbuild.yaml .`, Google Cloud:
1. Provisions a high-CPU build server.
2. Reads our `cloudbuild.yaml` instructions.
3. Simultaneously builds the `ui`, `backend`, and `ingestion` Docker images.
4. Pushes them to our private Artifact Registry repository.

## 2. Infrastructure Deployment (CD)
Once the images are built, we use **Terraform** to update the actual servers.
By running `terraform apply`, Terraform:
1. Checks the current state of our Cloud Run instances.
2. Updates them to pull the newest "latest" tag from Artifact Registry.
3. Re-routes traffic to the new instances without downtime (Zero-Downtime Deployment).

## 3. Environment Variables
Sensitive data (API keys, passwords) are *never* stored in Docker images. 
Instead, we pass them directly into Terraform via the `terraform.tfvars` file. Terraform then injects them directly into the Cloud Run instances at runtime, ensuring maximum security.
