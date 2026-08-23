# Architecture

This project is a GUI-first Roblox game. Source-controlled Luau lives on disk and syncs into Studio. Live DataModel objects (especially GUI instances) are managed in Studio, not as files.

## Top-level source-controlled directories

| Path | Purpose |
| --- | --- |
| `ServerScriptService/` | Authoritative server scripts. Contains the server entry point and server-only systems. |
| `ServerScriptService/Services/` | Authoritative server-side systems. Currently `PoliticalHierarchyService.luau` and `TerritoryMapService.luau`. |
| `ReplicatedStorage/Shared/` | Modules that are safe and appropriate for both client and server. |
| `ReplicatedStorage/Shared/Config/` | Centralized configuration data. Currently `PoliticalHierarchyConfig.luau`, `MapCatalog.luau`, `ValePrototypeMap.luau`, `RealmColors.luau`. |
| `ReplicatedStorage/Shared/Types/` | Reusable Luau type definitions. Currently `PoliticalTypes.luau` and `TerritoryTypes.luau`. |
| `ReplicatedStorage/Shared/Util/` | Genuinely reusable utilities. Currently `PoliticalRankRules.luau`, `MapAdjacency.luau`, `MapGeometry.luau`, `MapTriangles.luau`. |
| `ReplicatedStorage/Remotes/` | RemoteEvents/RemoteFunctions created in Studio. Hierarchy: `HierarchyClientEvent`, `HierarchyServerEvent`. Territory: `TerritoryClientEvent`, `TerritoryServerEvent`. Disk `_Placeholder.luau` remains so Script Sync keeps this folder (remotes are not Luau files). |
| `StarterPlayerScripts/` | Client scripts that run for each player. On disk this is a root folder; in Studio it maps to `StarterPlayer.StarterPlayerScripts`. Contains the client entry point and controllers. |
| `StarterPlayerScripts/Controllers/` | Client-side behavior and GUI control. Currently `PoliticalHierarchyController.luau` and `TerritoryMapController.luau`. |
| `docs/` | Project documentation, including this architecture note. |
| `AI/` | Agent tracker: progress, decisions, and changelog. |

GUI instances are **not** stored in this filesystem. They are created and edited in Roblox Studio.

Reserved Script Sync folders that still have no Luau modules keep `_Placeholder.luau` so Studio materializes the folder. Delete or replace the placeholder when real modules occupy that folder. `ReplicatedStorage/Remotes/_Placeholder.luau` is kept because remotes are Studio instances, not synced Luau.

Prototype GUI: `StarterGui.HierarchyPrototypeGui` (Studio-managed, not a filesystem source file). V0.1 layout: central `MapStage`, right `Main` hierarchy panel, bottom `TerritoryInfo`, top-left `ResultToast`.

## Server / client / shared separation

- **Server** (`ServerScriptService`) owns authoritative game state, validation, and any decision that must not be forged by a client.
- **Client** (`StarterPlayerScripts/` on disk → `StarterPlayer.StarterPlayerScripts` in Studio) owns local presentation: GUI control, input handling, and visual feedback.
- **Shared** (`ReplicatedStorage/Shared`) owns types, config, and utilities that both sides may use without giving the client authority.

`Bootstrap.server.luau` and `Bootstrap.local.luau` are thin entry points. They orchestrate modules; they do not become monolithic game scripts. Do not introduce frameworks or external dependencies unless a later decision records that change. Script Sync maps `Bootstrap.local.luau` to a **LocalScript** in `StarterPlayerScripts`. Do not use `Bootstrap.client.luau` there: a Script with RunContext=Client under `StarterPlayerScripts` runs twice.

## Tooling roles

- **Roblox Studio MCP** handles live DataModel manipulation, GUI instances, inspection, and playtesting.
- **Script Sync** handles source-controlled Luau files and folders between disk and Studio.
- **Git / GitHub** provides version history and rollback for the files in this repository.

## GUI and authority

GUI behavior is driven by client **Controllers**. Authoritative game state and validation remain **server-side** in **Services**.

The client must never be trusted for authoritative game decisions. Treat client requests as untrusted input: the server validates, the client reflects the result.

That includes **title establishment**: the client may show eligibility and request a title; only the server may grant Duke, King, or Emperor after revalidation.

## Coherent prototype UI

The game is GUI-first. Future GUI work must extend **one** evolving strategy-game interface, not a stack of isolated debug windows.

- Inspect live Studio GUI and screen usage before creating or substantially changing UI.
- Prototype quality is enough; readability, logical placement, and Play-mode testability are required. Edit-mode appearance alone is not verification.
- When the interactive map/world is implemented, it occupies **primary central** space. Supporting information and actions belong in side panels, overlays, or other placements that do not unnecessarily obstruct the map.
- Avoid Roblox CoreGui / topbar / chat overlap and unintentional overlap between project GUIs.
- Use proper layout and container behavior for dynamic content. Important actions, state changes, requests, and notifications must be obvious for manual testing.
- If a new system needs more screen space, reorganize the prototype coherently rather than stacking panels arbitrarily. Keep spacing, section hierarchy, button conventions, and prototype styling consistent where practical.
- Functional consistency takes priority over decorative polish. Do not copy another game’s copyrighted visual assets or exact UI.

This is a standing layout/integration principle, not a mandate to redesign existing GUI until a feature needs the space.

## Configuration and simulation

- **Map-driven political scaling.** Title-qualification thresholds come from the selected map’s configuration, not from hardcoded universal territory counts and not from human player count. Shared config belongs in `ReplicatedStorage/Shared/Config/` conceptually; the server still applies and validates it.
- **Match vs account state.** Gold, Prestige, and Influence are match resources and reset between matches. Crowns and Lifetime Support are account-level and persist. Do not mix competitive match power into premium currency.
- **Performance.** Prefer storing authoritative state and recalculating on meaningful changes. Avoid continuous polling and per-frame re-evaluation of unchanged political information or of every NPC action. This is a constraint on future systems, not a mandate to optimize empty modules.

## Territory / map foundation (V0.1 — accepted / complete)

- **Map definition / `MapConfiguration` (static per preset):** territory IDs, display names, polygon geometry, adjacency IDs. Hand-authored presets via `MapCatalog`. V0.1 default is `vale_prototype_16` (16 territories). The renderer uses the selected catalog map; 16 is not a universal constant.
- **Match map state (server-authoritative):** `TerritoryMapService` assigns one unique random territory to each human ruler, leaves the rest Unclaimed, and unclaims on hierarchy `RulerRemoving`. Snapshot JSON over `TerritoryServerEvent`; client `Ready` handshake. `DebugSetOwner` is server-only and is not a remote.
- **Client:** `TerritoryMapController` renders polygons in a ViewportFrame (WedgeParts), pan/zoom/select, info panel from replicated territory + hierarchy state. Greater-realm fill vs direct-holder rim; selection is a separate inward gold ring that does not replace those colors. Never treats clicks as granting ownership. `TerritoryClientEvent` accepts only `Ready`.

Political Hierarchy V0.1 remains the source of liege/vassal/root-ruler truth. Map coloring **reads** that state.
