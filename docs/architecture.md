# Architecture & Design

## Overview

`codex-antigravity-worker` defines the orchestration, delegation policies, and integration layer connecting **OpenAI Codex** with **Google Antigravity CLI (`agy`)** via the standard Model Context Protocol (MCP) implementation provided by [`tphakala/agy-mcp`](https://github.com/tphakala/agy-mcp).

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
│  - Process Tree Supervisor & Lock Management                │
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

---

## Key Architectural Principles

### 1. Clear Division of Responsibility
- **OpenAI Codex (Primary Agent)**: Owns system-level context, task breakdown, architectural governance, multi-step planning, final diff validation, and user interaction.
- **Antigravity Gemini 3.7 Flash (Subordinate Worker)**: Operates as a fast, autonomous execution sub-agent for self-contained, mechanical, or scoped tasks (e.g., codebase indexing, symbol tracing, error triage, localized bug fixing).

### 2. Standard MCP Protocol
- Communication strictly follows standard Model Context Protocol (JSON-RPC over stdio).
- Standard tool annotations (`destructiveHint`, `readOnlyHint`, `idempotentHint`, `openWorldHint`) allow Codex to make informed execution decisions.

### 3. Execution Models

| Execution Model | MCP Tool | Best For |
|---|---|---|
| **Synchronous Bounded** | `agy_run_sync` | Quick tasks expected to complete within seconds to minutes (code reading, targeted bug fixes, test runs). Blocks inline up to a configured timeout. |
| **Asynchronous Detached** | `agy_run` → `agy_status` / `agy_wait` | Long-running tasks or parallel executions. Returns immediately with a `job_id`, allowing status polling and late blocking. |
| **Conversation Continuation**| `conversation_id` parameter | Multi-turn refinement where subsequent tasks inherit context from previous turns without restating the prompt. |

### 4. Process Tree Lifecycle & Cancellation
- **POSIX (macOS / Linux)**: Managed via dedicated process groups (`setpgid`) with coordinated `SIGTERM` / `SIGKILL` cascade signaling.
- **Windows (Win32)**: Managed via native Windows Job Objects (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`), ensuring that terminating the supervisor immediately terminates all grandchild subprocesses without orphaned processes.

---

## Safety & Isolation Architecture

### Unattended Execution Boundary
To enable autonomous sub-agent execution without interactive terminal approval prompts, `agy-mcp` launches `agy` with `--dangerously-skip-permissions`. To safeguard system integrity, the following boundaries are enforced:

1. **Scoped Working Directory (`cwd`)**:
   - Every delegation requires an explicit, restricted directory path.
   - Never use root (`/`), home (`~`), or system configuration paths as `cwd`.

2. **Git Worktree Isolation Pattern**:
   - For high-entropy or speculative tasks, Codex creates an ephemeral Git worktree:
     ```bash
     git worktree add ../isolated-worker-task -b worker-task-branch
     ```
   - Codex delegates to `agy-mcp` with `cwd = "../isolated-worker-task"`.
   - After verification, Codex merges or discards the worktree cleanly.

3. **Mandatory Primary Agent Verification**:
   - Codex always inspects `git status`, `git diff`, and executes automated tests before declaring a task complete.
