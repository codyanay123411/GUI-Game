# Changelog

## 2026-08-23

Set up the local Roblox + Cursor development environment.

- Configured the Cursor local agent to run on this PC
- Connected and tested Roblox Studio MCP
- Configured and tested Script Sync for disk-backed Luau
- Initialized the Git repository
- Added a `.gitignore` for temp files, caches, logs, OS metadata, editor local state, and Studio place/lock files
- Removed the temporary Script Sync verification script
- Added this `AI/` tracker (`PROGRESS.md`, `DECISIONS.md`, `CHANGELOG.md`)

## 2026-08-23 — Architecture bootstrap

Added the source-controlled GUI-first layout (server/client/shared folders, thin bootstraps, `docs/ARCHITECTURE.md`). Verified the paths on disk. Did not mark Studio Script Sync appearance complete because Studio MCP had no connected instance in that session.

## 2026-08-23 — Client Script Sync path correction

Moved client files from nested `StarterPlayer/StarterPlayerScripts/` into root `StarterPlayerScripts/` (`Bootstrap.client.luau`, `Controllers/`). Deleted the duplicate `StarterPlayer/` directory. Disk mapping is now `StarterPlayerScripts/` → Studio `StarterPlayer.StarterPlayerScripts`.

## 2026-08-23 — Studio architecture verification

Added `_Placeholder.luau` ModuleScripts so reserved Script Sync folders appear in Studio. Verified `ServerScriptService.Services`, `ReplicatedStorage.Shared` (`Config`/`Types`/`Util`), `ReplicatedStorage.Remotes`, and `StarterPlayer.StarterPlayerScripts.Controllers`. Bootstraps still match disk.
