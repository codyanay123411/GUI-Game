# Decisions

Substantial architectural decisions belong in this file. Do not silently reverse them later. If a decision changes, record the new decision and why the previous one was replaced.

## Development workflow

- **Cursor Local Agent on This PC.** Local agent work runs on this machine, not a remote cloud agent, unless a later decision says otherwise.
- **Roblox Studio MCP.** Use Studio MCP for direct Studio interaction and playtesting (hierarchy inspection, running Studio, checking output, and related agent-driven Studio work).
- **Script Sync.** Version-controlled Luau lives on disk and stays in sync with Studio through Script Sync. `.luau` files are the source of truth for scripts.
- **Git / GitHub.** Use Git for history and rollback. A private GitHub remote is intended for backup and collaboration once published.

## Product direction

- This project is intended to be **primarily GUI-based**. Prefer interface-driven play over 3D world gameplay unless a later decision explicitly expands scope.
