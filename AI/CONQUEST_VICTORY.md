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
