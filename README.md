# Local Coding Agent

Dockerized [Pi](https://pi.dev) coding agent running against a local Ollama model.  
Inspired by [Vicki Boykis — Running local models is good now](https://vickiboykis.com/2026/06/15/running-local-models-is-good-now/).

## Intention

The goal of this repo is to demonstrate that a genuinely useful AI coding workflow can now run mostly — and in many cases entirely — on a local machine.

Local AI used to feel like a compromise: too slow, too small, too awkward to wire into real tools. Recent open-weight models, Apple Silicon unified memory, Ollama's local inference server, and lightweight agent harnesses have changed that. This project is an experiment in taking those pieces and turning them into a practical, reproducible setup for day-to-day coding assistance.

The motivation is not just cost savings, although avoiding per-token charges is nice. The bigger reasons are:

- **Privacy:** project files and prompts stay on the machine instead of being sent to a hosted API.
- **Control:** the model, runtime, tools, and sandbox are all inspectable and swappable.
- **Hackability:** the setup is small enough to understand, modify, and extend.
- **Offline-first workflows:** once the model and container are available, the core loop does not require cloud inference.
- **Learning:** building the stack yourself makes the moving parts of modern AI agents much less mysterious.

This is intended as a starting point for people who want to explore local-first AI development, not as a claim that local models beat frontier hosted models on every task. The point is that local is now good enough to be useful for a surprising amount of real work.

## Why Pi?

[Pi](https://pi.dev) is the agent harness in this setup — the "steering wheel" that lets a language model do useful coding work instead of only chatting.

By default, Pi gives the model a focused set of development tools such as reading files, writing files, editing files, and running shell commands. In this repo, Pi runs inside Docker with the target project mounted at `/workspace`, so the agent can work on code while remaining isolated from the rest of the host system.

Pi is useful here because it provides:

- **A terminal-native coding interface:** interact with the agent from the command line, switch models with `/model`, resume sessions, and inspect tool calls.
- **Tool use:** the model can read project files, run commands, and make precise edits rather than only suggest changes.
- **Model/provider flexibility:** Pi can talk to OpenAI-compatible providers, which makes it straightforward to point it at Ollama's local API.
- **Session management:** conversations and coding sessions persist, making it easier to continue work across runs.
- **Extensibility:** Pi supports skills, prompt templates, extensions, themes, and custom tools if the local workflow needs to grow.
- **A good fit for sandboxing:** Pi's philosophy is minimal core tooling plus an environment you control. Running it in Docker gives a practical safety boundary for local agents.

In short: Ollama runs the model, Gemma provides the intelligence, Docker provides the sandbox, and Pi turns the model into an interactive coding agent.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Host (Apple Silicon Mac — M4 Max, 128GB RAM)│
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
| `GUIDE.md` | Longer walkthrough explaining each piece of the local setup |

## How the Pieces Fit Together

1. **Ollama** runs on the host and exposes a local OpenAI-compatible API on port `11434`.
2. **Gemma 4 12B** is loaded by Ollama and performs inference locally.
3. **Pi** runs in the Docker container and acts as the coding agent UI/harness.
4. **Docker** limits Pi's filesystem access to the mounted project directory.
5. **models.json** tells Pi how to reach the local Ollama model.

This keeps the setup modular: swap the model, change the harness configuration, or point Pi at another compatible provider without redesigning the whole system.

## Model Performance

Performance varies by hardware. Tested on an Apple Silicon M4 Max with 128GB RAM:

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
