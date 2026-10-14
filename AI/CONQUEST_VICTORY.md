# Unclaimed conquest and Domination V0.x

Implemented 2026-10-10 under the Director's explicit request. **Agent-verified; Director acceptance pending.** Existing Communications, GUI sprint, Realm Overview and recovery assets are preserved. No commit, push or publication.

## Gameplay and architecture

Unclaimed territories now contain territory-owned militia, with no NPC ruler, treasury or loot. Defense precedence is territory override, map override, then NeutralDefenseConfig.BaseDefenders; Vale uses 300. Failed battles leave surviving defenders in that territory for the remainder of the match. Regeneration is deferred. Existing independent-root war authority, greater-realm adjacency, target locks, cooldowns, commitment limits, troop ledgers and combat remain authoritative. Roots can attack through a subject's border; subjects do not acquire independent external-war permission. Successful conquest uses normal ownership, income and title qualification.

NeutralDefenseService owns militia and revision validation. WarfareService records target kind and ownership revision. MilitaryService resolves neutral defense through the existing battle flow and rejects stale ownership or removed attackers, including during result presentation. Unclaimed information and blocked Conquer reasons are shown in the normal territory and military UI.

Domination uses a configurable map threshold of 70%, rounded up against every conquerable territory including Unclaimed: Vale requires 12 of 16. Root and all descendants count together. VictoryService evaluates meaningful ownership/hierarchy changes and synchronous mutation boundaries. MatchState permits only the first final result. A root wins, its descendants receive Realm Victory, and other players receive Defeat. Final identity, membership, ownership, counts and timestamps are retained.

The end freezes competitive mutation, income, pending wars and reserved commitments. Map inspection, Players, Messages and reopening Match Result remain available. Winner disconnects preserve final state; late joiners receive the final result without new rulers or free territory. There are no kicks, rematch, lobby or rewards. AdminBridge provides authorized InspectVictory, CheckVictory, InspectNeutral and SetNeutralDefense; changing defense is blocked during contests and after the match.

## Verification evidence

Test fixtures are saved under docs/verification/conquest-victory-*.luau.txt. They were temporary runtime server scripts using the existing service APIs with actual Studio players; accelerated battle timers and prepared ownership/Gold/troop/title state are test setup, not normal gameplay claims. All runtime fixtures were removed by ending their sessions.

| Scenario | Agent result | Evidence |
| --- | --- | --- |
| UC-PURE-01: threshold, denominator, nested realms, independence, malformed config and exactly-once state | PASS, 24 pure checks | conquest-victory-pure-checks.luau |
| UC-MP-01: unknown/nonadjacent/contested targets, invalid commitments, outsider requests, failure survivors, capture, cooldown, stale revision, cancellation, ledgers and owned-war/NAP regression | PASS, 32 assertions with three actual clients | conquest-victory-stage-one-pass.jpg; stage-one fixture |
| UC-MP-02: ownership changes after mechanical resolution | PASS; stale capture rejected | stage-two fixture and stage-two-pass.jpg |
| UC-MP-03: pending and resolved attacker actually disconnects | PASS; no transfer, no leaked engagement/war | conquest-victory-attacker-disconnect-pass.jpg |
| UC-MP-04: root attacks through subject holdings | PASS; subject independent attack rejected | stage-two fixture |
| VIC-MP-01: 11 to 12 realm holdings, concurrent pending battle, exactly-once final result and authority freeze | PASS | stage-two fixture and stage-two-pass.jpg |
| VIC-MP-02: root/subject/outsider presentation | PASS on three actual clients | conquest-victory-root-victory.jpg; realm-victory.jpg; defeat.jpg |
| VIC-MP-03: fealty immediately crosses threshold | PASS | conquest-victory-fealty-trigger-pass.jpg |
| VIC-MP-04: live root disconnect causes independence and recount before victory | PASS | conquest-victory-independence-pass.jpg |
| VIC-MP-05: winner leaves and late clients join | PASS; final realm retained, no new ruler/land | conquest-victory-winner-disconnect.jpg; late-join-pass.jpg |
| UC-SOLO-01: configuration precedence, malformed defense and AdminBridge authorization | PASS | conquest-victory-solo-config-admin-pass.jpg |
| UC-SOLO-02: actual mouse Conquer, commitment, Ready, capture and title qualification | PASS | conquest-victory-commitment.jpg; mouse-conquest-result.jpg; title-qualification.jpg |
| VIC-SOLO-01: actual mouse final conquest | PASS; final server ledger and ownership checked | conquest-victory-mouse-final-pass.jpg; solo-victory.jpg |
| VIC-UI-01: HD720 and VGA layout, text fits and panel bounds | PASS | conquest-victory-hd720.jpg; vga.jpg |
| VIC-UI-02: overlay blocks map click/zoom/drag; dismiss resumes zoom; Messages usable; Ready replay does not reopen | PASS | conquest-victory-vga-modal-pass.jpg; comms-ready-pass.jpg |
| UC-LOOT-01: Gold unchanged by neutral victory | PASS | viewport fixture, UC_VIC_VIEWPORT_NO_LOOT_PASS |
| UC-SOURCE-01: final disk/Studio equality and cleanup | PASS, 25 sources; recovery archives and GUI present, no runtime fixtures | conquest-victory-final-integrity-pass.jpg; final-integrity.txt |

All 65 gameplay Luau files compile with official Luau 0.740; this is syntax verification, not Roblox type checking. git diff --check passes. Earlier Communications production filtering/peer-delivery limitations remain unresolved; post-end checks verify that its UI and existing path stay available, not production transport acceptance. The final late-join spectator label was compiled and synced after multiplayer validation but its wording was not rerun in a new late-client session. No touch-device interaction, published-server/performance testing, full human match, balance acceptance or Director acceptance is claimed.

## Preservation and local delivery

Studio contains ServerStorage.ConquestVictoryRecovery_20261010.HierarchyPrototypeGui (pre-change GUI), CommunicationsRecoveryArchive and GuiSprintRecovery_20261009. The original recovered Communications files remain on disk. Final source equality was checked after the last gameplay edits.

A local offline place copy was saved using Download a Copy: docs/verification/conquest-victory-2026-10-10.rbxl (738,547 bytes). It includes current GUI/remotes/assets and source, remains ignored by Git, and was not published. The saved create-assets.txt and sync.txt commands document the Studio-only asset/source application. Studio is stopped in Edit mode; test ownership, results and probe attributes were runtime-only.

## Remaining Director playtests

Play a complete match and evaluate 300-defense/70%-threshold pacing, survivor persistence and competitive freeze. Check intended hierarchy authority and final root/subject/defeat messaging with human players. Regeneration, rewards, rematch and broader systems remain outside this implementation. Existing deferred Military and Communications scenarios retain their prior status.

## Requester-only Play Again — 2026-10-13

**IMPLEMENTED — AUTOMATICALLY CHECKED — TARGETED STUDIO TESTED — PUBLISHED ROUTING UNVERIFIED — NOT DIRECTOR-ACCEPTED.** Director explicitly chose a fresh reserved server for the requester, starting alone. This narrowly supersedes the earlier exclusion of replay; no lobby, queue, cohort transfer, rewards, persistence or shared reset was authorized.

### Coverage and route

Scoped inspection covered current MatchState/Victory/startup contracts, approved end-state rules, existing VictoryOverlay children and the installed utility's source. Kohl's retained Utility `rejoin` explicitly targets the current JobId and cannot provide a fresh match. Existing service/startup has no shared restart API; a new server runs normal initialization. Disk sources are intended code, not the entire place. Four affected modules were compared before guarded sync; exact original VictoryService/VictoryController clones remain inactive under ServerStorage.ReplayRecovery_20261013. No authored GUI overwrite or whole-place audit. Earlier admin/GUI/Prestige/rank/council work and recovery assets are preserved; task-baseline hashes show only the two existing Victory sources changed before documentation updates.

MatchReplayService uses server TeleportAsync to the current PlaceId with `ShouldReserveServer=true` and a one-player list. Each deliberate attempt creates new options; no old JobId, access-code reuse or public-server fallback. Roblox documents this as a new reserved destination; [teleport guide](https://create.roblox.com/docs/projects/teleport). Destination startup is the ordinary match lifecycle: resources/rank reset normally, no result/reward payload or lifecycle override. Starting alone is intentional; joining friends/matchmaking is outside this scope. Actual destination access and initialization remain unverified until a future authorized published test.

ReplayRequests owns actor-scoped request state. Ended/connected checks and the flight latch precede worker dispatch. Duplicate requests and Ready reads cannot create another transfer. API errors and correlated TeleportInitFailed release the request with readable retry feedback and a short cooldown; stale failures cannot unlock a newer attempt. No guessed timeout releases a transport that may still succeed. A delayed client Ready only resynchronizes status. Client revision checks reject stale status, including an initial Ready response during a local request. Only the requesting client receives routing feedback; clients cannot choose targets, destinations or reset shared state.

VictoryController extends the existing themed result panel with **Inspect final map** and **Play Again**, measured scrolling result/feedback text and persistent footer controls. Inspect and Match result reopening stay available during preparation/failure. Competitive freeze and final snapshot are unchanged; existing modal input blocking is retained. New controls use shared theme roles/settings. No other controller/system or Communications source changed.

### Current evidence

- **REPLAY-POLICY:** 39 pure synthetic assertions passed: premature/unavailable requests, requester isolation, duplicate queued/in-flight requests, Ready/status reads, cooldown, synchronous/asynchronous failures, stale callbacks, disconnect and reconnect. [Fixture](../docs/verification/replay-request-checks.luau.txt). Fake transport, not a Roblox departure test.
- **REPLAY-SOLO:** disposable actual server/client scripts; seeded ownership through normal Territory/Victory APIs reached Domination (not natural progression). Six server assertions passed for final snapshot, unchanged ruler/player, repeat Start and competitive ownership freeze; client verified live-state rejection. Native mouse Play Again returned readable Studio unavailability without leaving; Inspect dismissed and Match result reopened. [Server](../docs/verification/replay-server-checks.luau.txt), [client](../docs/verification/replay-client-checks.luau.txt), [receipts](../docs/verification/replay-runtime-2026-10-13.json).
- **REPLAY-UI:** real controller with explicitly synthetic pending/transport/failure statuses; pending button disabled, stale status ignored, inspection/reopening preserved pending, confirmed failure restored retry. Fourteen geometry cases / 286 cumulative client assertions (includes lifecycle/pending assertions), actual GUI sizes1279×662 and639×422, four supported fonts and1.1 scale settings. [Synthetic setup](../docs/verification/replay-synthetic-ui-server.luau.txt), [settings fixture](../docs/verification/replay-layout-server.luau.txt), [normal native unavailable](../docs/verification/replay-2026-10-13/normal-studio-unavailable.jpg), [compact synthetic failure](../docs/verification/replay-2026-10-13/compact-theme.jpg). Human usability, touch/gamepad and multi-client departure are not claimed.
- **REPLAY-SOURCE:** four production modules compile; fixture syntax checked; diff reviewed against task baseline; git diff --check passes. Post-stop read-only equality passed for all four Studio sources and recovery count2; disposable runtime scripts are absent. MatchReplayService/ReplayRequests are new server modules; existing VictoryService/Controller are the only production edits in this task. No admin/security/gameplay reset path introduced.

**Local-only:** docs/verification/replay-final-2026-10-13.rbxl saved in Edit mode,809808 bytes, SHA256 `32f89306d56644bae8ba6270ccb07b6c3d0d2ea3d4a9c5f3c257611f666d8194`; Git ignore confirmed. Contains current local place, affected sources and inactive originals; source equality is not full property/cloud/publication parity. Prior snapshots retained. No commit, push or Roblox save/publication.

**REPLAY-PROD — NOT TESTABLE IN CURRENT ENVIRONMENT:** Roblox TeleportService is unsupported in Studio; [official guide](https://create.roblox.com/docs/projects/teleport). No publication authorized. Next: after separately authorized publication, use Roblox clients to verify distinct new reserved JobId, requester-only arrival, normal fresh startup, others retaining the original final match, repeated-click isolation, destination access and real synchronous/TeleportInitFailed retry. Current tests do not establish platform success. **REPLAY-UX — DIRECTOR VERIFICATION REQUIRED:** assess result/feedback readability and deliberate departure wording. These are verification gaps, not current passes or Director acceptance.

### Player walkthrough

Finish a match. Inspect final map to dismiss the result; reopen with Match result whenever desired. Choose Play Again to request a new reserved match starting with you alone; others stay in the finished server. While waiting, inspection remains available and the request button is disabled. A confirmed failure leaves you here with readable feedback; retry after the short cooldown. Studio reports that published Roblox is required and does not teleport.
