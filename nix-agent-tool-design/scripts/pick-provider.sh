#!/usr/bin/env bash
# pick-provider.sh — scan registered OpenCode/OpenClaw providers and present a picker
# Usage: pick-provider.sh --target opencode|openclaw|pinix [--config <path>] [--write] [--dry-run]
#
# Credit: skill packaging by @Mind-Dragon (github.com/Mind-Dragon/atoolix)
# Original agent design by @epiral (github.com/epiral/agent-clip)

set -euo pipefail

TARGET=""
CONFIG_PATH=""
WRITE=false
DRY_RUN=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --config) CONFIG_PATH="$2"; shift 2 ;;
    --write)  WRITE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Error: --target is required (opencode|openclaw|pinix)"
  exit 1
fi

# --- Helper: check for jq ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq  OR  apt install jq"
  exit 1
fi

# --- Provider lists per tool ---

# OpenCode known providers (subset of AI SDK / Models.dev 75+)
OPENCODE_PROVIDERS=(
  "anthropic:claude-opus-4-5,claude-sonnet-4-5,claude-haiku-4-5"
  "openai:gpt-4o,gpt-4o-mini,o3,o4-mini"
  "openrouter:gateway (200+ models)"
  "google:gemini-2.5-pro,gemini-2.0-flash"
  "bedrock:claude via AWS (region required)"
  "azure:gpt-4o via Azure (deployment required)"
  "groq:llama-3.3-70b,gemma2-9b"
  "deepseek:deepseek-r2,deepseek-v3"
  "mistral:mistral-large,codestral"
  "xai:grok-3,grok-3-mini"
  "together:open model hosting"
  "fireworks:fast open models"
  "cerebras:ultra-fast inference"
  "litellm:local proxy / unified gateway"
  "ollama:local models (no key needed)"
  "vllm:local models (no key needed)"
)

# OpenClaw known providers
OPENCLAW_PROVIDERS=(
  "anthropic:claude-opus-4-5,claude-sonnet-4-5"
  "openai:gpt-4o,codex"
  "openrouter:gateway (200+ models)"
  "bedrock:claude via AWS"
  "vertex:gemini via GCP"
  "mistral:mistral-large,codestral"
  "groq:llama-3.3-70b,gemma2-9b"
  "deepseek:deepseek-r2,deepseek-v3"
  "together:open model hosting"
  "fireworks:fast open models"
  "cloudflare:edge inference"
  "litellm:local proxy / unified gateway"
  "ollama:local models (no key needed)"
  "vllm:local models (no key needed)"
  "nvidia:NIM inference"
  "venice:privacy-focused inference"
  "xai:grok-3,grok-3-mini"
  "vercel:managed AI gateway"
)

# --- Detect registered providers ---

declare -a REGISTERED=()

detect_opencode_providers() {
  local auth_file="${HOME}/.local/share/opencode/auth.json"
  if [[ ! -f "$auth_file" ]]; then
    echo "(no auth.json found at $auth_file — showing all supported providers)"
    return
  fi
  # auth.json keys are provider names
  mapfile -t REGISTERED < <(jq -r 'keys[]' "$auth_file" 2>/dev/null || echo "")
}

detect_openclaw_providers() {
  local cfg="${HOME}/.openclaw/config.json"
  [[ -f "claw.config.json" ]] && cfg="claw.config.json"
  [[ -n "$CONFIG_PATH" ]] && cfg="$CONFIG_PATH"

  if [[ ! -f "$cfg" ]]; then
    echo "(no OpenClaw config found — showing all supported providers)"
    return
  fi
  mapfile -t REGISTERED < <(jq -r '.providers | keys[]' "$cfg" 2>/dev/null || echo "")
}

detect_pinix_providers() {
  local cfg="${CONFIG_PATH:-data/config.yaml}"
  if [[ ! -f "$cfg" ]]; then
    echo "(config not found at $cfg — showing all supported providers)"
    return
  fi
  # Parse YAML providers block (basic grep, no yq dependency)
  mapfile -t REGISTERED < <(grep -E '^  [a-z_]+:$' "$cfg" | tr -d ' :' 2>/dev/null || echo "")
}

# --- Build display list ---

build_menu() {
  local -n PROVIDER_LIST=$1
  declare -a MENU=()
  declare -a MENU_KEYS=()
  declare -a MENU_MODELS=()

  local idx=1
  for entry in "${PROVIDER_LIST[@]}"; do
    local key="${entry%%:*}"
    local models="${entry#*:}"
    local registered_marker=""

    # Check if this provider is registered
    for r in "${REGISTERED[@]:-}"; do
      if [[ "$r" == "$key" ]]; then
        registered_marker=" ✓ (registered)"
        break
      fi
    done

    printf "  %2d) %-20s %s%s\n" "$idx" "$key" "$models" "$registered_marker"
    MENU_KEYS+=("$key")
    MENU_MODELS+=("$models")
    ((idx++))
  done

  echo ""
  read -rp "Pick a provider [1-$((idx-1))]: " CHOICE

  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE >= idx )); then
    echo "Invalid choice."; exit 1
  fi

  SELECTED_KEY="${MENU_KEYS[$((CHOICE-1))]}"
  SELECTED_MODELS="${MENU_MODELS[$((CHOICE-1))]}"
}

# --- Generate config snippet ---

generate_opencode_snippet() {
  local provider="$1"
  # Pick first model from the list as default
  local first_model
  first_model=$(echo "$SELECTED_MODELS" | cut -d',' -f1 | xargs)
  if [[ "$first_model" == *"gateway"* || "$first_model" == *"local"* || "$first_model" == *"proxy"* ]]; then
    first_model="<choose-a-model>"
  fi
  cat <<EOF

Add to ~/.config/opencode/opencode.json (or project opencode.json):

{
  "model": "${provider}/${first_model}"
}
EOF
}

generate_openclaw_snippet() {
  local provider="$1"
  local first_model
  first_model=$(echo "$SELECTED_MODELS" | cut -d',' -f1 | xargs)
  if [[ "$first_model" == *"gateway"* || "$first_model" == *"local"* || "$first_model" == *"proxy"* ]]; then
    first_model="<choose-a-model>"
  fi
  cat <<EOF

Add to your OpenClaw config:

{
  "agents": {
    "defaults": {
      "model": {
        "primary": "${provider}/${first_model}"
      }
    }
  }
}
EOF
}

generate_pinix_snippet() {
  local provider="$1"
  local first_model
  first_model=$(echo "$SELECTED_MODELS" | cut -d',' -f1 | xargs)
  if [[ "$first_model" == *"gateway"* || "$first_model" == *"local"* || "$first_model" == *"proxy"* ]]; then
    first_model="<choose-a-model>"
  fi
  # Map provider to base_url
  local base_url
  case "$provider" in
    openrouter)  base_url="https://openrouter.ai/api/v1" ;;
    anthropic)   base_url="https://api.anthropic.com/v1" ;;
    openai)      base_url="https://api.openai.com/v1" ;;
    groq)        base_url="https://api.groq.com/openai/v1" ;;
    deepseek)    base_url="https://api.deepseek.com/v1" ;;
    mistral)     base_url="https://api.mistral.ai/v1" ;;
    together)    base_url="https://api.together.xyz/v1" ;;
    fireworks)   base_url="https://api.fireworks.ai/inference/v1" ;;
    cerebras)    base_url="https://api.cerebras.ai/v1" ;;
    xai)         base_url="https://api.x.ai/v1" ;;
    ollama)      base_url="http://localhost:11434/v1" ;;
    *)           base_url="<provider-base-url>" ;;
  esac
  cat <<EOF

Add/update providers in data/config.yaml:

llm_provider: ${provider}
llm_model: ${first_model}
providers:
  ${provider}:
    base_url: ${base_url}
    api_key: <your-${provider}-key>
EOF
}

# --- Main ---

echo ""
case "$TARGET" in
  opencode)
    detect_opencode_providers
    echo "OpenCode providers (✓ = already registered via /connect):"
    echo ""
    build_menu OPENCODE_PROVIDERS
    generate_opencode_snippet "$SELECTED_KEY"
    ;;
  openclaw)
    detect_openclaw_providers
    echo "OpenClaw providers (✓ = found in config):"
    echo ""
    build_menu OPENCLAW_PROVIDERS
    generate_openclaw_snippet "$SELECTED_KEY"
    ;;
  pinix)
    detect_pinix_providers
    echo "Pinix/agent-clip providers (✓ = found in data/config.yaml):"
    echo ""
    build_menu OPENCODE_PROVIDERS   # Pinix supports the same set via OpenAI-compat base_urls
    generate_pinix_snippet "$SELECTED_KEY"
    ;;
  *)
    echo "Unknown target: $TARGET. Use opencode, openclaw, or pinix."
    exit 1
    ;;
esac
