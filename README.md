# Local Coding Agent

Dockerized [Pi](https://pi.dev) coding agent running against a local Ollama model.  
Inspired by [Vicki Boykis — Running local models is good now](https://vickiboykis.com/2026/06/15/running-local-models-is-good-now/).

## Architecture

```
┌─────────────────────────────────────────────┐
│  Host (Apple Silicon Mac)                    │
│                                              │
│  Ollama (:11434)                             │
│    └── gemma4:12b  (~7.6GB, Q4_K_M)         │
│           ▲                                  │
│           │  OpenAI-compatible API            │
│           │                                  │
│  Docker Container                            │
│    └── Pi Agent                              │
│         - bash only (no python/curl)         │
│         - /workspace mounted read-write      │
│         - models.json → Ollama endpoint      │
└─────────────────────────────────────────────┘
```

## Prerequisites

- **Ollama** — `brew install ollama`
- **Docker** — via Colima (`colima start`) or Docker Desktop
- **Model** — `ollama pull gemma4:12b`

## Quick Start

```bash
# 1. Make sure Ollama is serving
ollama serve &

# 2. Run Pi against any project directory
./run-pi.sh /path/to/your/project

# 3. Inside Pi, select the model
#    Press /model → pick "Gemma 4 12B QAT (Local)"
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the Pi agent image (node:22-slim + pi + bash tools) |
| `docker-compose.yml` | Container config — mounts workspace, ships models.json |
| `models.json` | Pi provider config pointing at Ollama's OpenAI-compat endpoint |
| `run-pi.sh` | Launch script with pre-flight checks |

## Model Performance

Performance varies by hardware. On Apple Silicon with 32GB+ RAM:

| Metric | Approximate |
|--------|-------------|
| Prefill | ~50-70 tps |
| Generation | ~10-15 tps |
| Memory usage | ~7.6 GB model + ~4-8 GB KV cache |
| Context window | 32K tokens (configurable) |

## Swapping Models

Edit `models.json` to add more models. No restart needed — Pi reloads on `/model`.

```bash
# Pull another model
ollama pull qwen3.6:8b

# Add to models.json, then in Pi: /model → select it
```

## Security Notes

Following the article's approach:
- Pi runs in a container — cannot access host filesystem beyond `/workspace`
- No Python, curl, or web browsing in the container
- No cloud API keys needed — fully offline inference
- Sessions persist in a Docker volume across runs
# local-coding-agent
