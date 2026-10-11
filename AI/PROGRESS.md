# Progress

## 2026-10-10 — Creator game presentation settings and GUI audio

**IMPLEMENTED — AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Native GAME UI/GAME AUDIO categories extend installed Kohl v0.17.0 through an isolated project addon; vendor source and personal saved appearance remain unchanged. Owner/creator edits server-wide validated runtime settings; GameTesters/SuperAdmins view only; real spoofed requests are rejected. GothamSSm default matches the inspected active FontFace. Dynamic theme application, semantic audio, safe density and text reflow are integrated without gameplay changes. Verification: 161 server assertions, 99 final owner-client assertions, three-client replication/remote denial and 252 min/default/max layout assertions across VGA/HD720/wide profiles. Persistence remains future work because no game persistence infrastructure exists. See [GAME_PRESENTATION_SETTINGS.md](GAME_PRESENTATION_SETTINGS.md). Commit/push to main authorized; no Roblox publication.

## 2026-10-10 — GameTester SuperAdmin permission update

Implemented the explicitly requested allowlist additions and trusted server Kohl SuperAdmin+ alternative in the central admin gate. All 21 existing GameTester commands share that gate; unrelated Kohl permissions remain unchanged. Targeted Studio verification covers effective rank, allowlist, revocation, malformed requests, real remote denial despite spoofed client attributes/arguments, and authorized command/help execution. See [ADMIN_PERMISSIONS.md](ADMIN_PERMISSIONS.md) for evidence and limitations. No gameplay mechanics or permanent ranks changed; no additional Director acceptance or Roblox publication.

## 2026-10-10 — Repository baseline finalization

Director approved preserving the current implementation and explicitly authorized one commit and a normal push to the existing branch. This does not promote agent-only checks to Director acceptance. All 65 disk sources matched Studio; all compiled; targeted running-client smoke verified map/navigation, Unclaimed militia UI, Tab transitions and Domination initialization. Archived recovered executables are disabled; one active Communications service/controller remains. Final offline snapshot: `docs/verification/finalized-baseline-2026-10-10.rbxl`. Reports retain real-account Communications and human balance/acceptance limitations. No new feature, redesign, gameplay change or Roblox publication. See [FINALIZATION.md](FINALIZATION.md).

## 2026-10-10 — Unclaimed conquest and Domination V0.x

**IMPLEMENTED — AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Explicit Director authorization supersedes the earlier Unclaimed/design-only restriction for this scope. Territory-owned configurable persistent militia, normal military conquest, event-driven 70% realm Domination, exactly-once result, competitive freeze and inspectable final state are complete on disk and Studio. Solo mouse flow, three-client Local Server outcomes, stale targets, disconnects, fealty/independence recount, no-loot and HD720/VGA checks passed. 65 sources compile; 24 pure checks and 32 first-stage multiplayer assertions passed. Final 25 changed sources match Studio; recovery assets preserved; local place saved. See [CONQUEST_VICTORY.md](CONQUEST_VICTORY.md) for evidence and limits. Human balance/playtest and Director acceptance remain pending. No commit, push or publication.

## How to use this tracker

### 2026-10-09 takeover investigation

Communications recovery audit completed: see [COMMUNICATIONS_RECOVERY_AUDIT.md](COMMUNICATIONS_RECOVERY_AUDIT.md). Reviewed complete candidate and supporting changes against the frozen design; exercised three-client Local Server scenarios and preserved supplemental evidence. Recommendation **B: salvage selected parts and rebuild the rest**, based on native transport/moderation divergence, reproduced Alliance revocation and Council cleanup defects, and clipped GUI. Original five-script sources verified unchanged after tests. No gameplay integration, implementation acceptance, or design change; production account/filtering behavior remains unverified and provenance unresolved.

Agent ran Studio Play Solo and a two-client Local Server; observed map navigation, Gold/recruitment, Alliance accept/break, NAP decline, vassalage acceptance, title establishment, and combat arithmetic self-test. **Live Studio materially differs from this checkout:** existing Communications service/controller/config, dependencies, GUI, and admin commands are present despite disk design-only status. Provenance is unresolved. A partial five-script preservation snapshot and detailed evidence/limitations are linked in `AI/TAKEOVER_REPORT.md`. No gameplay source edits or new Director acceptance; deferred MIL-MP statuses unchanged. Reconcile versions before synchronizing or implementing.

Before substantial work, review `AI/GAME_DESIGN.md`, `AI/ROADMAP.md`, `AI/PROGRESS.md`, and `AI/DECISIONS.md`. After substantial work, update this file and append meaningful changes to `AI/CHANGELOG.md`. Record significant architectural decisions in `AI/DECISIONS.md`. Do not edit `AI/GAME_DESIGN.md` unless the user explicitly requests a design change.

A task must not be marked complete until it has been verified. Agent-first verification is required. **Deferred** multiplayer/emergent cases (`AI/PLAYTEST_BACKLOG.md`) do **not** count as PASS and do **not** equal Director acceptance; they may be non-blocking for further V0.x work per `.cursor/rules/project.mdc` rule 29.

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
- [x] Economy / Resources V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 Gold foundation only; not a complete economy). `EconomyService`; start 150; Vale 10 Gold/min `baseGoldIncome`; global 6s tick; direct-owner income; Unclaimed pays nobody; conquest future-income only; subject Gold preserved; no liege tax; spend/overspend; disconnect Gold wipe. Ordinary HUD is player-relevant. Kohl inspectgold/setgold/addgold/spendgold via AdminBridge. Prestige remains Title test Prestige. Influence deferred. Tall-vs-wide and delegated greater-realm authority remain **future**. Landless-liege political consequences remain unresolved and are **not** part of this acceptance.
- [x] Military / Armies V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope only; not a complete military game; not V0.2). Eighteen ordinary Director PASSes recorded below (2026-08-24). Eight MIL-MP overlay/race cases remain **DEFERRED** in `AI/PLAYTEST_BACKLOG.md` (deferred ≠ PASS; not a V0.x progress blocker). Privileged `resolvewar` unwind/reject is Agent-verified. Hidden rolls/commits are admin/debug only.
- [x] Player communications / chat **PRE-V0.5 REQUIRED — IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Recommendation B replacement and personal-territory Direct are implemented. Real-account peer filtering/privacy and observer delivery remain outstanding. See `AI/COMMUNICATIONS_IMPLEMENTATION.md` and `AI/PLAYTEST_BACKLOG.md`.
- [x] Admin / Testing Infrastructure V0.1 **Kohl live for current AdminBridge ops — not a complete admin product.** Official @Scripth Kohl's Admin is in the place. GameTester chat/command-bar commands: adminhelp, inspectwars, inspectterritory, inspectruler, setowner, setprestige, inspectgold, setgold, addgold, spendgold, inspecttroops, settroops, addtroops, inspectmilitary, inspectcontest, resolvewar. Kohl owner/ruler tokens use `adminOwnerToken` / `adminRulerToken` (raw parse + player suggestions; SetOwner also suggests `unclaimed`) so `;setowner <id> unclaimed` reaches AdminBridge. **Director-verified PASS (2026-08-24 Local Server):** autocomplete showed Player1, Player2, Player3, and `unclaimed`; `setowner` and `setgold` worked. Not a new unclaim gameplay system. **Studio-only:** Local Server synthetic UserIds `< 0` pass `AdminConfig.IsGameTester`; published servers now require the allowlist OR trusted Kohl SuperAdmin+. Project-owned themed feedback (ResultToast + AdminInspectPanel). Kohl addon `run` returns nothing (no gsub boolean error); prototype theme Fonts are `Font` datatypes (no FontFace EnumItem spam). `AdminDebug.Invoke` and `*Debug` folders remain. Kohl SuperAdmin+ qualifies under the 2026-10-10 Director ruling; lower ranks require the allowlist. Warfare V0.1 is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**. Economy V0.1 is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (Gold foundation only). Military / Armies V0.1 is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope).

## Project knowledge

- [x] `AI/GAME_DESIGN.md` created (structured placeholders; verified on disk)
- [x] `AI/ROADMAP.md` created (16 phases; Phase 1 complete; current authorized design milestone: Communications V0.x freeze)
- [x] `AI/PLAYTEST_BACKLOG.md` — canonical **V0.5 Playtest Verification Backlog** (deferred ≠ PASS)
- [x] Initial multiplayer game vision / design bible v0.1 written into `AI/GAME_DESIGN.md` (verified on disk; no gameplay implemented)
- [x] Political Hierarchy Design V0.1 specified/documented (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) — **V0.1 prototype accepted** after two-client accept and decline verification
- [x] Design checkpoint (maps, title progression, naming, economy, monetization, performance) specified/documented — map and title V0.1 implemented separately; naming/monetization still not implemented; **Economy / Resources V0.1** is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (Gold foundation)
- [x] Territory / Map Foundation V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [x] Title Progression V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after two-client director testing
- [x] Diplomacy V0.1 specified, implemented, and **accepted / complete** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`) after director Local Server multiplayer verification
- [x] Warfare / Conquest V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`). V0.1 only; future military systems must build on this authority.
- [x] Economy / Resources V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (`AI/GAME_DESIGN.md`, `AI/DECISIONS.md`). Gold foundation only; tall-vs-wide and delegated greater-realm authority remain future architecture.
- [x] Military / Armies V0.1 **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (`AI/GAME_DESIGN.md`). Ordinary V0.1 war resolution through Military battle feeding Warfare. Deferred MIL-MP overlay cases remain in `AI/PLAYTEST_BACKLOG.md` (deferred ≠ PASS).
- [x] Player communications / chat **PRE-V0.5 REQUIRED — IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Recommendation B replacement and personal-territory Direct are implemented. Real-account peer filtering/privacy and observer delivery remain outstanding. See `AI/COMMUNICATIONS_IMPLEMENTATION.md` and `AI/PLAYTEST_BACKLOG.md`.
- [x] Admin / Testing Infrastructure V0.1: official Kohl loader installed; listed AdminBridge commands live for GameTester UserIds; Studio debug fallback preserved.
- [ ] Confirm a full 0.1 feature freeze beyond the political-hierarchy prototype priority

## Economy / Resources V0.1 — director-accepted (2026-08-24)

**Status:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Economy / Resources V0.1 only** (Gold foundation). It is not a complete economy.

**Director-verified PASS (Local Server):**

- Multiplayer start **150 Gold**; both clients shared the same global 6-second payout countdown; one-territory income as specified
- Direct-owner **10 Gold/min**; **+1** per tick per owned land; two lands **+20 / +2**; three lands **+30 / +3**
- Warfare conquest transferred the target; **treasury not stolen**; future income followed new direct owner; landless defeated ruler **+0 Gold/min** and treasury stopped increasing
- Direct ownership transfer redirected future income; old owner’s Gold stayed intact
- Player3 vassal of Player1: **kept personal Gold**; still **+10 / +1** from their own land; Player1 got **no** liege share; no reset/merge/tax
- Unclaimed land pays **nobody** (income +0 after last holding removed; Gold stopped increasing; ownership restorable via existing `SetOwner` / `;setowner … unclaimed`)
- **Spend / overspend:** Player2 at 209 Gold, 0 income; `;spendgold Player2 500` → `Insufficient Gold.`, balance **209**; `;spendgold Player2 100` → `Spent 100 Gold.`, balance **109**; no partial spend; no negative
- **Disconnect Gold wipe:** Player2 disconnected with 109 Gold; Player1/Player3 did **not** receive it; they continued only territorial income; Player2’s war cancelled by Warfare disconnect cleanup; no inheritance

**Kohl raw-target autocomplete / admin UX:** **DIRECTOR-VERIFIED PASS** (Local Server). `adminOwnerToken` / `adminRulerToken`; suggestions listed Player1, Player2, Player3, and `unclaimed` on `setowner`; `setowner` and `setgold` worked. Suggestions are not authority. Not a new unclaim gameplay system.

Landless liege with surviving subjects is a **separate unresolved hierarchy/title case**, not an Economy bug.

Studio / Local Server / MCP sessions remain **development verification**, not the first real playtest.

**Git:** Director will commit/push in GitHub Desktop. Agents must not commit or push unless asked.

## Warfare / Conquest V0.1 — director-accepted (2026-08-24)

**Status:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Warfare V0.1** war-lifecycle authority. It is not a complete military game. **Military / Armies V0.1** **supersedes** same-target multiplicity and is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope; deferred MIL-MP rows remain).

**Director-verified PASS:**

- valid adjacent war declaration
- non-adjacent declaration rejection
- duplicate/matching active-war rejection
- attacker victory and target-territory transfer
- defender victory with ownership unchanged
- simultaneous competing wars against the same target territory (**historical Warfare V0.1 PASS**; same-target multiplicity **superseded** by Military / Armies V0.1)
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

## Military / Armies V0.1 — director-accepted (2026-08-24)

**Status:** **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** This accepts **Military / Armies V0.1 ordinary scope only**. It is not a complete military game and is not V0.2. Agent verification is not Director verification. Do not ask the Director to repeat these PASSes unless a concrete contradiction appears.

**Director-verified PASS (18):**

1. Last Battle summary readability (~20s; territory; VICTORY/DEFEAT; own/enemy committed; own casualties/survivors; ResultToast vs panel roles; new war overrides)
2. Attacker explicit commitment 0 + Ready → cancel; notice `Attack cancelled: you committed 0 Troops.`; no battle; no Last Battle; Troops unchanged; cooldown
3. Defender 0 / unopposed attacker victory (nonzero attacker); transfer; Last Battle enemy 0; 0 casualties; survivors = attacking force
4. Commitment editing while unlocked (global Total / Available / Committed)
5. Over-Available input: reject illegal amount; last valid intermediate auto-submit **accepted as-is for V0.1** (not a remaining UX fix; ugly OK, confusing is not)
6. Recruit after lock: Total/Available rise; locked commitment unchanged
7. Timeout / AFK: accepted commitment preserved; AFK opponent 0; battle proceeds; Last Battle/ownership coherent
8. 10s post-war cooldown (server: no immediate redeclare)
9. Post-war cooldown live UI refresh (selected territory flips back to Declare War without reselect)
10. Casualty / ledger after battle (example: 760 − 187 = 573; 187 + 313 = 500)
11. Multiple simultaneous wars / global overextension (no dual-use of the same Troops)
12. Selected-territory active-war Military context (independent wars, timers, presentation)
13. Territory-contextual Last Battle (example Brightfen/Duskfen; no cross-contamination)
14. Duplicate war on same territory rejected (`Already contested.`)
15. Defender victory / ownership unchanged; attacker Last Battle DEFEAT
16. Attacker victory / ownership transfer (example Duskfen; toast + Last Battle VICTORY; 92 + 708 = 800)
17. Pre-battle enemy commitment secrecy (locked 237 not shown to opponent; “Opponent preparing forces”)
18. Never-interacted attacker 55s cancel (Brightfen; toast `War cancelled (attacker did not commit).`; no battle; no Last Battle; ownership unchanged; Troops 862/862/0; idle Military; target post-war cooldown / disabled Declare)

**Ordinary Director checks remaining:** none.

**Deferred (not PASS, not V0.x progress blockers):** `AI/PLAYTEST_BACKLOG.md` **MIL-MP-01, MIL-MP-02, MIL-MP-03, MIL-MP-04, MIL-MP-05, MIL-MP-07, MIL-MP-10, remaining MIL-MP-11 races** (eight overlay/race cases). MIL-MP-06/08/09 ordinary observations **VALIDATED**. If later deferred testing shows Troop duplication, dropped outcomes, double resolution, stuck CONTESTED, or equivalent authoritative corruption, that is a real defect (no longer deferred).

Studio / Local Server / MCP sessions remain **development verification**, not the first real playtest.

**Git:** do not commit or push unless directors authorize.

## Communications V0.x — replacement implemented, partial agent verification (2026-10-09)

**Status:** **IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Director explicitly authorized recommendation B on 2026-10-09, superseding the earlier implementation prohibition. Frozen product rules remain canonical. Military / Armies V0.1 remains **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1). Eight MIL-MP rows remain deferred in `AI/PLAYTEST_BACKLOG.md`.

**Frozen (see `AI/GAME_DESIGN.md`):** Diplomatic (replaces General); Council = ruler + direct subjects; Allies = per Alliance (no NAP, no subject inherit); Direct = 1:1 + current border, send cut immediately if adjacency lost; Admin/Observer metadata + mute; live Title identity; TextChatService direction; no voluntary-speech censorship.

**Verification:** three Local Server clients exercised current political authority, Alliance break/reaccept IDs, border loss, Council creation/cleanup, identity and accepted-service smoke checks. Native sender receipts, blocked stale Council send (no false render), final wrapped/scrolling GUI and source integrity verified. Synthetic peer chat permissions denied native peer delivery; real-account filtering/privacy/observer and network lifecycle remain unverified. Director clarified Direct as personal-territory adjacency, relationship-independent; implemented and 26/26 targeted checks passed with three Studio clients, including same-root adjacent/non-adjacent, inherited-holding exclusion and immediate border loss/restoration. See `AI/COMMUNICATIONS_IMPLEMENTATION.md` for full matrix/evidence and file list; `AI/PLAYTEST_BACKLOG.md` COM rows for remaining tests. Recovered sources preserved inactive; one active replacement; ignored local .rbxl copy saved. No commit/push/publish. Deferred announcements omitted.

**Git:** do not commit or push unless directors authorize.

## 2026-10-09 — Authorized GUI / UX sprint

Map-first centralized navigation and responsive system drawers implemented; unified slate/gold styling, full-screen background, province labels, priority requests, Military decision presentation and readable admin inspect output. Agent exercised Solo, three-client political/war flows, native Solo messaging, small/common/wide layouts and targeted input probes. See [GUI_UX_SPRINT.md](GUI_UX_SPRINT.md) for evidence and limits. Director visual approval required; no new gameplay acceptance, commit, push or publication.

## 2026-10-10 — Custom Realm Overview

Director-authorized hold-Tab political player list implemented and agent-verified in Solo and three-client Local Server. Players navigation supplies nonkeyboard access. PlayerList-only CoreGui disable survives respawn; private resources excluded. Live hierarchy, holdings, Alliance/NAP/war, disconnect/root cleanup and same-root Direct revocation verified. Small/common/wide layouts, 50 diagnostic rows, typing focus and map input isolation exercised. See [REALM_OVERVIEW.md](REALM_OVERVIEW.md) for source/assets, fields, matrix and limits. NOT Director-accepted; no gameplay advancement, commit, push or publication.
