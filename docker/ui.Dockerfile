# --- UI MICROSERVICE (STREAMLIT) ---
FROM python:3.11-slim

WORKDIR /app

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set Environment Variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8501

# Streamlit default port
EXPOSE 8501

# Start the Streamlit application
# We use --server.port and --server.address for Cloud Run compatibility
CMD ["streamlit", "run", "ui/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
