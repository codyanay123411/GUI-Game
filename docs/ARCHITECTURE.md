# Architecture

This project is a GUI-first Roblox game. Source-controlled Luau lives on disk and syncs into Studio. Live DataModel objects (especially GUI instances) are managed in Studio, not as files.

## Top-level source-controlled directories

| Path | Purpose |
| --- | --- |
| `ServerScriptService/` | Authoritative server scripts. Contains the server entry point and server-only systems. |
| `ServerScriptService/Services/` | Authoritative server-side systems. Currently `PoliticalHierarchyService.luau`, `TerritoryMapService.luau`, `TitleProgressionService.luau`, `DiplomacyService.luau`, `WarfareService.luau`, plus Admin Bridge (`AdminConfig`, `AdminBridge`, `AdminService`, `AdminKohlAddon`). |
| `ReplicatedStorage/Shared/` | Modules that are safe and appropriate for both client and server. |
| `ReplicatedStorage/Shared/Config/` | Centralized configuration data. Currently `PoliticalHierarchyConfig.luau`, `MapCatalog.luau`, `ValePrototypeMap.luau`, `RealmColors.luau`, `DiplomacyConfig.luau`, `WarfareConfig.luau`. |
| `ReplicatedStorage/Shared/Types/` | Reusable Luau type definitions. Currently `PoliticalTypes.luau`, `TerritoryTypes.luau`, `TitleTypes.luau`, `DiplomacyTypes.luau`, and `WarfareTypes.luau`. |
| `ReplicatedStorage/Shared/Util/` | Genuinely reusable utilities. Currently `PoliticalRankRules.luau` (`NextRank` / `Name`), `TitleRequirements.luau`, `MapAdjacency.luau`, `MapGeometry.luau`, `MapTriangles.luau`, `PrototypeGuiTheme.luau`, `KohlPrototypeTheme.luau`, `WarfareAdjacency.luau`, `PlayerRelevantView.luau`. |
| `ReplicatedStorage/Remotes/` | RemoteEvents/RemoteFunctions created in Studio. Hierarchy: `HierarchyClientEvent`, `HierarchyServerEvent`. Territory: `TerritoryClientEvent`, `TerritoryServerEvent`. Title: `TitleClientEvent`, `TitleServerEvent`. Diplomacy: `DiplomacyClientEvent`, `DiplomacyServerEvent`. Warfare: `WarfareClientEvent`, `WarfareServerEvent`. Disk `_Placeholder.luau` remains so Script Sync keeps this folder (remotes are not Luau files). |
| `StarterPlayerScripts/` | Client scripts that run for each player. On disk this is a root folder; in Studio it maps to `StarterPlayer.StarterPlayerScripts`. Contains the client entry point and controllers. |
| `StarterPlayerScripts/Controllers/` | Client-side behavior and GUI control. Currently `PoliticalHierarchyController.luau`, `TerritoryMapController.luau`, `TitleProgressionController.luau`, `DiplomacyController.luau`, and `WarfareController.luau`. |
| `docs/` | Project documentation, including this architecture note. |
| `AI/` | Agent tracker: progress, decisions, and changelog. |

GUI instances are **not** stored in this filesystem. They are created and edited in Roblox Studio.

Reserved Script Sync folders that still have no Luau modules keep `_Placeholder.luau` so Studio materializes the folder. Delete or replace the placeholder when real modules occupy that folder. `ReplicatedStorage/Remotes/_Placeholder.luau` is kept because remotes are Studio instances, not synced Luau.

Prototype GUI: `StarterGui.HierarchyPrototypeGui` (Studio-managed, not a filesystem source file). V0.1 layout: central `MapStage` (`{1,-404},{1,-184}`), right `Main` hierarchy panel, right `DiplomacyPanel` above a bottom-right `TitlePanel`, bottom `TerritoryInfo` (`{1,-404},{0,160}` including Declare War + war status), top-left `ResultToast`. Incoming vassalage is `VassalageOfferOverlay`; incoming diplomacy is `DiplomacyOfferOverlay` (offset so both can coexist).

## Server / client / shared separation

- **Server** (`ServerScriptService`) owns authoritative game state, validation, and any decision that must not be forged by a client.
- **Client** (`StarterPlayerScripts/` on disk → `StarterPlayer.StarterPlayerScripts` in Studio) owns local presentation: GUI control, input handling, and visual feedback.
- **Shared** (`ReplicatedStorage/Shared`) owns types, config, and utilities that both sides may use without giving the client authority.

`Bootstrap.server.luau` and `Bootstrap.local.luau` are thin entry points. They orchestrate modules; they do not become monolithic game scripts. Do not introduce frameworks or external dependencies unless a later decision records that change. Script Sync maps `Bootstrap.local.luau` to a **LocalScript** in `StarterPlayerScripts`. Do not use `Bootstrap.client.luau` there: a Script with RunContext=Client under `StarterPlayerScripts` runs twice.

## Tooling roles

- **Roblox Studio MCP** handles live DataModel manipulation, GUI instances, inspection, and Studio Play / Local Server **development verification**. Those sessions are not the project’s first real playtest (published server; see `AI/GAME_DESIGN.md`).
- **Script Sync** handles source-controlled Luau files and folders between disk and Studio.
- **Git / GitHub** provides version history and rollback for the files in this repository.

## GUI and authority

GUI behavior is driven by client **Controllers**. Authoritative game state and validation remain **server-side** in **Services**.

The client must never be trusted for authoritative game decisions. Treat client requests as untrusted input: the server validates, the client reflects the result.

That includes **title establishment**: the client may show eligibility and request a title; only the server may grant Duke, King, or Emperor after revalidation. Title Progression V0.1 is **accepted / complete**.

### Player-relevant information (standing)

Player-facing UI must use player/realm-relevant views of authoritative server state. Global server state is not automatically player-visible. Admin/debug inspection is exempt. Systems that intentionally expose global/public information must explicitly define that visibility.

When implementing a system, decide explicitly:

- **A.** Globally public by design
- **B.** Relevant only to the local player / ruler / greater realm (subjects inherit the root’s view)
- **C.** Admin/debug-only

Do not default to rendering the full server snapshot in ordinary GUI. Territory selection may show public province facts (name, owner, rank) while private/active state (wars, pending requests, internal resources) is shown only when the local realm is involved, unless a future system defines public knowledge.

**Warfare V0.1:** ordinary `TerritoryInfo` / `WarfareController` lists wars where `attackerRootId` or `defenderRootId` is the local greater-realm root. `;inspectwars` and WarfareDebug remain global.

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

### Prototype panel geometry (standing)

Current prototype screen regions are **deterministic**. Gameplay-state changes update **content and visual state** inside those regions (text, button enablement, tree/player rows). They must not arbitrarily reflow primary panel Size/Position.

Dynamic lists (hierarchy tree, other players) **scroll inside** their assigned regions. They do not grow the parent `Main` or `TitlePanel`.

`Main` (hierarchy) and `TitlePanel` form one right-side column with a small fixed gap: hierarchy fills remaining height above a **fixed-height** title footer. The Establish control keeps a reserved slot (enable/disable/label; “No further title” when there is no next rank) so hiding a next title does not shrink the panel.

Explicit future player actions (open/collapse/keybind panels) may change geometry on purpose. That is not this V0.1 prototype.

### Prototype visual theme (standing)

Current prototype surfaces share one dark grand-strategy **theme system** (`PrototypeGuiTheme`): panel tone, stroke, corners, type hierarchy, and button states. Gameplay-state updates still change content and enablement, not primary geometry. The Vassalage overlay keeps stronger gold emphasis as a priority action. Result toasts stay related but visually distinct as transient feedback. Token values are prototype styling, not permanent art direction.

## Future UI shell (specified, not implemented)

Long-term GUI architecture. **Do not implement from this section.** The current prototype layout remains in use (right-side hierarchy + title, map-centered vassalage overlay, result toast). Do not assign keyboard keys yet.

- The interactive political map is the persistent primary workspace and should eventually occupy essentially the full usable main game canvas.
- Major systems (hierarchy, titles, diplomacy, economy, religion, and later equivalents) must **not** accumulate as permanently visible stacked panels. They open as contextual panels/overlays over the map.
- Major panels should be opened by explicit activation: on-screen navigation controls and/or keyboard keybinds. **No keybinds are assigned.** Future work must **centralize** UI navigation/bindings; controllers must not each invent a private key.
- Opening a major panel uses a coherent UI state model: close or replace another major panel where appropriate; coexist only when useful; avoid permanent clutter.
- **Player/map orientation** (restrained own-land identification, center-on / show-my-realm or equivalent) is **required before the first published playtest**. Exact keybind/art not locked. Do not implement from this section unless the Director authorizes pre-playtest usability work.
- **Priority overlays** (incoming Vassalage Accept/Decline and similar must-act requests) stay visible and actionable no matter which major panel is open. They are not major panels.
- **Result toasts** stay transient, non-interactive feedback. Do not merge them with major panels or action overlays.
- Functional clarity first; visual polish later. Not a license to redesign the current accepted/prototype GUI now.

### Input layering / click-through (standing)

Current and future GUI must prevent click-through between overlapping interactive layers.

When a pointer/input event is handled by a visible higher-priority GUI element, lower layers must not react to the same input. The interactive map is the lowest primary gameplay input layer. Admin inspect overlay and visible Kohl command-bar/dashboard chrome are higher layers while shown.

Examples: Accept/Decline on a Vassalage overlay must not also select a territory underneath; clicking or dragging inside a major panel must not pan/select the map beneath it; scrolling inside a panel must not zoom the map underneath it; clicking non-transparent modal/card space should block map interaction where that UI occupies the screen.

Use Roblox GUI/input mechanisms that **consume/block** input for the visible/interactable bounds of the higher-priority GUI. Do not rely on ZIndex alone. Do not make the entire screen globally modal if that unnecessarily blocks unrelated map area.

**Implemented (map input):** `TerritoryMapController` ignores pan/select/zoom when `PlayerGui:GetGuiObjectsAtPosition` finds `VassalageOfferOverlay`, `DiplomacyOfferOverlay`, `TitlePanel`, `Main`, `TerritoryInfo`, or `DiplomacyPanel` at the pointer. Map press must start on the map itself. Result toasts are not blocking layers. Check runs only on pointer events, not per frame. Mouse wheel over the map still zooms when Roblox marks it `gameProcessed` because `MapStage` is an Active GUI surface; `gameProcessed` is not treated as higher-GUI blocking.

## Configuration and simulation

- **Map-driven political scaling.** Title-qualification thresholds come from the selected map’s configuration, not from hardcoded universal territory counts and not from human player count. Shared config belongs in `ReplicatedStorage/Shared/Config/` conceptually; the server still applies and validates it. Vale Title Progression V0.1 **test** numbers (Duke 2/100, King 5/250, Emperor 10/500) live on `ValePrototypeMap.titleRequirements` only; they must not become a universal engine constant.
- **Match vs account state.** Gold, Prestige, and Influence are match resources and reset between matches. Crowns and Lifetime Support are account-level and persist. Do not mix competitive match power into premium currency.
- **Performance.** Prefer storing authoritative state and recalculating on meaningful changes. Avoid continuous polling and per-frame re-evaluation of unchanged political information or of every NPC action. This is a constraint on future systems, not a mandate to optimize empty modules.

## Territory / map foundation (V0.1 — accepted / complete)

- **Map definition / `MapConfiguration` (static per preset):** territory IDs, display names, polygon geometry, adjacency IDs. Hand-authored presets via `MapCatalog`. V0.1 default is `vale_prototype_16` (16 territories). Vale lattice adjacency is **8-neighbor** (edge or corner). The renderer uses the selected catalog map; 16 is not a universal constant.
- **Match map state (server-authoritative):** `TerritoryMapService` assigns one unique random territory to each human ruler, leaves the rest Unclaimed, and unclaims on hierarchy `RulerRemoving`. Snapshot JSON over `TerritoryServerEvent`; client `Ready` handshake. `SetOwner` / `DebugSetOwner` are server-only and are not client remotes. Query helpers: `GetOwnerRulerId`, `GetOwnedTerritoryIds`, `AreAdjacent`.
- **Client:** `TerritoryMapController` renders polygons in a ViewportFrame (WedgeParts), pan/zoom/select, info panel from replicated territory + hierarchy state. Greater-realm fill vs direct-holder rim; selection is a separate inward gold ring that does not replace those colors. Never treats clicks as granting ownership. `TerritoryClientEvent` accepts only `Ready`.

Political Hierarchy V0.1 remains the source of liege/vassal/root-ruler truth. Map coloring **reads** that state.

## Title progression (V0.1 — accepted / complete)

- **Config:** `TitleRequirements = f(MapConfiguration)` via `Shared/Util/TitleRequirements.luau` reading `mapDef.titleRequirements` (Vale test: Duke 2/100, King 5/250, Emperor 10/500). Sequential next rank only (`PoliticalRankRules.NextRank`).
- **Server:** `TitleProgressionService` revalidates ruler, current rank, next rank, greater-realm territory count (`CountOwnedByRulers` over ruler + `descendantIds`), and test Prestige (threshold, not spent), then `SetTitleRank`. Temporary server-side test Prestige only (default 0). `TitleClientEvent` accepts Ready / Establish only. Do not trust the client.
- **Client:** `TitleProgressionController` + `TitlePanel`: eligibility display and Establish request. Hierarchy/map show the new rank from hierarchy snapshots after grant.
- **Must not:** own or mutate territory; auto-promote; auto-demote; duplicate hierarchy authority; implement a real Prestige economy.
- **Dependencies:** Title → Hierarchy + Territory. Hierarchy and Territory do not require Title. Change events: `StateChanged`, `OwnershipChanged`.
- **Debug (prototype only):** `_G.__TitleProgressionV01.DebugSetPrestige(rulerId, n)` if the running server VM exposes `_G`; otherwise `ServerScriptService.TitleProgressionDebug:SetAttribute("SetPrestige", "rulerId=number")`. No client Prestige remote.
- **Accepted / complete** after director Local Server + 2 Players testing (see `AI/PROGRESS.md`). Does not authorize a real Prestige economy, title-loss, or other deferred systems.

## Diplomacy (V0.1 — accepted / complete)

- **Server:** `DiplomacyService` Alliance/NAP flags on unordered independent-root pairs; 30s pending requests; intents Ready / OfferAlliance / OfferNAP / Accept / Decline / BreakAlliance / BreakNAP. Consumes `PoliticalHierarchyService` for independence/root. Dissolves on `StateChanged` (loss of independence) and `RulerRemoving` (disconnect). Query `AreAllied` / `HasNonAggressionPact` (resolve via root ids). JSON snapshot on `DiplomacyServerEvent`.
- **Client:** `DiplomacyController` + `DiplomacyPanel` (fixed 380×148 above Title) and `DiplomacyOfferOverlay` (ZIndex 31). Subjects see the root realm’s relations read-only. Toasts for notices.
- **Must not:** implement wars as Diplomacy gameplay, map recolor, title/Prestige effects, vassal autonomy, opinion. **Warfare / Conquest V0.1** (implemented) **queries** this state: NAP blocks declaration; Alliance does not auto-join.
- **Accepted / complete** after director Local Server multiplayer verification (see `AI/PROGRESS.md`). Hierarchy, map, and title V0.1 stay accepted. Does not authorize deferred military systems, opinion, vassal diplomatic autonomy, or other deferred systems.

## Warfare / Conquest (V0.1 — IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED)

- **Server:** `WarfareService` active wars keyed by warId (attacker root, original defender root, target). `WarfareClientEvent` accepts Ready / DeclareWar(territoryId) only. Server derives attacker, defender, adjacency, NAP. Greater-realm adjacency uses `Shared/Util/WarfareAdjacency` against MapConfiguration `adjacentIds` and territories owned by the attacking root plus descendants. Resolution is **not** a client remote: `DebugResolveWar` / `WarfareDebug.Invoke('Resolve', warId, 'Attacker'|'Defender')`. Attacker victory calls `TerritoryMapService.SetOwner(target, attackingRoot)` after ending the resolving war; competing wars on that target go stale via `OwnershipChanged`. Defender victory ends the war with no ownership change. Cancels on `RulerRemoving` and loss of independence (`StateChanged`).
- **Client:** `WarfareController` drives `TerritoryInfo.DeclareWar` / `WarStatus`; selection via `SelectedTerritoryId` published by `TerritoryMapController`. Declare War is enabled only when the same greater-realm adjacency helper is true (plus independence / owner / NAP checks). Button copy names the selected territory and uses “additional war” when those two roots already have an active territory-specific war. Toasts for notices. **Player-facing war lists** use `PlayerRelevantView` (local greater-realm / root only). The replicated snapshot stays global; admin `;inspectwars` is unfiltered.
- **Must not:** armies, battles, claims, peace, map recolor for war, title/Prestige grants, client victory authority.
- **Acceptance:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 only; not a complete military game). Director-verified PASS includes adjacent/non-adjacent/duplicate declaration, attacker and defender victory, competing same-target wars, stale-war cleanup, loss of independence without liege inheritance, attacker-root and defender-root disconnect without conquest or leftover stale wars, player-relevant ordinary GUI, global admin InspectWars, and AdminBridge ResolveWar → `WarfareService.DebugResolveWar`. Hierarchy, map, title, diplomacy V0.1, and prototype GUI maintenance stay accepted. Future military systems must build on this authority.

## Admin / testing (V0.1 — Kohl live for current bridge ops)

- **Kohl's Admin** (official @Scripth, Creator Store `172732271`, folder `ServerScriptService.Kohl's Admin`) is command UI/auth only. Custom commands belong in `Config.Addons` (CollectionService tag on the Addons folder). Auto-update loads MainModule asset `1868400649`; local Config/Addons still apply.
- **AdminBridge** is the only game-state testing façade. Live: Kohl `;adminhelp` / `;inspectwars` / `;inspectterritory` / `;inspectruler` / `;setowner` / `;setprestige` / `;resolvewar` → addon → `AdminBridge.Execute(UserId, …)` with `AdminConfig` GameTester allowlist. In Studio only, synthetic Local Server UserIds (`< 0`) also pass that check; published servers do not. Studio: `ServerScriptService.AdminDebug.Invoke(operation, …)` (no UserId).
- **Presentation (not authority):** `AdminFeedbackEvent` is server-to-client display only. Mutations still cannot be invoked from the client. `AdminFeedbackController` uses ResultToast + `AdminInspectPanel`. `AdminKohlThemeClient` restyles Kohl command chrome from `KohlPrototypeTheme` / `PrototypeGuiTheme` after load (survives MainModule auto-update). Do not fork Kohl MainModule for look. In-game copy/reuse of reusable admin IDs is a **pre-playtest admin UX requirement**, not implemented now.
- No project Admin remotes that invoke AdminBridge. Per-system `*Debug` folders remain (mock rulers, WarfareDebug Declare/Resolve, etc.).
- Future gameplay services should expose testing through this bridge, not by scattering Kohl requires.
