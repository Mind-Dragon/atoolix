# *nix Agent Tool Design — Install Guide

Three install targets: **OpenCode**, **OpenClaw**, and **Pinix** (the original runtime this design was built for).

---

## Option A: Run the Original App (Pinix + agent-clip)

This skill was built *inside* Pinix by [@epiral](https://github.com/epiral). If you want the full experience, run the original app.

### 1. Install Pinix (macOS arm64)

```bash
# Create dirs
mkdir -p ~/bin ~/.boxlite/rootfs

# Download binaries
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

# Add your API key to data/config.yaml (after make dev)
make dev

# Build and package
make package                          # → dist/agent.clip
pinix clip install dist/agent.clip    # install
```

### 4. Configure

Edit `data/config.yaml`:
```yaml
name: pi
providers:
  openrouter:
    base_url: https://openrouter.ai/api/v1
    api_key: <your-key>
llm_provider: openrouter
llm_model: anthropic/claude-3.5-haiku
```

### 5. Chat

```bash
bin/agent-local send -p "hello"
```

The agent inside Pinix uses the exact tool design described in SKILL.md natively.

---

## Option B: Install as OpenCode Skill

### Global install (all OpenCode sessions)

```bash
mkdir -p ~/.config/opencode/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o ~/.config/opencode/skills/nix-agent-tool-design/SKILL.md
```

### Project-scoped install

```bash
mkdir -p .opencode/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o .opencode/skills/nix-agent-tool-design/SKILL.md
```

#### Optional: configure permissions in `opencode.json`

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

### Global install

```bash
mkdir -p ~/.openclaw/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o ~/.openclaw/skills/nix-agent-tool-design/SKILL.md
```

### Workspace-scoped install

```bash
mkdir -p <your-workspace>/skills/nix-agent-tool-design
curl -L https://raw.githubusercontent.com/Mind-Dragon/atoolix/main/nix-agent-tool-design/SKILL.md \
  -o <your-workspace>/skills/nix-agent-tool-design/SKILL.md
```

### Verify

```bash
openclaw skills list
openclaw skills info nix-agent-tool-design
```

---

## Trigger Phrases

The skill activates when you use any of these:

- "design agent tools"
- "single run tool"
- "CLI for agents"
- "tool interface design"
- "agent tool architecture"
- "function calling vs CLI"
- "overflow mode"
- "binary guard"
- "agent output format"

---

## Credits

Original design and implementation by [@epiral](https://github.com/epiral):
- [epiral/agent-clip](https://github.com/epiral/agent-clip) — the agent runtime
- [epiral/pinix](https://github.com/epiral/pinix) — the decentralized Clip platform

Skill packaging by [@Mind-Dragon](https://github.com/Mind-Dragon).
