# 📡 Tracing & Observability (Logfire)

In a microservices architecture, when an error happens, it's very hard to know *where* it happened. Did the UI fail? Did the LLM timeout? Did the Vector DB crash?

To solve this, we integrated **Pydantic Logfire**.

## What it does
Logfire provides Distributed Tracing. It acts like an "X-Ray" for our code.

1. **The UI:** When a user asks a question in Streamlit, Logfire starts a timer.
2. **The Backend:** It tracks exactly how many milliseconds the LangGraph Planner took.
3. **The Databases:** It traces the exact SQL query sent to Postgres and the exact vector search sent to Qdrant.
4. **The LLM:** It records the exact prompt sent to Groq and the exact tokens returned.

## The "Safety Shield" Pattern
During development, we realized that if Logfire couldn't authenticate (missing token), it would crash the entire Cloud Run container. 
To prevent observability tools from bringing down production, we wrapped the initialization in a try-except block:

```python
try:
    logfire.configure()
    LOGFIRE_STATUS = "Connected & Tracing"
except Exception:
    LOGFIRE_STATUS = "Standby (No Token)"
```
This guarantees 100% uptime for the application, even if the tracing platform goes offline.
