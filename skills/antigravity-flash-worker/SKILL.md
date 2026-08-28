---
name: antigravity-flash-worker
description: Delegate scoped code investigation, error triage, codebase reading, test generation, and targeted bug fixes to the Antigravity Gemini 3.7 Flash sub-agent worker via agy-mcp.
---

# Antigravity Flash Worker Delegation Skill

## Overview

Use this skill when you (the primary orchestrating agent, Codex) want to offload scoped investigations, rapid codebase indexing, test generation, or targeted bug fixes to the **Google Antigravity Gemini 3.7 Flash** worker via the `agy` Model Context Protocol (MCP) server (`tphakala/agy-mcp`).

The Antigravity worker operates as a **subordinate specialist worker**. It performs fast, autonomous executions within the designated workspace. **All final architectural judgements, safety reviews, test verifications, and quality decisions remain strictly with the primary agent (Codex).**

---

## Delegation Matrix

### Suitable Tasks for Delegation

- **Codebase Exploration & Scanning**: Identifying tech stack, entrypoints, directory layouts, configuration files, and build scripts.
- **Symbol & Reference Tracing**: Locating class, method, function, or type definitions and references across multi-file repositories.
- **Log & Traceback Triage**: Analyzing stack traces, crash dumps, and build failure logs to pinpoint exact failing files and lines.
- **Scoped Bug Diagnosis & Fix**: Investigating well-defined bugs in isolated functions/modules and verifying via existing unit tests.
- **Test Generation & Coverage**: Writing complementary unit or integration tests for existing modules.
- **Documentation & Code Summarization**: Summarizing complex modules, architectural concepts, or legacy code.

### Prohibited / Non-Delegated Tasks

DO NOT delegate the following tasks to the worker; perform and decide these directly:
- **Core Architecture & Schema Design**: Defining cross-cutting boundaries, database schemas, and public API contracts.
- **Security, Auth & Secret Management**: Handling cryptographic keys, credentials, authentication flows, or permission models.
- **Destructive File Operations**: Bulk deletions, git history rewrites, or unversioned disk purges.
- **Ambiguous Requirements**: Tasks requiring user product trade-offs, preference clarification, or human guidance.

---

## MCP Tool Invocation Protocol

The worker is accessed via the `agy` MCP server tools:

### 1. Synchronous Scoped Execution (`agy_run_sync`)
Use `agy_run_sync` for quick, interactive tasks (bounded wait, default up to 10 minutes):

- `prompt`: Self-contained, explicit task description with clear instructions, acceptance criteria, and constraints.
- `cwd`: Absolute path to the target repository or workspace.
- `model`: Target model ID (default recommended: `gemini-3.7-flash-high`).
- `dirs`: (Optional) Additional directory paths if the task references external dependencies.

```json
{
  "prompt": "Inspect calculator.py for the discount calculation bug. Fix the issue and run python3 test_calculator.py to verify.",
  "cwd": "/path/to/target-repo",
  "model": "gemini-3.7-flash-high"
}
```

### 2. Asynchronous / Long-Running Tasks (`agy_run` + `agy_wait`)
Use `agy_run` when kicking off long tasks or running multiple tasks concurrently:

1. Call `agy_run` with `prompt`, `cwd`, and `model`. It immediately returns a `job_id` and initial state (`running`).
2. Call `agy_status` for non-blocking progress snapshots.
3. Call `agy_wait` with `job_id` to block until the job completes and receive the final result.
4. If a running job needs to be aborted, call `agy_cancel` with `job_id` to cleanly terminate the process tree.

### 3. Multi-Turn Conversation Continuation
When a follow-up task builds upon previous worker context:
- Extract `conversation_id` from the previous turn's response.
- Pass `conversation_id` in subsequent `agy_run` or `agy_run_sync` calls to maintain session memory without repeating context.

---

## Safety & Isolation Guidelines

1. **Workspace Boundary**: Always provide an explicit, dedicated `cwd`. Never delegate with root (`/`), home directories (`~`), or system directories as `cwd`.
2. **Git Worktree Isolation (Recommended for High-Risk Changes)**:
   For high-risk, broad, or speculative code modifications:
   - Primary agent creates an isolated Git worktree: `git worktree add ../feature-worktree -b feature-branch`.
   - Pass `../feature-worktree` as `cwd` to the worker.
   - Inspect and verify changes in the worktree before merging into the main working tree.
3. **Verification Protocol**:
   - Inspect `git status` and `git diff` after worker execution.
   - Independently run the test suite to ensure all assertions pass.
   - Review worker modifications before finalizing output to the user.
