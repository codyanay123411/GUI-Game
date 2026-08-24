# Progress

## How to use this tracker

Before substantial work, review `AI/GAME_DESIGN.md`, `AI/ROADMAP.md`, `AI/PROGRESS.md`, and `AI/DECISIONS.md`. After substantial work, update this file and append meaningful changes to `AI/CHANGELOG.md`. Record significant architectural decisions in `AI/DECISIONS.md`. Do not edit `AI/GAME_DESIGN.md` unless the user explicitly requests a design change.

A task must not be marked complete until it has been verified.

## Environment setup

- [x] Cursor local agent configured
- [x] Roblox Studio MCP connected and tested
- [x] Script Sync configured and tested
- [x] Git repository initialized
- [x] `.gitignore` added
- [x] Temporary Script Sync test removed (`ServerScriptService/VibeCodingSyncTest.luau`)
- [x] Private GitHub repository published

## Game architecture

- [x] Define GUI-first game architecture (`docs/ARCHITECTURE.md`)
- [x] Source-controlled folder layout created and verified on disk
- [x] Client disk path corrected to root `StarterPlayerScripts/` (duplicate `StarterPlayer/` removed; verified on disk)
- [x] Verify Script Sync folders appear in Studio (placeholder modules materialize reserved folders; bootstraps still match disk)
- [ ] Plan core screens, flows, and data ownership
- [x] Implement initial architecture in synced Luau source (Phase 1 bootstrap: thin bootstraps, reserved folders, `_Placeholder.luau` only; verified on disk and in Studio). This is **not** gameplay implementation.

## Phase 1 status

- [x] **Phase 1 — Foundation & Architecture: COMPLETE** (audit: PASS WITH MINOR CLEANUP; documentation cleanup verified). Ready for the first gameplay prototype **when directors authorize it**.
- [x] Political Hierarchy V0.1 **accepted / complete** (directors confirmed Local Server + 2 Players). Human Independent Lords, voluntary vassalage, rank/cycle validation, tree preservation, 30s request TTL, prototype GUI, temporary disconnect cleanup, dual accept/decline notices. Player-facing term is **Vassalage**.
- [x] Territory / Map Foundation V0.1 **accepted / complete** (directors confirmed two real Studio clients: unique starts, Unclaimed remainder, select/info, pan/zoom, vassalage map recolor with holder vs realm distinction, gold selection ring, disconnect Unclaimed and hierarchy cleanup). Political Hierarchy V0.1 remains accepted. Warfare, claims, economy, AI, and other deferred systems **not** included.
- [x] Title Progression V0.1 **accepted / complete** (directors confirmed Local Server + 2 Players: both Lords; vassalage; greater-realm count 2/2; server-side 100 test Prestige; on-screen Establish Duchy; Player1 became Duke; prestige not spent; Player2 saw the rank; liege/vassals/land intact; territory info and map visualization correct; pan/zoom/select regression pass). Vale test thresholds remain Duke 2/100, King 5/250, Emperor 10/500. Incoming vassalage uses `VassalageOfferOverlay`. Political Hierarchy V0.1 and Territory / Map Foundation V0.1 remain accepted. Real Prestige economy, title-loss, warfare, claims, AI, and other deferred systems **not** included.
- [x] Prototype GUI layout stability (maintenance): right-side Hierarchy + Title use assigned regions; title rank/content updates do not reflow primary panel geometry; hierarchy fills down to a fixed-height title footer. Map click-through layering preserved. Not a new gameplay system.
- [x] Prototype GUI theme consistency (maintenance): Hierarchy, Title, TerritoryInfo, Vassalage overlay, and ResultToast share `PrototypeGuiTheme`. Layout stability and input layering preserved. Not a new gameplay system.
- [x] Prototype GUI maintenance batch **director-verified / complete** (input layering, layout stability, unified theme, pan/zoom `gameProcessed` correction). Future prototype GUI must respect those rules. Not a new gameplay system.
- [x] Diplomacy V0.1 **accepted / complete** (directors confirmed Local Server multiplayer: independent human rulers and subject behavior). Human GUI offer → real second-client overlay; Alliance Accept; NAP Accept; Alliance/NAP Decline; Alliance + NAP coexistence; independent Break; both clients updated after agreement changes; 30s pending expire; subject read-only diplomacy; loss of independence dissolves external diplomacy with no transfer to the new liege; disconnect of an independent ruler with active diplomacy removes that ruler and dissolves the survivor’s agreements; diplomacy remains rooted at the independent greater-realm ruler. No observed regression to hierarchy, territory/map, title progression, GUI layering, pan/zoom/select, or prototype theme/layout. Political Hierarchy V0.1, Territory / Map Foundation V0.1, and Title Progression V0.1 remain accepted. Warfare, opinion, vassal diplomatic autonomy, and other deferred systems **not** included.
- [x] Warfare / Conquest V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 only; not a complete military game). Director-verified PASS: valid adjacent declaration; non-adjacent rejection; duplicate/matching active-war rejection; attacker victory and target-territory transfer; defender victory with ownership unchanged; simultaneous competing wars against the same target; stale-war cleanup after another attacker captures the target; loss of independence during an active war terminates the war; the new liege does not inherit that war; defender-root disconnect terminates the war without conquest; attacker-root disconnect terminates the war without conquest (most recent: Player1 attacker vs Player3 defender, target frostfield; remaining client “War cancelled (left the match).”; ordinary Territory UI no active wars; no transfer); disconnect cleanup leaves no active stale war; ordinary Warfare GUI player/realm-relevant; admin InspectWars remains global; AdminBridge ResolveWar uses `WarfareService.DebugResolveWar`. Hierarchy, Territory / Map, Title Progression, Diplomacy V0.1, and prototype GUI maintenance remain accepted / director-verified.
- [x] Admin / Testing Infrastructure V0.1 **Kohl live for current AdminBridge ops — not a complete admin product.** Official @Scripth Kohl's Admin is in the place. GameTester chat/command-bar commands: adminhelp, inspectwars, inspectterritory, inspectruler, setowner, setprestige, resolvewar. **Studio-only:** Local Server synthetic UserIds `< 0` pass `AdminConfig.IsGameTester`; published servers still require the allowlist. Project-owned themed feedback (ResultToast + AdminInspectPanel). Kohl addon `run` returns nothing (no gsub boolean error); prototype theme Fonts are `Font` datatypes (no FontFace EnumItem spam). `AdminDebug.Invoke` and `*Debug` folders remain. Kohl rank is not GameTester. Warfare V0.1 is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**.

## Project knowledge

- [x] `AI/GAME_DESIGN.md` created (structured placeholders; verified on disk)
- [x] `AI/ROADMAP.md` created (16 phases; current phase 1; verified on disk)
- [x] `.cursor/rules/project.mdc` created (always-apply operating rule; verified on disk)
- [x] Initial multiplayer game vision / design bible v0.1 written into `AI/GAME_DESIGN.md` (verified on disk; no gameplay implemented)
- [x] Political Hierarchy Design V0.1 specified/documented (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) — **V0.1 prototype accepted** after two-client accept and decline verification
- [x] Design checkpoint (maps, title progression, naming, economy, monetization, performance) specified/documented — map and title V0.1 implemented separately; naming/economy/monetization still not implemented
- [x] Territory / Map Foundation V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [x] Title Progression V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [x] Diplomacy V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after director Local Server multiplayer verification
- [x] Warfare / Conquest V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`). V0.1 only; future military systems must build on this authority.
- [x] Admin / Testing Infrastructure V0.1: official Kohl loader installed; listed AdminBridge commands live for GameTester UserIds; Studio debug fallback preserved.
- [ ] Confirm a full 0.1 feature freeze beyond the political-hierarchy prototype priority

## Warfare / Conquest V0.1 — director-accepted (2026-08-24)

**Status:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Warfare V0.1 only**. It is not a complete military game.

**Director-verified PASS:**

- valid adjacent war declaration
- non-adjacent declaration rejection
- duplicate/matching active-war rejection
- attacker victory and target-territory transfer
- defender victory with ownership unchanged
- simultaneous competing wars against the same target territory
- stale-war cleanup after another attacker captures the target
- loss of independence during an active war terminates the war
- the new liege does not inherit the former independent ruler's war
- defender/root disconnect terminates the active war without conquest
- attacker/root disconnect terminates the active war without conquest
- disconnect cleanup leaves no active stale war
- ordinary Warfare GUI uses player/realm-relevant war information
- admin InspectWars remains intentionally global
- AdminBridge ResolveWar continues to use WarfareService's authoritative debug resolution path

**Most recent disconnect mirror test:** Player1 attacker vs Player3 defender, target frostfield; active war confirmed before disconnect; Player1 disconnected while the war was active; remaining client received “War cancelled (left the match).”; ordinary Territory UI reported no active wars afterward; no conquest/ownership transfer.

**Previous disconnect test:** defender disconnected during an active war; war terminated; no conquest; no stale active war remained.

**Previous political-state test:** Player2 was an independent defender in an active war; Player2 became a vassal of Player3; the active war terminated; Player3 did not inherit Player2's war.

Studio / Local Server / MCP sessions remain **development verification**, not the first real playtest.

**Git:** do not commit or push unless directors authorize.
