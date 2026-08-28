# Codex Antigravity Worker

An orchestration and delegation integration layer enabling **OpenAI Codex** to leverage **Google Antigravity CLI (`agy`)** as a high-speed, autonomous sub-agent worker (powered by **Gemini 3.7 Flash**) via the standard Model Context Protocol (MCP).

---

## 📌 Project Scope & Positioning

> **Important**: This repository is **not** an Antigravity MCP Server implementation.
>
> We do not fork, copy, or duplicate underlying MCP server or CLI code. Instead, this project provides the **Codex delegation policies, MCP configuration templates, sub-agent skills, and platform setup automation** necessary to connect:
>
> **OpenAI Codex** → [`tphakala/agy-mcp`](https://github.com/tphakala/agy-mcp) (MCP Server) → **Google Antigravity CLI (`agy`)** → **Gemini 3.7 Flash (Worker)**

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Primary Agent: Codex                     │
│                (Planning, Architecture, Synthesis)          │
└──────────────────────────────┬──────────────────────────────┘
                               │ Model Context Protocol (MCP stdio)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    MCP Server: agy-mcp                      │
│             (tphakala/agy-mcp Go Supervised Daemon)         │
│  - agy_run / agy_run_sync / agy_wait / agy_status / agy_cancel
│  - Native Process Tree Supervisor & Lock Management         │
│  - Stream-JSON Event Stream Decoder                         │
└──────────────────────────────┬──────────────────────────────┘
                               │ Subprocess: agy --output-format stream-json
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Google Antigravity CLI (agy)                │
│               - Unattended Tool Auto-Approval               │
│               - Multi-Turn Conversation State               │
└──────────────────────────────┬──────────────────────────────┘
                               │ Google Cloud / Antigravity API
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            Autonomous Worker: Gemini 3.7 Flash              │
│       (Fast Code Exploration, Analysis, Scoped Edits)       │
└─────────────────────────────────────────────────────────────┘
```

For detailed architectural specifications, see [docs/architecture.md](docs/architecture.md).

---

## ⚡ Prerequisites

1. **Google Antigravity CLI (`agy`)**: Installed and authenticated on your machine.
2. **`agy-mcp`**: The upstream Go-based MCP server from [tphakala/agy-mcp](https://github.com/tphakala/agy-mcp).
   - **macOS (Homebrew)**: `brew install tphakala/tap/agy-mcp`
   - **Manual Binary**: Download from [tphakala/agy-mcp Releases](https://github.com/tphakala/agy-mcp/releases).

---

## 🚀 Quick Start

### macOS / Linux

1. Clone this repository:
   ```bash
   git clone https://github.com/<owner>/codex-antigravity-worker.git
   cd codex-antigravity-worker
   ```
2. Run the installer:
   ```bash
   ./scripts/install-macos.sh
   ```
3. Run the automated smoke test:
   ```bash
   ./scripts/smoke-test.sh
   ```

---

### Windows 11 *(Prepared & Structured; Pending Formal Verification)*

1. Open PowerShell and run:
   ```powershell
   .\scripts\install-windows.ps1
   ```
2. Configure your `%USERPROFILE%\.codex\config.toml` using the provided template.

---

## ⚙️ Codex MCP Configuration

Add the `agy` MCP server to your `~/.codex/config.toml` (macOS/Linux) or `%USERPROFILE%\.codex\config.toml` (Windows):

```toml
[mcp_servers.agy]
command = "agy-mcp"
args = []
```

### Custom Path & Proxy Configuration (Optional)

If `agy` or `agy-mcp` is located outside standard PATH, or your network requires an HTTP/HTTPS proxy to reach Google APIs:

```toml
[mcp_servers.agy]
command = "/Users/<username>/.local/bin/agy-mcp"

[mcp_servers.agy.env]
AGY_MCP_AGY_PATH = "/Users/<username>/.local/bin/agy"
PATH = "/Users/<username>/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Optional proxy (if needed in restricted network environments):
# HTTP_PROXY = "http://127.0.0.1:10808"
# HTTPS_PROXY = "http://127.0.0.1:10808"
# ALL_PROXY = "socks5://127.0.0.1:10808"
```

A full annotated template is available in [`config/codex-mcp.example.toml`](config/codex-mcp.example.toml).

---

## 🧠 Codex Delegation Skill (`antigravity-flash-worker`)

This repository installs the [`antigravity-flash-worker`](skills/antigravity-flash-worker/SKILL.md) skill into Codex (`~/.codex/skills/antigravity-flash-worker/`).

### When Codex Delegates
- **Fast Codebase Discovery**: Mapping entrypoints, build files, and module structures.
- **Symbol / Reference Lookup**: Tracing functions and types across multi-file codebases.
- **Error & Log Triage**: Pinpointing root-cause files and lines from stack traces.
- **Targeted Bug Fixes & Unit Tests**: Fixing localized bugs and writing verifying unit tests.

### Delegation Boundary & Safety
- **Primary Agent Authority**: Codex reviews diffs, runs test suites, and makes all architectural decisions.
- **Unattended Execution**: Runs with `--dangerously-skip-permissions` inside the assigned `cwd` for autonomous execution.
- **High-Risk Worktree Pattern**: For broad or speculative changes, Codex can create an isolated Git worktree (`git worktree add ../temp-worktree`) and delegate execution there before merging.

---

## 📄 License & Upstream Attribution

- Upstream MCP Server: [`tphakala/agy-mcp`](https://github.com/tphakala/agy-mcp) (MIT License)
- Google Antigravity CLI: [Google Antigravity](https://antigravity.google/)
