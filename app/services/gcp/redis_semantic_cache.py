import logfire
from redisvl.extensions.llmcache import SemanticCache
from app.config import settings
from app.services.retrieval.embedding import embed_texts


# Initialize the Semantic Cache
# This will be None if Redis is not reachable or in Local Mode
_cache = None


def init_cache():
    """Initializes the Redis Semantic Cache with Vertex AI embeddings."""
    global _cache
    
    if settings.LOCAL_MODE or not settings.REDIS_HOST:
        logfire.warning("⚠️ Redis Cache disabled (Local Mode or Missing Host)")
        return None

    try:
        # Define the Redis connection URL
        redis_url = f"redis://{settings.REDIS_HOST}:{settings.REDIS_PORT}"
        
        # We use the same schema as our main RAG system for consistency
        _cache = SemanticCache(
            name="rag_cache",
            prefix="semantic",
            redis_url=redis_url,
            distance_threshold=0.15 # Lower is stricter (0.10 - 0.20 is sweet spot)
        )
        
        # TEST: Check if Redis supports Vector Search (FT.INFO command)
        # Standard Google Memorystore may not support this unless it's a Cluster or has modules
        try:
            _cache.index.create(dims=768, overwrite=False)
            logfire.info(f"✅ Redis Semantic Cache Initialized at {settings.REDIS_HOST}")
        except Exception as e:
            logfire.warning(f"⚠️ Redis Index Error: {e}. Semantic Search might not be supported on this Redis instance. Caching disabled.")
            _cache = None
            
        return _cache
    except Exception as e:
        logfire.error(f"❌ Redis Cache Connection Failed: {e}")
        _cache = None
        return None
    
    
def check_cache(query: str):
    """
    Checks if a semantically similar query exists in Redis.
    Returns the cached response string or None.
    """
    if not _cache:
        return None
        
    with logfire.span("🧠 Semantic Cache Check", query=query):
        try:
            # 1. Embed the user query using our standard Vertex AI model
            vector = embed_texts([query])[0]
            
            # 2. Search for similar queries in Redis
            # redisvl handles the vector search logic internally
            results = _cache.check(vector=vector)
            
            if results:
                logfire.info("🎯 Cache HIT! Serving from Redis")
                return results[0]["response"]
                
            return None
        except Exception as e:
            logfire.error(f"⚠️ Cache Check Error: {e}")
            return None


def update_cache(query: str, response: str):
    """
    Stores a new query-response pair in the semantic cache.
    """
    if not _cache:
        return
        
    try:
        # Vectorize before storing
        vector = embed_texts([query])[0]
        
        _cache.store(
            prompt=query,
            response=response,
            vector=vector
        )
        logfire.info("💾 Cache Updated with new response")
    except Exception as e:
        logfire.error(f"⚠️ Cache Update Error: {e}")


# Initialize on module load
init_cache()
