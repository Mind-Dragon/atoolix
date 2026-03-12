# atoolix

A collection of agent tool design skills for [OpenCode](https://opencode.ai) and [OpenClaw](https://github.com/openclaw/openclaw).

Curated by [@Mind-Dragon](https://github.com/Mind-Dragon).

---

## Skills

### [nix-agent-tool-design](./nix-agent-tool-design/SKILL.md)

**Credit:** This skill was authored by the backend lead at [Manus](https://manus.im), distilled from their open-source [agent-clip](https://github.com/epiral/agent-clip) runtime ([@epiral](https://github.com/epiral)). All design credit belongs to them — this repo packages it as an installable skill.

Applies the *nix Agent design philosophy to agent tool interfaces — single `run()` tool, CLI over function calling, two-layer execution/presentation architecture, progressive `--help` discovery, and error-as-navigation.

Distilled from 2 years of production agent work at Manus. The full implementation lives in:
- **[epiral/agent-clip](https://github.com/epiral/agent-clip)** — the agent as a Pinix Clip (Go)
- **[epiral/pinix](https://github.com/epiral/pinix)** — the decentralized runtime platform that hosts Clips

See [INSTALL.md](./nix-agent-tool-design/INSTALL.md) for setup instructions (OpenCode, OpenClaw, and Pinix).

---

## License

MIT — skill packaging by @Mind-Dragon. Original design by [@epiral](https://github.com/epiral).
