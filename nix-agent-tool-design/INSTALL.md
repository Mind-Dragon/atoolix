# *nix Agent Tool Design — Install Guide

Three install targets: **OpenCode**, **OpenClaw**, and **Pinix** (the original runtime this design was built for).

---

## Option A: Run the Original App (Pinix + agent-clip)

This skill was built *inside* Pinix by [@epiral](https://github.com/epiral). If you want the full experience, run the original app.

### 1. Install Pinix (macOS arm64)

```bash
mkdir -p ~/bin ~/.boxlite/rootfs
curl -L https://github.com/epiral/pinix/releases/latest/download/pinix-v0.2.0-darwin-arm64.tar.gz | tar xz -C ~/bin
curl -L https://github.com/epiral/pinix/releases/latest/download/boxlite-v0.2.0-darwin-arm64.tar.gz | tar xz -C ~/bin
curl -L https://github.com/epiral/pinix/releases/latest/download/rootfs-v0.2.0.ext4.gz | gunzip > ~/.boxlite/rootfs/rootfs.ext4
```

> Or use **Clip Dock Desktop** which bundles everything: see [epiral/pinix releases](https://github.com/epiral/pinix/releases)

### 2. Start the server

```bash
boxlite serve --port 8100 &
pinix serve --addr :9875 --boxlite-rest http://localhost:8100
```

### 3. Build and install agent-clip

```bash
git clone https://github.com/epiral/agent-clip
cd agent-clip
make dev
make package
pinix clip install dist/agent.clip
```

### 4. Pick your API provider

The installer will scan your registered OpenCode and OpenClaw providers and let you choose:

```bash
bash <(curl -sL https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/scripts/pick-provider.sh) \
  --target pinix \
  --config agent-clip/data/config.yaml
```

Or configure manually — edit `data/config.yaml`:

```yaml
name: pi
providers:
  openrouter:
    base_url: https://openrouter.ai/api/v1
    api_key: <your-key>
llm_provider: openrouter
llm_model: anthropic/claude-3.5-haiku
embedding_provider: openrouter
embedding_model: openai/text-embedding-3-small
```

### 5. Chat

```bash
bin/agent-local send -p "hello"
```

---

## Option B: Install as OpenCode Skill

### 1. Install the skill file

**Global (all sessions):**
```bash
mkdir -p ~/.config/opencode/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o ~/.config/opencode/skills/nix-agent-tool-design/SKILL.md
```

**Project-scoped:**
```bash
mkdir -p .opencode/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o .opencode/skills/nix-agent-tool-design/SKILL.md
```

### 2. Pick a provider

Run this to scan your already-registered OpenCode providers and pick one:

```bash
bash <(curl -sL https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/scripts/pick-provider.sh) \
  --target opencode
```

This reads `~/.local/share/opencode/auth.json` (where OpenCode stores API keys added via `/connect`) and presents a numbered menu:

```
Registered OpenCode providers:
  1) anthropic      claude-opus-4-5, claude-sonnet-4-5, claude-haiku-4-5
  2) openai         gpt-4o, gpt-4o-mini, o3, o4-mini
  3) openrouter     (gateway — 200+ models)
  4) groq           llama-3.3-70b, gemma2-9b
  5) ollama         llama3.2, mistral (local)

Pick a provider [1-5]: _
```

After selection, outputs the recommended `opencode.json` model config snippet:

```json
{
  "model": "anthropic/claude-sonnet-4-5"
}
```

Append to your `~/.config/opencode/opencode.json` or project `opencode.json`.

**Supported OpenCode providers** (75+ via AI SDK / Models.dev):[^1]

| Provider | Config key | Notes |
|----------|-----------|-------|
| Anthropic | `anthropic` | Claude Opus/Sonnet/Haiku |
| OpenAI | `openai` | GPT-4o, o3, o4-mini |
| OpenRouter | `openrouter` | Gateway to 200+ models |
| Google Vertex | `vertex` | Gemini models |
| Amazon Bedrock | `bedrock` | AWS region required |
| Azure OpenAI | `azure` | Deployment name required |
| Groq | `groq` | Fast inference |
| DeepSeek | `deepseek` | DeepSeek R2, V3 |
| Mistral | `mistral` | Mistral Large, Codestral |
| xAI | `xai` | Grok models |
| Together AI | `together` | Open model hosting |
| Fireworks AI | `fireworks` | Fast open models |
| Cerebras | `cerebras` | Ultra-fast inference |
| LiteLLM | `litellm` | Local proxy / unified gateway |
| Ollama | `ollama` | Local models, no key needed |
| vLLM | `vllm` | Local models, no key needed |

[^1]: Full list at https://opencode.ai/docs/providers/

### 3. Configure permissions (optional)

```json
{
  "permission": {
    "skill": {
      "nix-agent-tool-design": "allow"
    }
  }
}
```

---

## Option C: Install as OpenClaw Skill

### 1. Install the skill file

**Global:**
```bash
mkdir -p ~/.openclaw/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o ~/.openclaw/skills/nix-agent-tool-design/SKILL.md
```

**Workspace-scoped:**
```bash
mkdir -p <your-workspace>/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o <your-workspace>/skills/nix-agent-tool-design/SKILL.md
```

### 2. Pick a provider

```bash
bash <(curl -sL https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/scripts/pick-provider.sh) \
  --target openclaw
```

This reads your OpenClaw config (`~/.openclaw/config.json` or `claw.config.json`) for registered providers and presents a numbered menu:

```
Registered OpenClaw providers:
  1) anthropic      claude-opus-4-5, claude-sonnet-4-5
  2) openrouter     (gateway — 200+ models)
  3) ollama         llama3.2 (local)

Pick a provider [1-3]: _
```

After selection, outputs the model config snippet for OpenClaw:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-5"
      }
    }
  }
}
```

**Supported OpenClaw providers** (23+ documented):[^2]

| Provider | Config key | Notes |
|----------|-----------|-------|
| Anthropic | `anthropic` | Claude Opus/Sonnet/Haiku |
| OpenAI | `openai` | GPT-4o, Codex |
| OpenRouter | `openrouter` | Gateway — recommended for flexibility |
| Amazon Bedrock | `bedrock` | AWS credentials required |
| Google Vertex | `vertex` | Gemini models |
| Mistral | `mistral` | Mistral Large, Codestral |
| Groq | `groq` | Fast Llama/Gemma inference |
| DeepSeek | `deepseek` | R2, V3 |
| Together AI | `together` | Open model hosting |
| Fireworks AI | `fireworks` | Fast open models |
| Cloudflare AI | `cloudflare` | Edge inference |
| LiteLLM | `litellm` | Local proxy / unified gateway |
| Ollama | `ollama` | Local models, no key needed |
| vLLM | `vllm` | Local models, no key needed |
| NVIDIA | `nvidia` | NIM inference |
| Venice | `venice` | Privacy-focused inference |
| xAI | `xai` | Grok models |
| Vercel AI Gateway | `vercel` | Managed gateway |

[^2]: Full list at https://docs.openclaw.ai/providers

### 3. Verify

```bash
openclaw skills list
openclaw skills info nix-agent-tool-design
```

---

## The `pick-provider.sh` Script

The script does the following:

1. Detects `--target` (opencode / openclaw / pinix)
2. Reads the relevant auth/config file:
   - OpenCode: `~/.local/share/opencode/auth.json`
   - OpenClaw: `~/.openclaw/config.json` or `claw.config.json` in CWD
   - Pinix: `data/config.yaml` (path from `--config`)
3. Lists registered providers with their available models
4. Prompts user to pick one
5. Outputs the config snippet (or writes it directly with `--write`)

**Options:**
```
--target opencode|openclaw|pinix   Required. Which tool to configure.
--config <path>                    Config file path (pinix only, default: data/config.yaml)
--write                            Write config snippet directly instead of printing
--dry-run                          Show what would be written without writing
```

---

## Trigger Phrases

The skill activates on:
- "design agent tools" / "single run tool"
- "CLI for agents" / "tool interface design"
- "function calling vs CLI" / "overflow mode"
- "binary guard" / "agent output format"
- "two-layer architecture" / "error as navigation"

---

## Credits

Original design and implementation by [@epiral](https://github.com/epiral):
- [epiral/agent-clip](https://github.com/epiral/agent-clip) — the agent runtime
- [epiral/pinix](https://github.com/epiral/pinix) — the decentralized Clip platform

Skill packaging by [@Mind-Dragon](https://github.com/Mind-Dragon).
