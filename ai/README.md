# AI Chat Backend API - Railway Deployment

FastAPI backend for AI chat using Ollama. This is the backend-only branch for Railway deployment.

**Ollama is installed directly in the Railway container** - no external setup needed!

## Setup

### Deploy to Railway

1. Connect your GitHub repo to Railway
2. Railway will auto-detect the Dockerfile and build
3. Optional environment variables:
   - `OLLAMA_MODEL`: Model name to use (default: "llama2")
   - `PORT`: Railway sets this automatically

**Note:** The first deployment will take longer as it downloads and installs Ollama and pulls the AI model (2-7GB depending on model). Subsequent deployments are faster.

### Local Development

```bash
cd backend
pip install -r requirements.txt
python main.py
```

The API will run on http://localhost:8000

## API Endpoints

- `GET /` - Health check
- `POST /api/chat` - Send message, get AI response
  ```json
  {
    "message": "Hello, how are you?"
  }
  ```

