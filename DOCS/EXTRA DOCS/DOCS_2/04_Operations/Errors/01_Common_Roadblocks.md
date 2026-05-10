# 🐛 Error Deep Dive: startup & Connection Issues

We hit several "showstopper" errors during development. Here is the technical breakdown of the most common ones and why they happened.

## 1. Error Code 9: Port Mismatches
* **The Error:** `The user-provided container failed to start and listen on the port defined provided by the PORT=8080`
* **The Root Cause:** Cloud Run sends traffic to port 8080 by default. Streamlit (UI) listens on 8501. The two systems were talking on different frequencies.
* **The Lesson:** Always check the `CMD` in your Dockerfile. If your app doesn't listen on the port Cloud Run expects, it will be killed instantly.

## 2. No such file or directory: Cloud SQL Socket
* **The Error:** `connection to server on socket "/cloudsql/.../.s.PGSQL.5432" failed: No such file or directory`
* **The Root Cause:** Even if the database exists, the container is a "sealed box." It cannot see the database unless you explicitly mount it as a **Volume**.
* **The Lesson:** Cloud Run requires a specific "Cloud SQL Connection" configuration in Terraform to expose that socket file.

## 3. NotImplementedError: Async/Sync Mismatch
* **The Error:** `langgraph/checkpoint/base/__init__.py, line 340, in aget_tuple raise NotImplementedError`
* **The Root Cause:** Python's `asyncio` is powerful but strict. We were using the synchronous `PostgresSaver` library inside an `async` FastAPI function. Since `PostgresSaver` didn't have the "async" code (`aget_tuple`), it just gave up.
* **The Lesson:** Align your database drivers with your function types. (Sync with Sync, Async with Async).

## 4. NEW: Network Address Lock (The Destruction Error)
* **The Error:** `The address resource ... is already being used by //serverless.googleapis.com/.../addressReservations/...`
* **The Root Cause:** This is a "Zombie Address." When you use Direct VPC Egress, Google Cloud creates an "Address Reservation" that outlives the Cloud Run service.
* **The Manual Fix:**
  1. Go to **VPC network** -> **IP addresses**.
  2. Search for the address ID from the error.
  3. Release/Delete it manually.
  4. Only then will Terraform be allowed to delete the VPC network.
