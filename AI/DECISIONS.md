# Decisions

Substantial architectural decisions belong in this file. Do not silently reverse them later. If a decision changes, record the new decision and why the previous one was replaced.

## Development workflow

- **Cursor Local Agent on This PC.** Local agent work runs on this machine, not a remote cloud agent, unless a later decision says otherwise.
- **Roblox Studio MCP.** Use Studio MCP for direct Studio interaction and playtesting (hierarchy inspection, running Studio, checking output, and related agent-driven Studio work).
- **Script Sync.** Version-controlled Luau lives on disk and stays in sync with Studio through Script Sync. `.luau` files are the source of truth for scripts.
- **Empty Script Sync folders.** Script Sync does not create Studio folders that contain no `.luau` files. Reserved directories keep a `_Placeholder.luau` ModuleScript that returns `{}` solely so the folder appears in Studio. Delete that placeholder when the folder has real project files. Do not put gameplay in placeholders.
- **Git / GitHub.** Use Git for history and rollback. A private GitHub remote is intended for backup and collaboration once published.

## Product direction

- This project is intended to be **primarily GUI-based**. Prefer interface-driven play over 3D world gameplay unless a later decision explicitly expands scope.

## Source layout

- **Server** lives under `ServerScriptService`. `Services/` is reserved for authoritative server-side systems. `Bootstrap.server.luau` is a thin orchestrator only.
- **Client** lives under root-level `StarterPlayerScripts/` on disk, which Script Sync maps to `StarterPlayer.StarterPlayerScripts` in Studio. Do not use a nested `StarterPlayer/StarterPlayerScripts/` disk path. `Controllers/` is reserved for client behavior and GUI control. `Bootstrap.client.luau` is a thin orchestrator only.
- **Shared** lives under `ReplicatedStorage/Shared` (`Config/`, `Types/`, `Util/`). Shared modules must be safe for both sides and must not grant the client authority.
- **Remotes** live under `ReplicatedStorage/Remotes`. That folder is reserved for RemoteEvents and RemoteFunctions. Remote instances are created in Studio, not as Luau files.
- **GUI instances are not source-controlled as files.** They are created and edited through Roblox Studio MCP / Studio. Controllers drive GUI behavior; Services own authoritative state and validation.
- **The client is never trusted** for authoritative game decisions.
- Avoid monolithic scripts. Do not introduce frameworks or external dependencies unless a later decision records that change.
