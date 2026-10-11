# Architecture

This project is a GUI-first Roblox game. Source-controlled Luau lives on disk and syncs into Studio. Live DataModel objects (especially GUI instances) are managed in Studio, not as files.

## Top-level source-controlled directories

| Path | Purpose |
| --- | --- |
| `ServerScriptService/` | Authoritative server scripts. Contains the server entry point and server-only systems. |
| `ServerScriptService/Services/` | Authoritative server-side systems. Currently `PoliticalHierarchyService.luau`, `TerritoryMapService.luau`, `TitleProgressionService.luau`, `DiplomacyService.luau`, `WarfareService.luau`, `EconomyService.luau`, `MilitaryService.luau`, `CommunicationsPolicy.luau`, `CommunicationsService.luau`, `NeutralDefenseService.luau`, `MatchState.luau`, `VictoryService.luau`, plus `GameSettingsService.luau` and Admin Bridge (`AdminConfig`, `AdminBridge`, `AdminService`, `AdminKohlAddon`). |
| `ReplicatedStorage/Shared/` | Modules that are safe and appropriate for both client and server. |
| `ReplicatedStorage/Shared/Config/` | Centralized configuration data. Currently `PoliticalHierarchyConfig.luau`, `MapCatalog.luau`, `ValePrototypeMap.luau`, `RealmColors.luau`, `DiplomacyConfig.luau`, `WarfareConfig.luau`, `EconomyConfig.luau`, `MilitaryConfig.luau`, `CommunicationsConfig.luau`, `NeutralDefenseConfig.luau`, `PresentationBindings.luau`, `GameSettingsConfig.luau`. |
| `ReplicatedStorage/Shared/Types/` | Reusable Luau type definitions. Currently `PoliticalTypes.luau`, `TerritoryTypes.luau`, `TitleTypes.luau`, `DiplomacyTypes.luau`, `WarfareTypes.luau`, and `EconomyTypes.luau`. |
| `ReplicatedStorage/Shared/Util/` | Genuinely reusable utilities. Currently `PoliticalRankRules.luau` (`NextRank` / `Name`), `TitleRequirements.luau`, `MapAdjacency.luau`, `MapGeometry.luau`, `MapTriangles.luau`, `PrototypeGuiTheme.luau`, `KohlPrototypeTheme.luau`, `WarfareAdjacency.luau`, `PlayerRelevantView.luau`, `EconomyPayout.luau`, `MilitaryCombat.luau`, `RealmGraph.luau`, `RealmOverviewView.luau`, `Domination.luau`, `GuiSounds.luau`. |
| `ReplicatedStorage/Remotes/` | RemoteEvents/RemoteFunctions created in Studio. Hierarchy: `HierarchyClientEvent`, `HierarchyServerEvent`. Territory: `TerritoryClientEvent`, `TerritoryServerEvent`. Title: `TitleClientEvent`, `TitleServerEvent`. Diplomacy: `DiplomacyClientEvent`, `DiplomacyServerEvent`. Warfare: `WarfareClientEvent`, `WarfareServerEvent`. Economy: `EconomyClientEvent`, `EconomyServerEvent`. Military: `MilitaryClientEvent`, `MilitaryServerEvent`. Communications: `CommunicationsClientEvent`, `CommunicationsServerEvent` (state/control/identity metadata only; native TextChannel transports player messages). Victory: `VictoryClientEvent`, `VictoryServerEvent`. Presentation: `GameSettingsRequestEvent`, `GameSettingsStateEvent` (created by GameSettingsService). Disk `_Placeholder.luau` remains so Script Sync keeps this folder (remotes are not Luau files). |
| `StarterPlayerScripts/` | Client scripts that run for each player. On disk this is a root folder; in Studio it maps to `StarterPlayer.StarterPlayerScripts`. Contains the client entry point and controllers. |
| `StarterPlayerScripts/Controllers/` | Client-side behavior and GUI control. Currently `PoliticalHierarchyController.luau`, `TerritoryMapController.luau`, `TitleProgressionController.luau`, `DiplomacyController.luau`, `WarfareController.luau`, `EconomyController.luau`, `MilitaryController.luau`, `CommunicationsController.luau`, `AdminFeedbackController.luau`, `StrategyPresentationController.luau`, `RealmOverviewController.luau`, `VictoryController.luau`, `GameSettingsController.luau`. |
| `docs/` | Project documentation, including this architecture note. |
| `AI/` | Agent tracker: progress, decisions, and changelog. |

GUI instances are **not** stored in this filesystem. They are created and edited in Roblox Studio.

Reserved Script Sync folders that still have no Luau modules keep `_Placeholder.luau` so Studio materializes the folder. Delete or replace the placeholder when real modules occupy that folder. `ReplicatedStorage/Remotes/_Placeholder.luau` is kept because remotes are Studio instances, not synced Luau.

Prototype GUI: `StarterGui.HierarchyPrototypeGui` (Studio-managed, not a filesystem source file). Historical V0.1 layout (superseded by the authorized map-first presentation below): central `MapStage` (`{1,-404},{1,-184}`), right `Main` hierarchy panel, right `DiplomacyPanel` above a bottom-right `TitlePanel`, bottom `TerritoryInfo` (`{1,-404},{0,160}` including Declare War + war status), compact `EconomyPanel` above TerritoryInfo in the map column, `MilitaryPanel` above Economy in the map column, top-left `ResultToast`. Incoming vassalage is `VassalageOfferOverlay`; incoming diplomacy is `DiplomacyOfferOverlay` (offset so both can coexist). `MapStage.BattleBanner` is the primary ~5s participant “battle in progress” presentation (not a third-party banner). Dual-lock does **not** also toast “Battle in progress”; `ResultToast` still shows final `BattleResult` and other generic notices. Participant `MilitaryPanel` shows a ~20s Last Battle summary **per selected territory** after combat (not a history log; not shown to third parties).

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

## UI shell direction (implemented in the authorized GUI sprint below; Settings/remapping remain future)

Long-term GUI architecture. **Do not implement from this section.** The current prototype layout remains in use (right-side hierarchy + title, map-centered vassalage overlay, result toast). Do not assign keyboard keys yet.

- The interactive political map is the persistent primary workspace and should eventually occupy essentially the full usable main game canvas.
- Major systems (hierarchy, titles, diplomacy, economy, religion, and later equivalents) must **not** accumulate as permanently visible stacked panels. They open as contextual panels/overlays over the map.
- Major panels should be opened by explicit activation: on-screen navigation controls and/or keyboard keybinds. **No keybinds are assigned.** Future work must **centralize** UI navigation/bindings; controllers must not each invent a private key.
- **Configurable remapping (future public product, not current work).** Player actions should eventually be **logical actions** mapped to player-selected inputs (Physical Input → configurable action → controller/UI). Example names such as `OpenMilitary` / `OpenDiplomacy` / `OpenRealm` / `OpenEconomy` / `OpenSettings` are illustrative, not a locked catalog. A future Settings / Controls UI would display gameplay and GUI binds and allow rebinding. Do **not** implement Settings/Controls, remapping, persistence, or new keybinds from this section. The **first published playtest** may use temporary/default binds; configurable controls are **not** automatically a first-playtest requirement. Do not over-engineer the current prototype; avoid new hardcoded physical-key GUI contracts where a logical action would remain easy later.
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

**Implemented (map input):** `TerritoryMapController` ignores pan/select/zoom when `PlayerGui:GetGuiObjectsAtPosition` finds `VassalageOfferOverlay`, `DiplomacyOfferOverlay`, `TitlePanel`, `Main`, `TerritoryInfo`, `DiplomacyPanel`, `AdminInspectPanel`, `EconomyPanel`, or `MilitaryPanel` at the pointer. Map press must start on the map itself. Result toasts are not blocking layers. Check runs only on pointer events, not per frame. Mouse wheel over the map still zooms when Roblox marks it `gameProcessed` because `MapStage` is an Active GUI surface; `gameProcessed` is not treated as higher-GUI blocking.

## Configuration and simulation

- **Map-driven political scaling.** Title-qualification thresholds come from the selected map’s configuration, not from hardcoded universal territory counts and not from human player count. Shared config belongs in `ReplicatedStorage/Shared/Config/` conceptually; the server still applies and validates it. Vale Title Progression V0.1 **test** numbers (Duke 2/100, King 5/250, Emperor 10/500) live on `ValePrototypeMap.titleRequirements` only; they must not become a universal engine constant.
- **Match vs account state.** Gold, Prestige, and Influence are match resources and reset between matches. Crowns and Lifetime Support are account-level and persist. Do not mix competitive match power into premium currency. **Economy / Resources V0.1** (**IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**) is the Gold foundation only.
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

- **Server:** `WarfareService` active wars keyed by warId (attacker root, original defender root, target). `WarfareClientEvent` accepts Ready / DeclareWar(territoryId) only. Server derives attacker, defender, adjacency, NAP. Greater-realm adjacency uses `Shared/Util/WarfareAdjacency` against MapConfiguration `adjacentIds` and territories owned by the attacking root plus descendants. **Military / Armies V0.1:** at most one active war per territory; 10s post-war cooldown on the target after resolve/cancel. Ordinary resolution is Military battle → `ApplyMilitaryOutcome`. Privileged `DebugResolveWar` / `WarfareDebug.Invoke('Resolve', warId, 'Attacker'|'Defender')` still exists: unwind Military if pre-mechanical; reject if mechanically final. Attacker victory calls `TerritoryMapService.SetOwner(target, attackingRoot)` after ending the resolving war; stale wars (admin ownership mutation) still skip transfer. Defender victory ends the war with no ownership change. Cancels on `RulerRemoving` and loss of independence (`StateChanged`) unless the battle is already mechanically final.
- **Client:** `WarfareController` drives `TerritoryInfo.DeclareWar` / `WarStatus`; selection via `SelectedTerritoryId` published by `TerritoryMapController`. Declare War is enabled only when the same greater-realm adjacency helper is true (plus independence / owner / NAP checks). If the selected territory is on post-war cooldown, a one-shot delay at replicated `endsAt` rerenders eligibility when that cooldown expires (no deselect/reselect). Button copy names the selected territory. Historical “additional war” copy for the **same** target is obsolete under Military / Armies V0.1 same-target supersession. Toasts for notices. **Player-facing war lists** use `PlayerRelevantView` (local greater-realm / root only). The replicated snapshot stays global; admin `;inspectwars` is unfiltered.
- **Must not:** claims, peace, map recolor for war, title/Prestige grants, client victory authority. Armies/battles belong to **Military / Armies V0.1** (`MilitaryService`), not this module.
- **Acceptance:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 only; not a complete military game). Director-verified PASS includes adjacent/non-adjacent/duplicate declaration, attacker and defender victory, **historical** competing same-target wars and stale competing-war cleanup (later **superseded** by Military / Armies V0.1), loss of independence without liege inheritance, attacker-root and defender-root disconnect without conquest or leftover stale wars, player-relevant ordinary GUI, global admin InspectWars, and AdminBridge ResolveWar → `WarfareService.DebugResolveWar`. Hierarchy, map, title, diplomacy V0.1, and prototype GUI maintenance stay accepted.

## Military / Armies (V0.1 — IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED)

- **Server:** `MilitaryService` personal Troop pools (start 1000). Invariant Total = Available + reserved across wars. `RulerCreated` / `RulerRemoving`. Recruit via `EconomyService.TrySpend` (1 Gold = 3 Troops). Commitments only for the two war roots. Timers 40s decision window / 55s hard timeout (interacted auto-lock at 40s; nonresponsive attacker cancel / defender 0 at 55s). Battle math in `MilitaryCombat` (hidden). Casualties reduce Total; survivors return when the war concludes. Does not `SetOwner` or declare wars. After both lock: calculate immediately, ~5s presentation, then `WarfareService.ApplyMilitaryOutcome`.
- **Client:** `MilitaryController` + `MilitaryPanel` (own Total/Available/Committed, recruit, compact **M** max-recruit, auto-submit commit field, Ready/Lock). Displayed commitment/Ready bind to the war whose `targetTerritoryId` matches `TerritoryInfo.SelectedTerritoryId` (same selection as the map). Unrelated selection does not show another war as that land’s commitment and does not mutate server Military state. Empty selection with exactly one live war still shows that war. Primary 5s presentation is `MapStage.BattleBanner` for the **displayed** war only (`phase == "present"`). Dual-lock does not send a “Battle in progress” `Notice`. `MilitaryClientEvent` Ready/Recruit/RecruitMax/SetCommit/LockCommit. `MilitaryServerEvent` per-player State / Notice (errors, lock, recruit; attacker lock-0 cancel: `Attack cancelled: you committed 0 Troops.`) / participant BattleResult (own committed/casualties/survivors, enemy fielded committed, won, territory; no rolls). After conclusion, participant panel shows ~20s Last Battle **for the selected territory** (independent per-territory cache; active war on that land overrides; unrelated land does not show another fight). ResultToast still shows the brief BattleResult. No “Set Forces” button; the amount field sends SetCommit when the parsed integer changes (debounced). Ready is disabled until a server-accepted intent exists. When the local player has no active `commit`/`present` session, the commitment TextBox is cleared (placeholder `Troops to commit`).
- **Must not:** Client-authoritative Troops, Gold spend, or battle; ordinary UI showing other rulers’ pools or hidden rolls; `SetOwner` from Military; same-territory second war; sieges, movement, levies, Alliance pooling, client-visible Effective Strength.
- **Admin:** `;inspecttroops` `;settroops` `;addtroops` `;inspectmilitary` `;inspectcontest`. `MilitaryDebug.Invoke` (Inspect, InspectWar, Recruit, RecruitMax, SetCommit, LockCommit, Advance, SetSeed, SelfTest, …).
- **Warfare integration:** contest + cooldown in `WarfareService`. Snapshot includes `cooldowns`.
- **Bootstrap:** Hierarchy → Territory → Title → Diplomacy → Warfare → Economy → **Military** → Admin.
- **Status:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope only). Eighteen Director PASSes in `AI/PROGRESS.md`. Eight MIL-MP overlay/race cases remain **DEFERRED ≠ PASS** in `AI/PLAYTEST_BACKLOG.md` (not a V0.x progress blocker). If later deferred testing shows Troop duplication, dropped outcomes, double resolution, stuck CONTESTED, or equivalent authoritative corruption, that is a real defect.

## Economy / Resources (V0.1 — IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED)

- **Server:** `EconomyService` Gold by rulerId (start 150). Reads `TerritoryMapService` ownership and map `baseGoldIncome` (Gold/min). One global 6s payout via `EconomyPayout.GoldPerTick`. Unclaimed pays nobody. Direct owner only. `TrySpend` / `AddGold` / `DebugSetGold` / `GetBalance` / `GetIncomeGoldPerMinute` / `GetInspect`. `RulerCreated` inits Gold without resetting existing; `RulerRemoving` deletes Gold with no transfer. `EconomyClientEvent` Ready only; `EconomyServerEvent` pushes **that player’s** State JSON (`gold`, `incomeGoldPerMinute`, `nextPayoutAt`). Map config that is not a whole tick errors at Start.
- **Client:** `EconomyController` + `EconomyPanel` (Gold / Gold/min / global countdown). No mutation intents.
- **Admin:** `;inspectgold` `;setgold` `;addgold` `;spendgold` → AdminBridge → EconomyService. `EconomyDebug.Invoke`.
- **Must not:** Prestige/Influence economies, Crowns, buildings, development, tax, trade, debt, loot, client mutate remotes.
- **Bootstrap:** Hierarchy → Territory → Title → Diplomacy → Warfare → Economy → Military → Admin.
- **Acceptance:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 Gold only). Director Local Server **PASS** (2026-08-24): multiplayer 150 + shared 6s clock; 1/2/3-territory income; conquest/admin transfer future-income without treasury steal; subject Gold/land income with no liege share; unclaimed pays nobody; spend/overspend (209→reject 500, spend 100→109); disconnect Gold wipe with no transfer; Kohl raw-target autocomplete. Landless-liege hierarchy is not an Economy defect and is not accepted by this stamp. Client Gold mutation is Ready-only by architecture.

## Communications (V0.x — IMPLEMENTED — PARTIAL AGENT VERIFICATION)

- **Status:** Director authorized recommendation B replacement on 2026-10-09; partial agent verification, NOT Director-accepted. Direct personal-territory adjacency clarified by Director on 2026-10-09.
- **Modules:** CommunicationsService owns native contexts and membership; CommunicationsPolicy derives current eligibility/identity from existing authorities; RealmGraph is stateless. CommunicationsController joins native Success receipts to metadata-only identity envelopes and owns local history/help/observer mute. No player text in Communications remotes. Diplomacy owns distinct Alliance instance IDs and StateChanged; current-state validation runs at native delivery time, independently of deferred source sync.
- **Studio assets:** CommunicationsPanel uses bounded scrolling transcript/selector/contact controls. Two existing Communications remotes retained for Ready/OpenDirect intents and state/identity labels. TextChatService default channels/commands disabled in edit configuration; other untagged rooms deny delivery. Live inspectcomms routes through existing AdminBridge authorization. Recovered sources preserved inactive in ServerStorage.CommunicationsRecoveryArchive. See AI/COMMUNICATIONS_IMPLEMENTATION.md for evidence and limitations.
- **Ordinary paths (frozen):** Diplomatic (realm-graph distance ≤ 2 from sender; not global; asymmetric delivery desired); Council (ruler + direct subjects; no geo limit); Allies (per Alliance; no NAP; no subject inherit; no geo limit); Direct (1:1; current personal-territory adjacency; send cut immediately if border lost; match-scoped).
- **Admin/Observer:** separate; context metadata + mute of the observer view; announcements unmistakably ADMIN/SYSTEM when later designed. Exact observer/announcement UI not frozen.
- **Identity / filtering:** live Title; Diplomatic/Direct one viewer-relative tag (Liege/Subject then Ally then none); Council/Allies Title only. Roblox TextChatService + platform filtering. No voluntary-speech censorship. Military hidden state remains system-protected.
- **Future (not this milestone):** long-distance/espionage communication; Tab-toggles-Hierarchy / Diplomacy-to-map-column layout idea.
- Canonical freeze: `AI/GAME_DESIGN.md` Player communications.

## Delegated greater-realm authority (future — not implemented)

Specified in `AI/GAME_DESIGN.md` / `AI/DECISIONS.md`. Rank defaults + individual overrides. Do not retrofit into accepted V0.1 systems. Permission catalog unresolved.

## Admin / testing (V0.1 — Kohl live for current bridge ops)

- **Kohl's Admin** (official @Scripth, Creator Store `172732271`, folder `ServerScriptService.Kohl's Admin`) provides command UI/auth and the isolated creator presentation surface; game state remains project-owned. Custom commands belong in `Config.Addons` (CollectionService tag on the Addons folder). Auto-update loads MainModule asset `1868400649`; local Config/Addons still apply.
- **AdminBridge** is the only game-state testing façade. Live: Kohl `;adminhelp` / `;inspectwars` / `;inspectterritory` / `;inspectruler` / `;setowner` / `;setprestige` / `;inspectgold` / `;setgold` / `;addgold` / `;spendgold` / `;inspecttroops` / `;settroops` / `;addtroops` / `;inspectmilitary` / `;inspectcontest` / `;resolvewar` → addon → `AdminBridge.Execute(UserId, …)` with the central `AdminConfig.IsGameTester` gate: authorized UserId OR trusted server Kohl effective rank >= configured `Data.roles.superadmin._rank`. Kohl owner/ruler argument types (`adminOwnerToken` / `adminRulerToken`) parse raw strings and only suggest player names (`unclaimed` on SetOwner); AdminBridge remains the resolver. **Director-verified PASS (2026-08-24):** Local Server `setowner` suggestions showed Player1, Player2, Player3, and `unclaimed`; `setowner` and `setgold` worked. In Studio only, synthetic Local Server UserIds (`< 0`) also pass that check; published servers do not. Studio: `ServerScriptService.AdminDebug.Invoke(operation, …)` (no UserId). The scoped GameTester addon adapts Kohl `Auth.hasCommand` only for its own 21 command definitions; other commands delegate unchanged. AdminService replicates `_GameTesterAuthorized` for client UI admission and refreshes it on player arrival / Kohl role changes. Server command admission and AdminBridge execution always recheck AdminConfig; client attributes are never server authority. No new admin mutation remote. The existing Communications GameTester observer check inherits this same authorization rule. See `AI/ADMIN_PERMISSIONS.md`.
- **Presentation (not authority):** `AdminFeedbackEvent` is server-to-client display only. Gameplay admin mutations still cannot be invoked through a new client mutation remote; the separately authorized presentation request path below is creator-validated. `AdminFeedbackController` uses ResultToast + `AdminInspectPanel`. `AdminKohlThemeClient` restyles Kohl command chrome from `KohlPrototypeTheme` / `PrototypeGuiTheme` after load (survives MainModule auto-update). Do not fork Kohl MainModule for look. In-game copy/reuse of reusable admin IDs is a **pre-playtest admin UX requirement**, not implemented now.
- No project Admin remotes that invoke AdminBridge. Per-system `*Debug` folders remain (mock rulers, WarfareDebug Declare/Resolve, etc.).
- Future gameplay services should expose testing through this bridge, not by scattering Kohl requires.

## Authorized GUI presentation layer — 2026-10-09

`StrategyPresentationController` owns responsive geometry, centralized Map/system navigation and major drawer visibility. VictoryController starts afterward, followed by GameSettingsController for live theme/audio application. Existing gameplay controllers continue to own content/actions and incoming request visibility. Priority overlays remain independent above the open drawer; toasts remain transient. Background ScreenGui is noninteractive and covers the viewport including its inset. Province labels follow the existing map camera without changing territory hit geometry or ownership. Main, TerritoryInfo, DiplomacyPanel, MilitaryPanel and CommunicationsPanel are scrolling roots. Admin inspection uses measured text height/canvas; InspectComms shares existing AdminBridge feedback routing. This explicitly authorized sprint supersedes older prototype fixed-region and future-only shell notes above for these implemented controls. Configurable keybinds/remapping remain future work. See `AI/GUI_UX_SPRINT.md`.

## Realm Overview presentation — 2026-10-10

The existing eight navigation buttons now have a ninth Players entry. RealmOverviewController starts through the presentation controller, owns PlayerList-only supported CoreGui disable and keyed rows, and consumes existing State/Ready contracts from Hierarchy, Territory, Diplomacy, Warfare and Communications. RealmOverviewView allowlists public fields and local-root relationship pairs; it excludes private resources, requests and admin metadata. Direct availability comes from current server contacts. No gameplay authority or new remote. Central PresentationBindings supplies explicitly authorized hold-Tab input; Settings/remapping remain future work. Fullscreen Studio overlay and map/navigation guards block underlying input; character respawn and focus loss close it. See AI/REALM_OVERVIEW.md for assets, data boundaries, sorting and verification.

## Unclaimed conquest and Domination — authorized 2026-10-10

NeutralDefenseService owns lightweight militia keyed by territory and ownership revision, configured by province/map/default. It never creates a ruler or Military Troop pool. Territory snapshots expose current/maximum defense for Unclaimed provinces. Warfare snapshots distinguish Player/Unclaimed targets; Military locks the militia immediately and uses existing combat arithmetic, attacker reservations, casualties and presentation. Surviving militia are applied only to the original Unclaimed lifecycle. Warfare revalidates that lifecycle and root authority before ordinary SetOwner transfer.

VictoryService and pure Shared.Util.Domination count all conquerable map definitions against greater-realm ownership. Map victory config supplies type/percentage; validation rejects invalid thresholds. Hierarchy and Territory events update progress, with synchronous Evaluate calls at authoritative mutation boundaries to avoid queued near-threshold transfers. Server-only MatchState retains the first final result, root identity, realm members and totals. VictoryService freezes Military/Warfare synchronously. Services guard competitive APIs; Economy stops payouts. Post-end ruler-removal/starting-land logic preserves final political/ownership inspection. Bootstrap starts Victory after Communications and before Admin.

VictoryClientEvent accepts Ready only; VictoryServerEvent sends public State JSON. VictoryController consumes that state, disables competitive controls, presents root Victory / subject Realm Victory / other Defeat, and reopens the result from StrategyNavigation.MatchResult. VictoryOverlay is a Studio asset with active modal input blocking; map drag cancels when it opens. Map, Players and Communications remain available after dismissal. AdminBridge adds InspectVictory, CheckVictory, InspectNeutral and SetNeutralDefense with existing GameTester authorization; CheckVictory evaluates normal rules and does not force a winner. See AI/CONQUEST_VICTORY.md for verification and limits.

## Creator game presentation / audio

GameSettingsConfig declares presentation-only defaults, allowed fonts and safe ranges. GameSettingsService validates creator-authorized Set/Reset requests, throttles per Player and replicates cloned sanitized snapshots/revisions through GameSettingsRequestEvent/StateEvent. AdminConfig.CanConfigureGame is independent of IsGameTester: explicit project owner/actual creator edits, testers view only. No rank or client attribute grants global configuration authority. Runtime state resets to source defaults on a new server; persistence is intentionally future work.

GameSettingsController starts after existing GUI controllers, coalesces slider requests, orders reset requests and applies PrototypeGuiTheme tokens to current/dynamic game descendants while retaining authored templates/base metrics. Existing controllers keep geometry and content authority. UI density changes safe navigation/drawer/row sizes; Communications/admin measured canvases reflow when font/size changes. GuiSounds owns a separate SoundGroup, copied inspected Kohl asset IDs, semantic playback, volumes/toggles and short debounce.

GamePresentationKohlClient uses existing AdminService addon delivery and native Kohl UI constructors. Its guarded Settings scroller/search handles are the only version-sensitive integration; dashboard-instance admission prevents duplicate mounting. No vendor Source changes, personal Kohl theme writes or Kohl savedSettings storage are used. Unsupported addon handles leave game defaults active. See AI/GAME_PRESENTATION_SETTINGS.md for controls, source inventory and verification.
