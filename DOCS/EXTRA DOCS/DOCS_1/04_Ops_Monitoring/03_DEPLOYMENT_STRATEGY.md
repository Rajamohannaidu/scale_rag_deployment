# Deployment Guide: Cloud Run & VPC

## 🚀 Deployment Strategy
The application is designed to be deployed as a container on **Google Cloud Run**.

## 📦 Containerization
1. **Dockerfile**: The project includes a Dockerfile.
2. **Build**: `gcloud builds submit --tag gcr.io/YOUR_PROJECT/rag-api`

## 🔗 Networking (CRITICAL)
Because the system uses **Memorystore Redis** (Private IP), you must set up a **Serverless VPC Access Connector**.

1. **Create Connector**:
   - Go to **VPC network > Serverless VPC access**.
   - Create a connector (e.g., `rag-vpc-connector`) in the same region.
2. **Configure Cloud Run**:
   - During deployment, go to **Networking**.
   - Select **"Route all traffic through the VPC connector"**.
   - Select your connector.

## 🔑 Environment Variables
Ensure the following are set in the Cloud Run configuration:
- `PROJECT_ID`
- `LOCATION`
- `GROQ_API_KEY`
- `QDRANT_API_KEY`
- `DB_USER`
- `DB_PASS`
- `REDIS_HOST`

## 🛠️ Deployment Command
```bash
gcloud run deploy rag-api \
  --image gcr.io/YOUR_PROJECT/rag-api \
  --vpc-connector rag-vpc-connector \
  --set-env-vars "GROQ_API_KEY=xxx,REDIS_HOST=10.x.x.x..." \
  --region us-central1 \
  --allow-unauthenticated
```
