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

## 2026-08-23 — Project knowledge system

Added `AI/GAME_DESIGN.md` (authoritative vision placeholders), `AI/ROADMAP.md` (16 ordered phases; current phase 1), and `.cursor/rules/project.mdc` (always-apply agent workflow). No gameplay implemented.

## 2026-08-23 — Design bible v0.1

Replaced design placeholders with the director-authored multiplayer feudal strategy bible: ~30-minute matches, ~50 players, GUI-first shared political world, subordination as gameplay not elimination. No gameplay implemented.

## 2026-08-23 — Political Hierarchy Design V0.1

Documented four landed ranks (Lord → Duke → King → Emperor), independent-Lord start with one territory, independence vs rank, direct/indirect vassals, voluntary vassalage rank rules, preserved subordinate trees, no cycles, server authority. Higher titles, obligations, independence methods, disconnect, and join-in-progress remain unspecified. No gameplay implemented.

## 2026-08-23 — Maps, titles, economy & performance checkpoint

Documented interactive multi-map geography vs realms, dynamic map-based title qualification, manual establishment with Prestige (not spent) and server revalidation, persistent titles below creation thresholds, Gold/Prestige/Influence vs Crowns/Lifetime Support, non-pay-to-win Crowns, and calculate-on-change performance philosophy. Numerical formulas, map assets, and products remain unresolved. No gameplay implemented.

## 2026-08-23 — Phase 1 closed (audit PASS WITH MINOR CLEANUP)

Corrected stale GitHub publication tracking, architecture-bootstrap tracking, Cursor rule wording for the active design bible, and `_Placeholder.luau` folder documentation. Formally closed Phase 1 — Foundation & Architecture. Political Hierarchy V0.1 remains specified, not implemented. No gameplay implemented.
