# --- INGESTION MICROSERVICE (BATCH WORKER) ---
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
# Switched libgl1-mesa-glx to libgl1 to fix the "no installation candidate" error
RUN apt-get update && apt-get install -y \
    build-essential \
    libmagic-dev \
    libxcb1 \
    libx11-6 \
    libxrender1 \
    libxext6 \
    libgl1 \
    libgomp1 \
    poppler-utils \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set Environment Variables
ENV PYTHONUNBUFFERED=1

# Cloud Run uses the PORT env var
EXPOSE 8080

# Start the Ingestion FastAPI application
CMD ["python", "-m", "uvicorn", "app.ingestion.processor:app", "--host", "0.0.0.0", "--port", "8080"]
