from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver
from app.agents.state import AgentState
from app.agents.nodes.planner import planner_node
from app.agents.nodes.retriever import retrieve_node
from app.agents.nodes.responder import generate_node

# 1. Initialize the State Graph
workflow = StateGraph(AgentState)

# 2. Define the Nodes
workflow.add_node("planner", planner_node)
workflow.add_node("retriever", retrieve_node)
workflow.add_node("responder", generate_node)

# 3. Define the Edges & Routing Logic
def route_planner(state: AgentState):
    """
    Routes the workflow based on the planner's decision.
    """
    if state["current_query"] == "CONVERSATIONAL":
        return "responder"
    return "retriever"

workflow.set_entry_point("planner")

# Conditional Edge: Planner -> Router -> (Retriever OR Responder)
workflow.add_conditional_edges(
    "planner",
    route_planner,
    {
        "retriever": "retriever",
        "responder": "responder"
    }
)

workflow.add_edge("retriever", "responder")
workflow.add_edge("responder", END)

# --- HYBRID MEMORY UPGRADE ---
def get_checkpointer():
    """
    Returns a persistent Postgres checkpointer in Cloud/Production mode,
    and falls back to in-memory checkpointer in Local mode.
    """
    from app.config import settings
    
    if settings.LOCAL_MODE:
        from langgraph.checkpoint.memory import MemorySaver
        print("💾 Using Local MemorySaver (RAM)")
        return MemorySaver()
    
    try:
        from langgraph.checkpoint.postgres import PostgresSaver
        from psycopg_pool import ConnectionPool
        
        # We define a connection string for the pool
        # The host is the local Unix socket path created by the Cloud SQL Connector
        conninfo = f"postgresql://{settings.DB_USER}:{settings.DB_PASS}@/{settings.DB_NAME}?host=/cloudsql/{settings.DB_CONNECTION_NAME}"
        
        # Initialize the pool
        pool = ConnectionPool(conninfo=conninfo, max_size=10)
        
        # Use the pool to create the checkpointer
        # We wrap it in a context manager to ensure setup happens correctly
        with pool.connection() as conn:
            checkpointer = PostgresSaver(conn)
            checkpointer.setup()
        
        # Note: In a long-running app, the pool stays alive in the background
        print("🐘 Using Persistent PostgresSaver (Cloud SQL Pool)")
        return PostgresSaver(pool)
        
    except Exception as e:
        from langgraph.checkpoint.memory import MemorySaver
        print(f"⚠️ Postgres Connection Failed: {e}. Falling back to MemorySaver.")
        return MemorySaver()

# 4. Compile the Graph with Dynamic Memory
checkpointer = get_checkpointer()
rag_agent = workflow.compile(checkpointer=checkpointer)
