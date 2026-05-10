# 🤖 03. Node Intelligence

Detailed breakdown of the LangGraph agent nodes.

## 🧠 Nodes
- **Planner Node**: Determines user intent using conversation history.
- **Retriever Node**: Executes search and Vertex AI reranking.
- **Responder Node**: Synthesizes the final answer with token safety.

## 💾 State & Memory
Uses `AgentState` and `MemorySaver` to preserve context across thread IDs.
