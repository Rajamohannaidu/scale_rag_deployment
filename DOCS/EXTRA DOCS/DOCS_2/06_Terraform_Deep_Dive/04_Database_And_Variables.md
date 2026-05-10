# 🏗️ Terraform Deep Dive: database.tf & variables.tf

These files handle the persistent state and the secrets of our application.

## 1. database.tf (The Memory)
* **Instance Config:** We chose `db-f1-micro`. This is the smallest Postgres instance available, keeping your costs down to roughly $10/month during development.
* **Deletion Protection:** We set `deletion_protection = false`. While dangerous for production, it is essential for development so you can run `terraform destroy` easily.
* **Database & Users:** We create a database named `rag_memory` and a user named `rag_admin`.

## 2. variables.tf & terraform.tfvars
This is how we keep the "Blueprint" (the code) separate from the "Materials" (your specific project IDs and passwords).
* **variables.tf**: Defines *what* inputs are required (e.g., "I need a Groq API Key").
* **terraform.tfvars**: Stores the *actual* secret values. 
* **Pro-Tip:** Never commit your `terraform.tfvars` file to Git! It contains your passwords.
