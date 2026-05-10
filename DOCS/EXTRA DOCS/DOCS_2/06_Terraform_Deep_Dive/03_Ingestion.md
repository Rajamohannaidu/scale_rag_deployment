# 🏗️ Terraform Deep Dive: ingestion.tf

This file handles the "Event-Driven" part of our architecture. It's what makes the system feel like magic when you upload a file.

## 1. Ingestion Service
Very similar to the backend, but it's configured for **Internal Traffic Only**. 
* **Why?** We don't want anyone on the internet to be able to trigger our ingestion worker. It should only listen to Google's internal Eventarc service.

## 2. Eventarc Trigger (`google_eventarc_trigger`)
This is the "Tripwire." 
* **Matching Criteria:** It watches specifically for the `google.cloud.storage.object.v1.finalized` event (which means a file upload is finished).
* **Target:** It routes that event directly to our Ingestion Cloud Run service.
* **The Dependency Fix:** We added a `depends_on` block. This forces Terraform to wait until all IAM permissions are fully active before trying to create the trigger, preventing 403 errors.
