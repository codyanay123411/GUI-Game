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

## 2026-08-23 — Political Hierarchy V0.1 prototype

Implemented server-authoritative human Lord hierarchy, voluntary fealty with 30s request lifetime, rank/cycle validation, subordinate-tree preservation, two remotes, and a temporary Studio prototype GUI. Disconnect removes the runtime ruler (temporary; no AI replacement). No title progression, map, economy, or other gameplay systems.

## 2026-08-23 — Hierarchy V0.1 two-client verification pending

Corrected progress wording: V0.1 is implemented but **not accepted** until a real 1-server + 2-client Studio test passes. MCP `start_stop_play` only launches one play client; `Players:CreateLocalPlayer()` adds a dummy Player without a second client GUI/controller. No Git commit.

## 2026-08-23 — Hierarchy prototype GUI usability

Repositioned the V0.1 prototype panel to the right with CoreUISafeInsets (does not ignore Gui inset). Separated Self / tree / players / incoming sections, made Offer/Accept/Decline obvious, and distinguished “waiting for server” from “(no rulers)”. Gameplay unchanged. Two-client acceptance still pending.

## 2026-08-23 — Hierarchy V0.1 replication/UI bugfix

JSON-encoded hierarchy snapshots plus a client `Ready` handshake so Local Server clients are not stuck on “Waiting for server state...” if the first `FireClient` happens before `OnClientEvent`. Bound a single `HierarchyPrototypeGui`, destroyed extra clones, and converted client bootstrap to `Bootstrap.local.luau` (LocalScript) so Client RunContext no longer starts the controller twice. Player/request row clones force `Visible=true`. Gameplay rules unchanged. Two-client visual acceptance still pending.

## 2026-08-23 — Hierarchy V0.1 vassalage wording and dual notices

Player-facing “Fealty” is now **Vassalage**. Accept and decline notify both the initiator and the receiver from the server. Prototype result messages use a top-left toast. Gameplay rules unchanged. Two-client acceptance still pending.

## 2026-08-23 — Political Hierarchy V0.1 accepted

Directors confirmed Local Server + 2 Players: accept and decline both succeeded on both clients; hierarchy state matched; initiator and receiver both received the correct notifications; decline did not mutate hierarchy. V0.1 is **accepted / complete**. No gameplay code changed in this tracker update.

## 2026-08-23 — Territory / Map Foundation V0.1 design checkpoint

Documented Territory / Map Foundation V0.1 (16-territory test map, Unclaimed remainder, random unique human starts, irregular polygons, adjacency, bounded pan/zoom, greater-realm vs owner visualization, server-owned match map state). Specified only; no map implementation, Studio map GUI, or gameplay systems added.

## 2026-08-23 — GUI-first prototype consistency rule

Recorded a standing implementation rule: future GUI must join one coherent strategy-game interface (inspect live Studio UI first; central map when present; supporting panels/overlays; Play-mode verification; no isolated debug windows or cloned third-party UI). Documentation/rules only; no gameplay or Studio GUI changes.

## 2026-08-23 — Territory / Map Foundation V0.1 prototype

Implemented data-driven `MapConfiguration` (`vale_prototype_16`, 16 irregular quads), server-authoritative unique random human starts with Unclaimed remainder, ViewportFrame map with pan/zoom/select, greater-realm fill vs direct-holder rim, territory info panel, and hierarchy lifecycle unclaim. No warfare/claiming/AI. **Director acceptance and two-real-client tests pending.** No Git commit.

## 2026-08-23 — Territory selection additive gold ring

Selection no longer overwrites the direct-holder rim with yellow. Fill stays greater-realm color, holder rim stays the direct owner’s color, and selection is a separate inward gold WedgePart ring. Ownership and hierarchy logic unchanged. No Git commit.

## 2026-08-23 — Territory / Map Foundation V0.1 accepted

Directors confirmed two real Studio clients: unique starting territories, Unclaimed remainder, select/info, pan/zoom, vassalage greater-realm vs holder visualization, additive gold selection, and disconnect Unclaimed/hierarchy cleanup. V0.1 is **accepted / complete**. Unused leftover `MapWorld` ImageLabel removed. Deferred systems unchanged. No Git commit.

## 2026-08-23 — Title Progression V0.1 prototype

Implemented sequential Lord → Duke → King → Emperor from map-configured Vale test thresholds, greater-realm control (hierarchy descendants + ownership), temporary server-side test Prestige (not spent), Ready/Establish remotes, TitlePanel, and `SetTitleRank` without rewriting liege/vassals/land. Server revalidation rejects insufficient land/Prestige and does not skip ranks. Debug Prestige is server-only. **Not director-accepted;** two-real-client Establish Duchy still required. No Git commit.

## 2026-08-23 — Incoming vassalage overlay (layout)

Incoming Accept/Decline no longer live in the clipped bottom of the hierarchy panel. They use a map-centered `VassalageOfferOverlay` so the offer stays actionable beside Title Progression. Result toast remains a non-interactive outcome notice. Gameplay rules unchanged. Two-real-client retest still required. No Git commit.

## 2026-08-23 — Future UI shell / keybind architecture (docs only)

Recorded long-term GUI direction: full-canvas map; major systems as contextual panels/overlays with centralized (unassigned) keybinds and/or nav buttons; coherent panel state; priority action overlays vs toasts. Standing click-through / input-layering rule: higher-priority GUI consumes pointer events within its bounds; map is the lowest input layer. No Luau, Studio GUI, keybinds, or gameplay changes. Title V0.1 acceptance continues on the current prototype. No Git commit.

## 2026-08-23 — Title Progression V0.1 accepted

Directors confirmed Local Server + 2 Players: both clients started as Lords; Political Hierarchy and Territory / Map V0.1 still worked; vassalage between the two real players; greater-realm count included subordinate land (2 / 2); server-side test Prestige set to 100 and not spent; Title panel Eligible + Establish Duchy; director clicked Establish Duchy; Player1 became Duke; Player2 saw the updated rank; liege/vassals/ownership/hierarchy/territory info/map visualization remained correct; pan/zoom/select regression pass; no blocking runtime issue. Incoming Vassalage overlay already in place. V0.1 is **accepted / complete**. Deferred systems unchanged. No Git commit.

## 2026-08-23 — Map input layering (click-through)

Map pan/select/zoom now ignore pointer events that sit over `VassalageOfferOverlay`, `TitlePanel`, hierarchy `Main`, or `TerritoryInfo` (`GetGuiObjectsAtPosition` on the event, not per frame). Clicks on unobstructed map still select. Result toast is not a blocking layer. Gameplay rules unchanged. No Git commit.

## 2026-08-23 — Prototype GUI layout stability

Right-side hierarchy now fills down to a fixed-height Title panel (small gap) instead of a shortened 500px box with dead space. Title content/button state no longer hides the Establish slot. Gameplay-state updates stay inside assigned regions. No Git commit.

## 2026-08-23 — Map pan/zoom after theme (input correction)

Mouse-wheel zoom was dropped because Active `MapStage` marks wheel as `gameProcessed`. That blocked zoom, and default-zoom camera clamp made pan appear dead. Zoom now uses map-vs-higher-GUI hit tests, not a blanket `gameProcessed` reject. Theme/layout unchanged. No Git commit.

## 2026-08-23 — Prototype GUI theme consistency

Hierarchy, Title, TerritoryInfo, Vassalage overlay, and ResultToast now share one prototype theme (`PrototypeGuiTheme`): panel tone, stroke, corners, type hierarchy, and button states. Overlay keeps stronger gold emphasis; toast stays distinct transient feedback. Primary panel geometry and gameplay unchanged. No Git commit.

## 2026-08-23 — Diplomacy V0.1 prototype

Implemented server-authoritative Alliance and NAP between independent root rulers: 30s pending requests, unordered duplicate rejection, unilateral break, dissolve on loss of independence (no liege transfer), disconnect cleanup, `AreAllied` / `HasNonAggressionPact`. Prototype GUI: `DiplomacyPanel` in the right column above Title, `DiplomacyOfferOverlay` for incoming Accept/Decline, toasts, theme + map input layering. One-client Studio tests with mock rulers passed pending director multiplayer acceptance. No warfare/opinion/autonomy. No Git commit.

## 2026-08-23 — Diplomacy V0.1 accepted

Directors confirmed Local Server multiplayer verification, including independent human rulers and subject behavior: human GUI offer → real second-client overlay; Alliance Accept; NAP Accept; Alliance/NAP Decline; Alliance + NAP coexistence; independent Break; both clients updated after agreement changes; 30s pending expire; subject read-only diplomacy; loss of independence dissolves external diplomacy with no transfer to the new liege; disconnect of an independent ruler with active diplomacy removes that ruler and dissolves the survivor’s agreements; diplomacy remains rooted at the independent greater-realm ruler; no observed regression to hierarchy, territory/map, title progression, GUI layering, pan/zoom/select, or prototype theme/layout. V0.1 is **accepted / complete**. Deferred diplomacy unchanged. No Git commit.
