# 🧠 Step 4: Semantic Caching with Redis

This final step adds a high-performance caching layer to our Enterprise RAG system. Instead of relying purely on exact-string matching, we use **Vector Similarity** to understand the "meaning" of a user's question.

## 🚀 Why Semantic Caching?
Traditional caches (like standard Redis) require a 100% character-for-character match to work.
*   **Traditional**: "What's the weather?" vs "What is the weather?" = **Cache MISS**
*   **Semantic**: "What's the weather?" vs "What is the weather?" = **Cache HIT** (99% similarity)

## 🏗️ How it Works
We use the **`redisvl`** (Redis Vector Library) to manage a vector index inside our Google Memorystore (Redis) instance.

1.  **Query Vectorization**: When a user asks a question, we instantly generate its embedding using Vertex AI.
2.  **Vector Search**: We search Redis for any existing vectors that are "close" to the new query (within a distance threshold of ~0.15).
3.  **Instant Response**: If a match is found, we serve the answer from Redis in **~50ms**, bypassing the complex Agentic Graph and saving expensive Groq/OpenAI tokens.

## 🛡️ Resilience & Speed
*   **Cost Savings**: Repeated questions (like HR policies or common FAQs) cost **zero** tokens after the first time.
*   **Latency**: Users get answers 50x faster on cached queries.
*   **Availability**: Even if your LLM provider is down, the most common questions will still work because they are stored in your private Redis cache.

## 🛠️ Configuration
You can adjust the `distance_threshold` in `app/services/gcp/redis_semantic_cache.py`:
*   **Lower (0.10)**: Very strict. Only hits if the question is almost identical.
*   **Higher (0.30)**: Very loose. Might serve answers for questions that are only vaguely related.
*   **Recommended**: **0.15** for a balance of safety and performance.
