# *nix Agent Tool Design — Install Guide

Two install targets: **OpenCode** and **OpenClaw**. The `SKILL.md` content is identical; only the install path differs.

---

## OpenCode

### Global install (applies to all your OpenCode sessions)

```bash
mkdir -p ~/.config/opencode/skills/nix-agent-tool-design
cp SKILL.md ~/.config/opencode/skills/nix-agent-tool-design/SKILL.md
```

### Project-scoped install (applies only inside a specific repo)

```bash
mkdir -p .opencode/skills/nix-agent-tool-design
cp SKILL.md .opencode/skills/nix-agent-tool-design/SKILL.md
```

OpenCode will automatically discover the skill and surface it as `nix-agent-tool-design` in `<available_skills>`.

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

## OpenClaw

### Global install (applies to all agents on your machine)

```bash
mkdir -p ~/.openclaw/skills/nix-agent-tool-design
cp SKILL.md ~/.openclaw/skills/nix-agent-tool-design/SKILL.md
```

### Workspace-scoped install (applies to one agent/project)

```bash
mkdir -p <your-workspace>/skills/nix-agent-tool-design
cp SKILL.md <your-workspace>/skills/nix-agent-tool-design/SKILL.md
```

### Verify install

```bash
openclaw skills list
openclaw skills info nix-agent-tool-design
```

---

## Trigger Phrases

The skill activates when you (or the agent) uses any of these:

- "design agent tools"
- "single run tool"
- "CLI for agents"
- "tool interface design"
- "agent tool architecture"
- "function calling vs CLI"
- "overflow mode"
- "binary guard"
- "agent output format"

Or just ask the agent to "apply nix agent design" during an agent architecture session.
