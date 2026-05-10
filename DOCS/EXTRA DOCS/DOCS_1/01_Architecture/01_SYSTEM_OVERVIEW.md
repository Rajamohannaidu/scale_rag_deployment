# 🏗️ 01. System Overview

This project implements a **Scalable, Production-Grade Agentic RAG** using a cyclic state machine.

## 🔄 The Cyclic Flow
```mermaid
graph TD
    User((User)) --> UI[Streamlit UI]
    UI --> Planner{Planner Node}
    Planner -->|Conversational| Responder[Responder Node]
    Planner -->|Technical| Retriever[Retriever Node]
    Retriever --> Reranker[Vertex AI Reranker]
    Reranker --> Responder
    Responder --> UI
    Responder -.-> Memory[(Memory Saver)]
```

## 🛠️ Stack Breakdown
- **Orchestrator**: LangGraph (for cyclic logic)
- **Memory**: MemorySaver Checkpointer
- **Vector DB**: Qdrant Cloud
- **LLM**: Groq (Llama 3 70B)
- **Re-ranking**: Google Vertex AI Ranking API
