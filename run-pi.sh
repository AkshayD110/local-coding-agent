#!/usr/bin/env bash
# run-pi.sh — Launch the containerized Pi agent pointed at a local Ollama model.
#
# Usage:
#   ./run-pi.sh                          # mount current directory as workspace
#   ./run-pi.sh /path/to/project         # mount a specific project
#   ./run-pi.sh /path/to/project --print # pass extra pi flags
#
# Prerequisites:
#   1. Ollama running:  ollama serve
#   2. Model loaded:    ollama pull gemma4:12b
#   3. Docker running:  colima start  (or Docker Desktop)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# First positional arg can be a workspace path
WORKSPACE_DIR=""
pi_args=()

while (($#)); do
  case "$1" in
    /*|./*|../*) 
      # Looks like a path — use as workspace if not set yet
      if [[ -z "$WORKSPACE_DIR" && -d "$1" ]]; then
        WORKSPACE_DIR="$1"
      else
        pi_args+=("$1")
      fi
      ;;
    *)
      pi_args+=("$1")
      ;;
  esac
  shift
done

# Default to current directory
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"
# Resolve to absolute path
case "$WORKSPACE_DIR" in
  /*) ;;
  *)  WORKSPACE_DIR="$(cd -- "$WORKSPACE_DIR" && pwd)" ;;
esac
export WORKSPACE="$WORKSPACE_DIR"

# -------------------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------------------
echo "🔍 Pre-flight checks..."

# 1. Docker
if ! docker info &>/dev/null; then
  echo "❌ Docker is not running. Start it with: colima start"
  exit 1
fi
echo "  ✅ Docker running"

# 2. Ollama
if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
  echo "❌ Ollama is not running. Start it with: ollama serve"
  exit 1
fi
echo "  ✅ Ollama running"

# 3. Model available
if ! ollama list 2>/dev/null | grep -q "gemma4:12b"; then
  echo "⏳ Model gemma4:12b not found. Pulling..."
  ollama pull gemma4:12b
fi
echo "  ✅ gemma4:12b available"

# 4. Build image if needed
if ! docker images | grep -q "pi-agent.*0.79.6"; then
  echo "⏳ Building pi-agent Docker image (first run only)..."
  docker compose --project-directory "$SCRIPT_DIR" -f "$SCRIPT_DIR/docker-compose.yml" build
fi
echo "  ✅ pi-agent image ready"

# -------------------------------------------------------------------
# Launch
# -------------------------------------------------------------------
repo_slug="$(basename -- "$WORKSPACE_DIR" | tr -c 'a-zA-Z0-9_.-' '-' | sed 's/^-*//')"
[[ -z "$repo_slug" ]] && repo_slug="workspace"
container_name="pi-${repo_slug}-$$"

echo ""
echo "🚀 Launching Pi Agent"
echo "   Workspace: $WORKSPACE_DIR"
echo "   Model:     gemma4:12b (Ollama @ localhost:11434)"
echo "   Container: $container_name"
echo ""

cmd=(
  docker compose
  --project-directory "$SCRIPT_DIR"
  -f "$SCRIPT_DIR/docker-compose.yml"
  run --rm
  --name "$container_name"
  pi
  --model "${PI_MODEL:-gemma4:12b}"
)

# Append pi flags (e.g. --print, etc.)
if ((${#pi_args[@]})); then
  cmd+=("${pi_args[@]}")
fi

exec "${cmd[@]}"
