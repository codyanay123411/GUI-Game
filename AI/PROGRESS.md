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
- [x] Warfare / Conquest V0.1 **implemented — partially director-verified — acceptance testing paused — not director-accepted.** Director Local Server tests that **passed** are listed under the pause checkpoint below. Vale 8-neighbor adjacency and the attacker-victory pipeline (Greyfen transfer → map refresh → Title control 1/2→2/2) are **director-verified**. **Not complete.** Do not infer remaining cases from MCP/agent tests. Hierarchy, Territory / Map, Title Progression, Diplomacy V0.1, and prototype GUI maintenance remain accepted / director-verified.
- [x] Admin / Testing Infrastructure V0.1 **architecture recorded; foundation partial.** `AdminBridge` + Studio `AdminDebug.Invoke` wrap existing service APIs. Kohl's Admin **not installed** in the place (Director must insert official @Scripth loader). Chat commands not live. Warfare acceptance status unchanged.

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
- [x] Warfare / Conquest V0.1 **implemented — partially director-verified — acceptance testing paused — not director-accepted** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`). Resume at Defender Victory.
- [x] Admin / Testing Infrastructure V0.1 specified; small Admin Bridge foundation implemented; Kohl loader **not** in the place.
- [ ] Confirm a full 0.1 feature freeze beyond the political-hierarchy prototype priority

## Pause checkpoint — Warfare / Conquest V0.1 (2026-08-23)

Director stopped acceptance testing. **Do not continue implementation** until authorized. **Do not mark Warfare V0.1 accepted.**

**Status:** implemented — partially director-verified — acceptance testing paused — **not** director-accepted.

**Corrections this session (implementation already in the working tree):**
1. Greater-realm adjacency GUI now shares `WarfareAdjacency` with the server (server was already authoritative).
2. Territory-specific Declare War / Additional War copy in `TerritoryInfo` (presentation only).
3. Vale map data: 8-neighbor (edge or corner) lattice; **director-verified**.

**Director-verified PASS:** pan/zoom/select; greater-realm and vassal-border declaration; non-adjacent / true non-neighbor prevention; subject cannot declare; NAP blocks; breaking NAP restores eligibility; immediate declaration (no Accept/Decline); multiple territorial wars between the same roots; duplicate attacker+same-target rejection; additional-war presentation; diagonal/corner adjacency; **attacker victory** on Greyfen (`warId` `d34b9750-29ff-4c8a-bb22-f066c334f04b`, `Player_-1` vs `Player_-3`) via `WarfareDebug.Invoke("Resolve", warId, "Attacker")` — ownership/color updated, war cleared, Title control 1/2→2/2, hierarchy intact.

**Stopped immediately before:** **Defender Victory.** On resume: Local Server multiplayer; declare a valid adjacent war; read `ServerScriptService.WarfareDebug.LastSnapshot.Value`; `Invoke("Resolve", warId, "Defender")`. Expect war ends, defender keeps the target, no transfer, no Prestige/truce/claim effects.

**Still not director-verified (do not mark passed from MCP tests):** Defender Victory; competing same-target wars then first attacker victory + stale cleanup; participating-root disconnect during war; loss of independence during war / no liege inheritance.

**Git at pause:** branch `main`, HEAD `e742f31` (Accept Diplomacy V0.1), **ahead of origin/main by 1**. Warfare implementation and these docs are **uncommitted** working-tree changes. Do not discard, reset, stash, commit, or push unless directors authorize.
