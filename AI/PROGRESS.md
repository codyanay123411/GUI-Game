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

## Project knowledge

- [x] `AI/GAME_DESIGN.md` created (structured placeholders; verified on disk)
- [x] `AI/ROADMAP.md` created (16 phases; current phase 1; verified on disk)
- [x] `.cursor/rules/project.mdc` created (always-apply operating rule; verified on disk)
- [x] Initial multiplayer game vision / design bible v0.1 written into `AI/GAME_DESIGN.md` (verified on disk; no gameplay implemented)
- [x] Political Hierarchy Design V0.1 specified/documented (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) — **V0.1 prototype accepted** after two-client accept and decline verification
- [x] Design checkpoint (maps, title progression, naming, economy, monetization, performance) specified/documented — map and title V0.1 implemented separately; naming/economy/monetization still not implemented
- [x] Territory / Map Foundation V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [x] Title Progression V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [ ] Confirm a full 0.1 feature freeze beyond the political-hierarchy prototype priority
