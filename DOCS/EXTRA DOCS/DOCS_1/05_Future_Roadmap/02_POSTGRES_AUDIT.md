# Postgres Audit Logging & Persistence

## 🏛️ Overview
Every interaction with the Enterprise RAG system is logged to **Google Cloud SQL (Postgres)**. This provides a source of truth for auditing, performance monitoring, and debugging.

## 📊 Database Schema
The system uses SQLAlchemy to manage the `query_logs` table:

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Unique identifier for each request. |
| `timestamp` | DateTime | When the query was executed (UTC). |
| `query` | Text | The raw user query. |
| `reasoning` | Text | The internal "Chain of Thought" from the LLM. |
| `answer` | Text | The final validated response. |
| `sources` | JSONB | List of source URLs/snippets used. |
| `latency` | Float | Total end-to-end processing time in seconds. |

## 🛠️ Connectivity
- **Cloud SQL Python Connector**: Used for secure, encrypted connections without needing to manage SSL certificates or authorized networks.
- **ORM**: SQLAlchemy is used to handle the mapping, allowing for easy expansion (e.g., adding a `user_feedback` table later).

## 📈 Analytics Queries
You can run these in the GCP "Query Studio":
- **Average Latency**: `SELECT AVG(latency) FROM query_logs;`
- **Most Used Sources**: Use JSON functions to expand the `sources` column.
- **Debug Reasoning**: `SELECT reasoning FROM query_logs WHERE id = '<uuid>';`
