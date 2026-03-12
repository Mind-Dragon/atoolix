#!/usr/bin/env bash
# install.sh — atoolix installer
# Installs agent-clip (from epiral/agent-clip) + nix-agent-tool-design skill
# for OpenCode, OpenClaw, or both.
#
# Usage:
#   bash install.sh                  # interactive
#   bash install.sh --target opencode
#   bash install.sh --target openclaw
#   bash install.sh --target both
#   bash install.sh --target pinix
#
# Credit:
#   Original agent design & implementation: @epiral (github.com/epiral)
#   Skill packaging: @Mind-Dragon (github.com/Mind-Dragon/atoolix)

set -euo pipefail

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[0;33m'
BLU='\033[0;34m'; BLD='\033[1m'; RST='\033[0m'

info()  { echo -e "${BLU}▸${RST} $*"; }
ok()    { echo -e "${GRN}✓${RST} $*"; }
warn()  { echo -e "${YLW}⚠${RST}  $*"; }
err()   { echo -e "${RED}✗${RST} $*" >&2; exit 1; }

# ── Args ───────────────────────────────────────────────────────────────────────
TARGET=""
SKIP_PINIX=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --skip-pinix) SKIP_PINIX=true; shift ;;
    -h|--help)
      echo "Usage: bash install.sh [--target opencode|openclaw|both|pinix]"
      exit 0
      ;;
    *) warn "Unknown option: $1"; shift ;;
  esac
done

# ── Banner ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLD}atoolix installer${RST}"
echo    "Skill packaging by @Mind-Dragon — original agent by @epiral"
echo    "https://github.com/Mind-Dragon/atoolix"
echo ""

# ── Detect installed tools ─────────────────────────────────────────────────────
HAS_OPENCODE=false
HAS_OPENCLAW=false
HAS_PINIX=false
HAS_JQ=false

command -v opencode  &>/dev/null && HAS_OPENCODE=true
command -v openclaw  &>/dev/null && HAS_OPENCLAW=true
command -v pinix     &>/dev/null && HAS_PINIX=true
command -v jq        &>/dev/null && HAS_JQ=true

echo -e "Detected tools:"
$HAS_OPENCODE && echo -e "  ${GRN}✓${RST} opencode" || echo -e "  ${YLW}–${RST} opencode (not found)"
$HAS_OPENCLAW && echo -e "  ${GRN}✓${RST} openclaw" || echo -e "  ${YLW}–${RST} openclaw (not found)"
$HAS_PINIX    && echo -e "  ${GRN}✓${RST} pinix"    || echo -e "  ${YLW}–${RST} pinix (not found)"
$HAS_JQ       && echo -e "  ${GRN}✓${RST} jq"       || echo -e "  ${YLW}–${RST} jq (needed for provider detection)"
echo ""

# ── Pick install target ─────────────────────────────────────────────────────────
if [[ -z "$TARGET" ]]; then
  OPTIONS=()
  $HAS_OPENCODE && OPTIONS+=("opencode")
  $HAS_OPENCLAW && OPTIONS+=("openclaw")
  $HAS_PINIX    && OPTIONS+=("pinix")
  OPTIONS+=("opencode (install first)" "openclaw (install first)" "both")

  echo -e "${BLD}Install skill for:${RST}"
  for i in "${!OPTIONS[@]}"; do
    printf "  %d) %s\n" $((i+1)) "${OPTIONS[$i]}"
  done
  echo ""
  read -rp "Pick [1-${#OPTIONS[@]}]: " CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#OPTIONS[@]} )); then
    err "Invalid choice."
  fi
  TARGET="${OPTIONS[$((CHOICE-1))]}"
fi

# Normalize
case "$TARGET" in
  *opencode*install*) TARGET="opencode"; NEED_INSTALL_OPENCODE=true ;;
  *openclaw*install*) TARGET="openclaw"; NEED_INSTALL_OPENCLAW=true ;;
  both) ;;
  opencode|openclaw|pinix) ;;
  *) err "Unknown target: $TARGET" ;;
esac

NEED_INSTALL_OPENCODE=${NEED_INSTALL_OPENCODE:-false}
NEED_INSTALL_OPENCLAW=${NEED_INSTALL_OPENCLAW:-false}

# ── Install OpenCode if needed ──────────────────────────────────────────────────
install_opencode() {
  info "Installing OpenCode..."
  if command -v curl &>/dev/null; then
    curl -fsSL https://opencode.ai/install | bash
  else
    err "curl is required to install OpenCode."
  fi
  ok "OpenCode installed."
}

install_openclaw() {
  info "Installing OpenClaw..."
  if command -v curl &>/dev/null; then
    curl -fsSL https://openclaw.ai/install | bash
  else
    err "curl is required to install OpenClaw."
  fi
  ok "OpenClaw installed."
}

$NEED_INSTALL_OPENCODE && install_opencode
$NEED_INSTALL_OPENCLAW && install_openclaw

# ── Install Pinix + agent-clip (from epiral's repos) ───────────────────────────
maybe_install_pinix() {
  if $SKIP_PINIX; then return; fi
  if $HAS_PINIX; then
    ok "pinix already installed — skipping agent-clip setup."
    return
  fi

  echo ""
  echo -e "${BLD}Pinix / agent-clip (optional)${RST}"
  echo    "agent-clip is the original AI agent runtime this skill was built for."
  echo    "Source: https://github.com/epiral/agent-clip"
  echo    "Runtime: https://github.com/epiral/pinix"
  echo ""
  read -rp "Install Pinix + agent-clip? [y/N]: " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { info "Skipping Pinix install."; return; }

  # Detect architecture
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$ARCH" in
    arm64|aarch64) ARCH_TAG="arm64" ;;
    x86_64)        ARCH_TAG="amd64" ;;
    *) err "Unsupported architecture: $ARCH" ;;
  esac

  if [[ "$OS" != "darwin" && "$OS" != "linux" ]]; then
    err "Unsupported OS: $OS. Pinix supports macOS and Linux."
  fi

  PINIX_VERSION=$(curl -sL https://api.github.com/repos/epiral/pinix/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
  PINIX_VERSION=${PINIX_VERSION:-0.2.0}

  info "Installing Pinix v${PINIX_VERSION} (${OS}/${ARCH_TAG})..."
  mkdir -p ~/bin ~/.boxlite/rootfs

  BASE="https://github.com/epiral/pinix/releases/download/v${PINIX_VERSION}"
  curl -L "${BASE}/pinix-v${PINIX_VERSION}-${OS}-${ARCH_TAG}.tar.gz"   | tar xz -C ~/bin
  curl -L "${BASE}/boxlite-v${PINIX_VERSION}-${OS}-${ARCH_TAG}.tar.gz" | tar xz -C ~/bin
  curl -L "${BASE}/rootfs-v${PINIX_VERSION}.ext4.gz" | gunzip > ~/.boxlite/rootfs/rootfs.ext4

  ok "Pinix installed to ~/bin"

  # agent-clip: clone and build
  if command -v go &>/dev/null; then
    info "Building agent-clip from source (requires Go)..."
    CLONE_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/epiral/agent-clip "$CLONE_DIR/agent-clip"
    cd "$CLONE_DIR/agent-clip"
    make dev
    make package
    ~/bin/pinix clip install dist/agent.clip
    ok "agent-clip installed."
    cd - >/dev/null
  else
    warn "Go not found — skipping agent-clip build."
    warn "To build manually: git clone https://github.com/epiral/agent-clip && cd agent-clip && make dev && make package && pinix clip install dist/agent.clip"
  fi
}

if [[ "$TARGET" == "pinix" ]]; then
  maybe_install_pinix
fi

# ── Provider / model picker ─────────────────────────────────────────────────────

# Known providers: "key:models_or_description"
OPENCODE_PROVIDERS=(
  "anthropic:claude-opus-4-5,claude-sonnet-4-5,claude-haiku-4-5"
  "openai:gpt-4o,gpt-4o-mini,o3,o4-mini"
  "openrouter:gateway — 200+ models"
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

OPENCLAW_PROVIDERS=(
  "anthropic:claude-opus-4-5,claude-sonnet-4-5"
  "openai:gpt-4o,codex"
  "openrouter:gateway — 200+ models"
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

# Detect registered providers from config files
detect_registered_opencode() {
  local auth="${HOME}/.local/share/opencode/auth.json"
  if $HAS_JQ && [[ -f "$auth" ]]; then
    jq -r 'keys[]' "$auth" 2>/dev/null
  fi
}

detect_registered_openclaw() {
  local cfg="${HOME}/.openclaw/config.json"
  [[ -f "claw.config.json" ]] && cfg="claw.config.json"
  if $HAS_JQ && [[ -f "$cfg" ]]; then
    jq -r '.providers | keys[]' "$cfg" 2>/dev/null
  fi
}

pick_model() {
  local -n _providers=$1
  local detect_fn=$2

  mapfile -t REGISTERED < <($detect_fn 2>/dev/null || true)

  echo ""
  echo -e "${BLD}Pick a model provider${RST}"
  if [[ ${#REGISTERED[@]} -gt 0 ]]; then
    echo -e "  (${GRN}✓${RST} = already registered / API key found)"
  fi
  echo ""

  local idx=1
  declare -a KEYS=()
  declare -a MODELS=()

  for entry in "${_providers[@]}"; do
    local key="${entry%%:*}"
    local models="${entry#*:}"
    local mark=""
    for r in "${REGISTERED[@]:-}"; do
      [[ "$r" == "$key" ]] && mark=" ${GRN}✓${RST}" && break
    done
    printf "  %2d) %-20s %s%b\n" "$idx" "$key" "$models" "$mark"
    KEYS+=("$key")
    MODELS+=("$models")
    ((idx++))
  done

  echo ""
  read -rp "Pick [1-$((idx-1))]: " CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE >= idx )); then
    err "Invalid choice."
  fi

  SELECTED_PROVIDER="${KEYS[$((CHOICE-1))]}"
  local mods="${MODELS[$((CHOICE-1))]}"
  local first_model
  first_model=$(echo "$mods" | cut -d',' -f1 | xargs)
  if echo "$first_model" | grep -qE 'gateway|local|proxy|via'; then
    first_model="<choose-a-model>"
  fi
  SELECTED_MODEL="${SELECTED_PROVIDER}/${first_model}"
}

# ── Install skill for OpenCode ──────────────────────────────────────────────────
install_skill_opencode() {
  echo ""
  echo -e "${BLD}Installing skill: nix-agent-tool-design → OpenCode${RST}"

  SKILL_RAW="https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md"

  read -rp "Install globally (~/.config/opencode) or project-local (.opencode)? [G/p]: " scope
  if [[ "$scope" =~ ^[Pp]$ ]]; then
    SKILL_DIR=".opencode/skills/nix-agent-tool-design"
  else
    SKILL_DIR="${HOME}/.config/opencode/skills/nix-agent-tool-design"
  fi

  mkdir -p "$SKILL_DIR"
  curl -fsSL "$SKILL_RAW" -o "${SKILL_DIR}/SKILL.md"
  ok "Skill installed to ${SKILL_DIR}/SKILL.md"

  # Model picker
  pick_model OPENCODE_PROVIDERS detect_registered_opencode

  # Determine config target
  if [[ "$scope" =~ ^[Pp]$ ]]; then
    CFG_FILE="opencode.json"
  else
    CFG_FILE="${HOME}/.config/opencode/opencode.json"
  fi

  echo ""
  echo -e "${BLD}Recommended model config${RST} (add to ${CFG_FILE}):"
  echo ""
  cat <<EOF
{
  "model": "${SELECTED_MODEL}"
}
EOF

  echo ""
  read -rp "Write model config to ${CFG_FILE}? [y/N]: " write_cfg
  if [[ "$write_cfg" =~ ^[Yy]$ ]]; then
    if [[ -f "$CFG_FILE" ]]; then
      # Merge: add/overwrite "model" key using jq if available
      if $HAS_JQ; then
        TMP=$(mktemp)
        jq --arg m "$SELECTED_MODEL" '.model = $m' "$CFG_FILE" > "$TMP" && mv "$TMP" "$CFG_FILE"
        ok "Updated model in ${CFG_FILE}"
      else
        warn "jq not found — please add manually: \"model\": \"${SELECTED_MODEL}\""
      fi
    else
      mkdir -p "$(dirname "$CFG_FILE")"
      printf '{\n  "model": "%s"\n}\n' "$SELECTED_MODEL" > "$CFG_FILE"
      ok "Created ${CFG_FILE}"
    fi
  fi
}

# ── Install skill for OpenClaw ──────────────────────────────────────────────────
install_skill_openclaw() {
  echo ""
  echo -e "${BLD}Installing skill: nix-agent-tool-design → OpenClaw${RST}"

  SKILL_RAW="https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md"

  read -rp "Install globally (~/.openclaw) or workspace-local? [G/w]: " scope
  if [[ "$scope" =~ ^[Ww]$ ]]; then
    SKILL_DIR="skills/nix-agent-tool-design"
  else
    SKILL_DIR="${HOME}/.openclaw/skills/nix-agent-tool-design"
  fi

  mkdir -p "$SKILL_DIR"
  curl -fsSL "$SKILL_RAW" -o "${SKILL_DIR}/SKILL.md"
  ok "Skill installed to ${SKILL_DIR}/SKILL.md"

  # Model picker
  pick_model OPENCLAW_PROVIDERS detect_registered_openclaw

  echo ""
  echo -e "${BLD}Recommended model config${RST} (add to your OpenClaw config):"
  echo ""
  cat <<EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "${SELECTED_MODEL}"
      }
    }
  }
}
EOF
  echo ""
  warn "Merge the above into your claw.config.json (or ~/.openclaw/config.json)."
}

# ── Run installs ────────────────────────────────────────────────────────────────
case "$TARGET" in
  opencode)
    install_skill_opencode
    ;;
  openclaw)
    install_skill_openclaw
    ;;
  both)
    install_skill_opencode
    install_skill_openclaw
    ;;
  pinix)
    maybe_install_pinix
    echo ""
    echo -e "${BLD}Configure your LLM provider${RST}"
    echo    "Edit data/config.yaml in your agent-clip directory:"
    echo ""
    cat <<'EOF'
llm_provider: openrouter
llm_model: anthropic/claude-3.5-haiku
providers:
  openrouter:
    base_url: https://openrouter.ai/api/v1
    api_key: <your-openrouter-key>
EOF
    ;;
esac

# ── Done ────────────────────────────────────────────────────────────────────────
echo ""
ok "All done."
echo ""
echo -e "${BLD}Quick test:${RST}"
case "$TARGET" in
  opencode) echo '  opencode  →  type: /skills  (should list nix-agent-tool-design)' ;;
  openclaw) echo '  openclaw  →  run: openclaw skills list' ;;
  both)
    echo '  opencode  →  type: /skills'
    echo '  openclaw  →  run: openclaw skills list'
    ;;
  pinix)
    echo '  boxlite serve --port 8100 &'
    echo '  pinix serve --addr :9875 --boxlite-rest http://localhost:8100'
    echo '  bin/agent-local send -p "hello"'
    ;;
esac
echo ""
