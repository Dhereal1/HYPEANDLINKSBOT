#!/bin/bash
set -e

# Start Ollama in the background
echo "Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready (check if it's responding)
echo "Waiting for Ollama to start..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "Ollama is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Warning: Ollama did not start in time, continuing anyway..."
    fi
    sleep 1
done

# Check if model exists, if not pull it
MODEL=${OLLAMA_MODEL:-llama2}
echo "Checking for model: $MODEL"
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "Pulling model: $MODEL (this may take a while, 2-7GB download)..."
    ollama pull $MODEL || {
        echo "Warning: Failed to pull model. The API will still work but chat requests will fail."
    }
else
    echo "Model $MODEL already exists"
fi

# Start FastAPI app
echo "Starting FastAPI application on port ${PORT:-8000}..."
cd backend
exec python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}

