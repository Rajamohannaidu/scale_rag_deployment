# 🗺️ Future Roadmap

While the Enterprise Agentic RAG system is currently production-ready, here are the planned next steps to take it to the next level.

## 1. Multi-Modal Ingestion
**Current State:** The ingestion worker only parses Text and PDFs using Unstructured.io.
**Next Level:** Integrate Vision-Language Models (VLMs) to parse images, charts, and graphs within PDFs, storing their semantic meaning in Qdrant.

## 2. Dynamic Tool Calling
**Current State:** The LangGraph agent relies purely on the Vector DB for context.
**Next Level:** Equip the agent with external APIs (e.g., Jira, Salesforce, Google Workspace). The Planner node will decide whether to search Qdrant OR query a live API to answer the user's question.

## 3. Advanced Chunking Strategies
**Current State:** Basic text chunking with overlap.
**Next Level:** Implement "Semantic Chunking" or "Parent-Child Retrieval". This means we store small chunks for highly accurate vector search, but return the massive parent document to the LLM for maximum context.

## 4. User Authentication (Identity)
**Current State:** The UI allows anyone to chat, and memory is grouped by an auto-generated `thread_id`.
**Next Level:** Implement Google OAuth/SSO in Streamlit. Tie the LangGraph `thread_id` to the specific logged-in user, creating a personalized, long-term memory for every employee in the enterprise.

## 5. Automated Evaluation (RAGAS)
**Current State:** Manual testing of answers.
**Next Level:** Integrate a framework like RAGAS to automatically score the LLM's answers for Faithfulness (no hallucinations) and Answer Relevance based on the retrieved context.
