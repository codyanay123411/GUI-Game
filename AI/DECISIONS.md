# Decisions

Substantial architectural decisions belong in this file. Do not silently reverse them later. If a decision changes, record the new decision and why the previous one was replaced.

## Development workflow

- **Cursor Local Agent on This PC.** Local agent work runs on this machine, not a remote cloud agent, unless a later decision says otherwise.
- **Roblox Studio MCP.** Use Studio MCP for direct Studio interaction and playtesting (hierarchy inspection, running Studio, checking output, and related agent-driven Studio work).
- **Script Sync.** Version-controlled Luau lives on disk and stays in sync with Studio through Script Sync. `.luau` files are the source of truth for scripts.
- **Empty Script Sync folders.** Script Sync does not create Studio folders that contain no `.luau` files. Reserved directories keep a `_Placeholder.luau` ModuleScript that returns `{}` solely so the folder appears in Studio. Delete that placeholder when the folder has real project files. Do not put gameplay in placeholders.
- **Git / GitHub.** Use Git for history and rollback. The project’s **private GitHub** repository (`origin`) is an active part of the development workflow.

## Product direction

- This project is a **GUI-first multiplayer feudal grand-strategy and political RPG** for Roblox. Play is interface-driven (2D political map), not a traditional explorable 3D world, unless directors later change that.
- **Match:** approximately **30 minutes**, approximately **50 players**, one shared political world. History is **fictional and player-created** each match. Not a historical timeline and not a clone of another game’s exact mechanics.
- **Subordination is gameplay, not elimination.** Being conquered or becoming a subject does not automatically remove a player from the match. Powerful subordinate play must remain viable.
- Previous **single-player-oriented** development assumptions are **superseded**. **Political Hierarchy V0.1 is accepted / complete** (human Lords, voluntary vassalage). **Territory / Map Foundation V0.1 is accepted / complete.** **Title Progression V0.1 is accepted / complete.** Currently approved core play treats the human as their match ruler; do not implement aging, family simulation, generational succession, or natural character death. Further hierarchy features still require director authorization.
- Victory conditions are conceptual only. Do not implement victory math until those systems are formally designed.

## Political hierarchy (V0.1 — specified and implemented as a limited prototype)

- Foundational system. Nested ruler-to-ruler trees. Server-authoritative. Clients may request and display; the server validates.
- **V0.1 implementation:** `PoliticalHierarchyService` owns truth. Two Studio remotes: `HierarchyClientEvent` (intents) and `HierarchyServerEvent` (state/notices). Shared rank rule lives in `PoliticalRankRules` for display and server validation; the server always revalidates.
- **Normal play:** joining humans are Independent Lords. Higher landed ranks (Duke / King / Emperor) are established through Title Progression V0.1 when qualified; server debug/test fixtures remain available.
- **Voluntary vassalage (player-facing term: Vassalage, not Fealty):** offer → accept/decline; both must agree; requests expire after **30 seconds** (V0.1 tuning). Expired/stale/superseded requests cannot mutate hierarchy. After accept or decline, the server notifies **both** the initiator and the receiver.
- **Disconnect (temporary prototype):** leaving players have their runtime ruler removed; direct vassals become independent; descendant trees of remaining rulers stay intact. No AI replacement, reconnection, succession, or persistence. Territory / Map Foundation V0.1 listens to hierarchy `RulerRemoving` and sets that leaver’s **directly owned territory to Unclaimed**.
- **Ranks:** Lord → Duke → King → Emperor (four primary landed levels). This supersedes earlier Count-tier wording.
- **Normal start:** every participating player is an **Independent Lord** with **one** starting territory. No player Dukes/Kings/Emperors at match start.
- **Independence** is a status, not a rank. Rank and independence are separate.
- Distinguish **direct liege**, **direct vassals**, **indirect subjects**, independent rulers, top ruler, and greater-realm membership.
- **Voluntary vassalage** (both agree): allowed to equal or higher rank; **never** to lower rank. Equal-rank vassalage is allowed so blocs can form at Lord before higher titles exist.
- When a ruler’s liege changes (join or leave a greater realm), **existing subordinate trees stay attached**. Do not flatten internal hierarchy.
- Humans and NPCs may eventually share the same conceptual rules; detailed NPC political AI is unspecified.
- **No cycles.** Reject becoming subordinate to someone already in your subordinate tree.
- Title **establishment:** see **Title Progression V0.1** (accepted / complete). Sequential next-rank only. Vale test numbers are map-specific. Prestige is a threshold, **not spent**. Gold/Influence are not requirements. No auto-promotion. No auto-demotion. Title-loss remains unresolved.
- **Unresolved (do not invent):** title-loss; vassal obligations; independence methods; disconnect/reconnect; join-in-progress; title-scaling for maps other than Vale V0.1 test thresholds. War may later change hierarchy without eliminating players; war outcomes are not designed.

## Maps, title scaling, economy, monetization (checkpoint — specified, not implemented)

- Primary board: large interactive GUI political map. Multiple fictional maps; territory counts may differ; geography is stable per map and separate from political realm names. Map size and title scaling do **not** depend on human player count.
- `TitleRequirements = f(MapConfiguration)` — deterministic, configuration-driven. Greater-realm control counts. Do not hardcode universal X/Y/Z territory counts. **Vale Title Progression V0.1 test numbers** (Duke 2/100, King 5/250, Emperor 10/500) are locked for that prototype map only.
- Match resources reset each match: **Gold** (economic), **Prestige** (legitimacy), **Influence** (political leverage) — conceptually distinct.
- Account-level persist: **Crowns** (premium/cosmetic working name; not competitive match power) and **Lifetime Support** (non-spendable statistic; spending Crowns does not reduce it).
- Prefer procedural/curated naming, not external generative AI. Default realm names on title establishment; custom names optional and must be filterable. Never block establishment for lack of a custom name.
- Simulation performance: store state; calculate on meaningful change; do not poll/recalculate unchanged political info every frame.

## Territory / Map Foundation (V0.1 — accepted / complete)

- Reusable interactive political world map. GUI-first. Renderer is **map-agnostic**: current `MapConfiguration`, not a hardcoded 16-province system. V0.1 happens to use one **16-territory** test map; 16 is not a universal future count.
- Maps are **hand-authored presets**, not per-match procedural worlds. Multiple future maps may differ in count, shape, names, adjacency, and layout. No required recommended-player-count metadata. AI filling gaps is future; **no AI in V0.1**.
- **Territory** = smallest ownable unit; not subdivided. Static map definition: ID, display name, polygon geometry, adjacent IDs. Match state: owner and political/realm relationship. Do not bake ownership into geometry.
- Visuals: stylized **irregular polygons** (not hexes); fictional geographic names belong to the land, not the ruler (examples only: Westmere, Northvale, Greyfen, Highmarch).
- Humans start with **one unique random** available territory assigned on join after the ruler exists. No fixed Player1/Player2 slots. Unused territories are **Unclaimed** (neutral gray, still selectable). No NPC rulers to occupy leftovers. Practical V0.1 capacity = 16 starting humans. **17th human / no free territory is unresolved — do not invent.**
- Disconnect (with existing hierarchy cleanup): leaver’s directly owned territory → Unclaimed. No AI, reconnect, or succession.
- Realm colors: automatic curated palette; players do not choose in V0.1. Greater-realm fill vs direct-owner secondary indicator. Ownership ≠ hierarchy membership. Do not change Political Hierarchy V0.1 to achieve this.
- Every territory selectable. Info panel: name, ID, owner, rank, independent/subject, greater realm/root. Unclaimed labeled Unclaimed. No economy/war/religion/buildings. No claim/conquer/trade/gift/purchase. Server-only debug ownership changes allowed for tests, not as gameplay.
- Desktop: pan, wheel zoom, click select; bounded camera; initial view frames the test map. Touch/controller not required. “Focus my realm” not V0.1. Adjacency stored from day one; not used for war in V0.1.
- Server authoritative over ownership, assignment, and match map state. Client renders and displays. Calculate-on-change.
- **Implementation (2026-08-23):** `MapCatalog` / `ValePrototypeMap` (`vale_prototype_16`, 16 jittered quads). `TerritoryMapService` owns match ownership; clients request a snapshot via `TerritoryClientEvent` Ready / `TerritoryServerEvent` State (JSON). Renderer is ViewportFrame + WedgePart triangles (EditableImage blocked by Studio security). Fill = greater-realm color; inset rim = direct holder; selection is a separate inward gold ring (does not replace fill or holder color). `DebugSetOwner` is server-only. Client remotes do not mutate ownership. **Accepted / complete** after director two-client runtime testing (unique starts, Unclaimed remainder, pan/zoom, vassalage visualization, disconnect Unclaimed). Acceptance does **not** authorize warfare, claims, economy, AI, persistence, extra maps, or other deferred systems.

## Title Progression (V0.1 — accepted / complete)

- Sequential landed ranks only: Lord → Duke → King → Emperor. No skipping.
- Qualification uses **greater-realm** territory control (direct holdings of the ruler plus subordinate tree), derived from existing hierarchy + territory ownership. Do not duplicate hierarchy authority. Establishment does not consume land.
- Eligibility and establishment are separate. Manual player action. Server revalidates. Client display is informational. No auto-promotion.
- Vale prototype **test** thresholds (not universal): Duke 2 territories / 100 Prestige; King 5 / 250; Emperor 10 / 500. Lord has no establishment. `TitleRequirements = f(MapConfiguration)`.
- Prestige in V0.1 is **temporary server-side test Prestige**. Checked, **not spent**. No Prestige economy. No client Prestige mutation.
- Established titles are **not** auto-demoted if control later falls below the creation threshold. Title-loss systems remain unresolved — do not invent them.
- Rank is not the political realm’s custom name. V0.1 naming may use a simple default for UI; full naming/custom UI is deferred; lack of a custom name must never block establishment.
- Rank change does not automatically rewrite liege/vassal links or flatten trees. Do not invent hierarchy restructuring.
- Title system must not own or mutate map geometry/ownership. Hierarchy and map V0.1 stay accepted.
- **Implementation (2026-08-23):** `TitleRequirements` reads `MapConfiguration.titleRequirements` (Vale rows only). `TitleProgressionService` reads hierarchy + ownership, holds per-ruler test Prestige (default 0, not spent), recalculates eligibility on change, and grants the next rank via `PoliticalHierarchyService.SetTitleRank` after revalidation. Client `TitleProgressionController` shows current/next/control/Prestige/eligibility and fires `Establish` intent only. Remotes: `TitleClientEvent` (Ready / Establish) and `TitleServerEvent` (State / Notice). Server-only debug: `DebugSetPrestige` and `ServerScriptService.TitleProgressionDebug` attributes (Play Server `_G.__TitleProgressionV01` may be nil in the Command Bar VM; the attribute bridge is the supported live setter). Rank change does not alter liege/vassals/land. Incoming vassalage uses `VassalageOfferOverlay`. **Accepted / complete** after director Local Server + 2 Players testing (vassalage, 2-realm Duchy eligibility, server-side 100 test Prestige, on-screen Establish Duchy, both clients saw Duke, prestige not spent, map/hierarchy/territory regression pass). Acceptance does **not** authorize a real Prestige economy, title-loss, warfare, claims, AI, extra maps, or other deferred systems.

## Source layout

- **Server** lives under `ServerScriptService`. `Services/` is reserved for authoritative server-side systems. `Bootstrap.server.luau` is a thin orchestrator only.
- **Client** lives under root-level `StarterPlayerScripts/` on disk, which Script Sync maps to `StarterPlayer.StarterPlayerScripts` in Studio. Do not use a nested `StarterPlayer/StarterPlayerScripts/` disk path. `Controllers/` is reserved for client behavior and GUI control. `Bootstrap.local.luau` is a thin LocalScript orchestrator only. Do not use `Bootstrap.client.luau` in this folder (Client RunContext Scripts run twice under `StarterPlayerScripts`).
- **Shared** lives under `ReplicatedStorage/Shared` (`Config/`, `Types/`, `Util/`). Shared modules must be safe for both sides and must not grant the client authority.
- **Remotes** live under `ReplicatedStorage/Remotes`. That folder is reserved for RemoteEvents and RemoteFunctions. Remote instances are created in Studio, not as Luau files.
- **GUI instances are not source-controlled as files.** They are created and edited through Roblox Studio MCP / Studio. Controllers drive GUI behavior; Services own authoritative state and validation. New GUI must integrate into one coherent prototype interface (central map when present; supporting panels/overlays; Play-mode verification). Not a license for an unsolicited full UI redesign. **Critical temporary actions** (incoming Vassalage Accept/Decline) must not depend on leftover space inside a permanently visible info panel; they use a map-centered overlay. Result toasts remain non-interactive outcome notices. **Prototype geometry:** primary panels (`Main`, `TitlePanel`, `MapStage`, `TerritoryInfo`) keep stable assigned regions; rank/eligibility/tree updates change content inside those regions, not panel Size/Position. Lists scroll in place. Future player-driven open/collapse is separate. **Prototype theme:** `ReplicatedStorage.Shared.Util.PrototypeGuiTheme` is the shared visual language for current panels/overlay/toast/buttons. Overlay stays more prominent; toast stays transient. Not final art.
- **Future UI shell (specified, not implemented).** The map should eventually fill the usable main canvas. Hierarchy, titles, diplomacy, economy, religion, and similar systems should open as contextual panels/overlays, not as permanently stacked chrome. Activation will use on-screen navigation and/or keybinds; **keys are not assigned**; navigation/bindings must be centralized. Major-panel open state should replace or coexist deliberately. Priority action overlays stay above whatever panel is open. Toasts stay separate. Functional clarity first. Do not implement this shell or add keybinds from this checkpoint.
- **Input layering / click-through (standing).** A higher-priority visible GUI that occupies the pointer must consume it; the map must not also pan, zoom, or select. Block input to the **bounds** of that GUI, not the whole screen by default. Do not rely on ZIndex alone. **Map implementation:** `TerritoryMapController` uses `GetGuiObjectsAtPosition` on pointer events for `VassalageOfferOverlay`, `TitlePanel`, `Main`, and `TerritoryInfo`. ResultToast is not a blocking layer. Mouse wheel over the map is allowed even when Roblox sets `gameProcessed` because `MapStage` is Active; that flag is not treated as higher-GUI blocking.
- **The client is never trusted** for authoritative game decisions.
- Avoid monolithic scripts. Do not introduce frameworks or external dependencies unless a later decision records that change.

## Project knowledge

- **`AI/GAME_DESIGN.md` is the authoritative product/game vision (design bible v0.1).** Agents must not materially change it unless the user explicitly requests a design change. Unspecified mechanics are not a license to invent systems.
- **`AI/ROADMAP.md` is dependency order.** Do not implement major later-phase gameplay early. **Phase 1 is complete.** Political Hierarchy V0.1 is **accepted / complete**. Territory / Map Foundation V0.1 is **accepted / complete**. Title Progression V0.1 is **accepted / complete**. Do not start Phase 2 character simulation or later systems unless directors authorize them.
- **Operating rule:** `.cursor/rules/project.mdc` always applies. Before substantial work, read `AI/GAME_DESIGN.md`, `AI/ROADMAP.md`, `AI/PROGRESS.md`, and `AI/DECISIONS.md`.
- Continue using `AI/PROGRESS.md`, `AI/DECISIONS.md`, and `AI/CHANGELOG.md` for state, decisions, and history.
