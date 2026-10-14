# V0.5 Playtest Verification Backlog

## Province building markers — 2026-10-14

[Evidence](BUILDINGS_BALANCE_PROPOSAL.md#province-building-markers--2026-10-14).

| Scenario | Agent evidence | Remaining status |
| --- | --- | --- |
| BUILDING-MARKER-UX | Normal/compact and drawer views, native marker select/pan, hover/damage/ruin; compact small slots simplify | DIRECTOR VERIFICATION REQUIRED — silhouette recognition/colors/compact hover readability; touch has no hover. |
| BUILDING-MARKER-MULTI | One actual client, authoritative synthetic purchases/Repair/relocation/ruin/reset; synthetic cosmetic front/transport coexistence | DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG: multiple real clients receiving simultaneous capture/relocation/restart; not a current pass. |

## Final building stage — 2026-10-14

[Evidence](BUILDINGS_BALANCE_PROPOSAL.md#final-building-stage--capital-damagerepair-and-elimination--2026-10-14).

| Scenario | Agent evidence | Remaining status |
| --- | --- | --- |
| CAPITAL-UX | Native Build/Repair/relocate/upgrade/Max, normal/compact UI | DIRECTOR VERIFICATION REQUIRED — pacing/readability. |
| CAPITAL-MULTI | Solo client plus synthetic server actors; actual combat capture/retirement/reset and client stale guards | DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG: real concurrent/crossed Capitals, nested/autonomous capture and naval landing delivery. |
| CAPITAL-REJOIN | UserId tombstone gate and reset lifecycle verified in source/server fixtures | NOT TESTABLE IN CURRENT ENVIRONMENT — same published real account reconnect; no actual reconnect pass. |


## Town/Castle stage two — 2026-10-14

Evidence: [stage-two report](BUILDINGS_BALANCE_PROPOSAL.md#stage-two--towns-and-castles-implemented--2026-10-14).

| Scenario | Current evidence | Remaining status / next step |
| --- | --- | --- |
| BUILD-TC-UX | Native Solo purchases/recruitment, normal/compact rows, Max and over-cap screenshots | DIRECTOR VERIFICATION REQUIRED — readability and500-start early-conquest pacing. |
| BUILD-TC-MULTI | Synthetic simultaneous backing/cancellation/zero defense/casualty conservation; one actual client request guards | DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG: actual multi-client naval arrival, nested betrayal Castle and disconnect delivery. No current multi-client pass claimed. |
| BUILD-TC-NET | Correlated duplicate/stale/invalid requests checked in Solo | NOT TESTABLE IN CURRENT ENVIRONMENT — published accounts/network timing. |


## Prestige and map-scaled titles — 2026-10-13

Evidence: [implementation report](OPENFRONT_PLAYABILITY_REVIEW.md#prestige-earning-and-map-scaled-titles--2026-10-13). Design approved; implementation/balance acceptance separate.

| Scenario | Agent evidence | Remaining status / next check |
| --- | --- | --- |
| PRESTIGE-SYNC-01 | Current saved-place decode: eleven sources match disk, decimal formatting included; fixtures disabled under recovery | AGENT-VERIFIED — scoped snapshot correspondence only. Fractional-override visual runtime DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG; pure override validation/compile verified, default Vale output unchanged. |
| PRESTIGE-PACE-01 | Native ordinary Solo Duke/King/Emperor; theoretical rapid victory before higher titles | DIRECTOR VERIFICATION REQUIRED — human multiplayer pacing/land-loss/subject flow; decide balance from observed matches, not agent inspection delays. |
| PRESTIGE-UI-01 | Normal/compact140 layout assertions,4 fonts/settings extremes, screenshots | DIRECTOR VERIFICATION REQUIRED — judge explanation, personal/subtree distinction and preferred display settings. |
| PRESTIGE-REJOIN-01 | Pure same-ID new lifetime reset and actual Local Server disconnect cleanup | NOT TESTABLE IN CURRENT ENVIRONMENT — same real identity disconnect/rejoin and published peers; verify fresh Lord/zero/new allocation without restored/offline Prestige. |
| PRESTIGE-TOUCH-01 | Desktop layout/input only | DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG; separate authorized touch work, not a touch pass. |

## Province decision clarity — 2026-10-11

Evidence: [CONTEXTUAL_MAP_INTERACTION.md](CONTEXTUAL_MAP_INTERACTION.md#province-decision-clarity-milestone--2026-10-11). Agent results do not imply novice usability or Director acceptance.

| Scenario | Agent evidence | Remaining status / concrete next check |
| --- | --- | --- |
| PROV-POL-01 | 24 pure production-module assertions: authored corners, root/subject, treaties, cooldown, private-conflict filtering, configured count/recount | DIRECTOR VERIFICATION REQUIRED — judge whether cues/reasons explain a real decision |
| PROV-MP-01 | Three actual clients: player reservations/locks/privacy/result, hierarchy progress, cooldown and end freeze/final inspection | DIRECTOR VERIFICATION REQUIRED — ordinary-account desktop match; published-account/latency behavior unverified |
| PROV-UI-01 | Mouse conquest 500 vs 300; accepted/held/released figures and 2/12 progress; native result focus and radial pass-through | DIRECTOR VERIFICATION REQUIRED — walkthrough from selection through result |
| PROV-UI-02 | VGA/HD720 default settings: captions fit, drawer separation and controls scroll reachable; mouse pan/zoom/Recenter | DIRECTOR VERIFICATION REQUIRED — preferred font/UI scales, long ruler names, dense simultaneous edge markers |
| PROV-TOUCH-01 | No touch gesture implementation/test in desktop milestone | DEFERRED — separate authorized touch milestone; mouse layout is not touch navigation evidence |
| PROV-COM-01 | Existing event presentation extended; native transport unchanged | NOT TESTABLE IN CURRENT ENVIRONMENT — published peer delivery/filtering/privacy needs real accounts |

## GUI redundancy cleanup — 2026-10-10

Evidence: AI/GUI_REDUNDANCY_CLEANUP.md. Agent passes do not grant Director acceptance.

| Scenario | Agent evidence | Remaining playtest status |
| --- | --- | --- |
| GUI-CLN-01 | Retired surfaces/nav/templates absent; final Studio audit archives 20 objects; 77 disk sources match | DEFERRED — Director acceptance |
| GUI-CLN-02 | Back/click-away, no click-through, pan/zoom, global-detail persistence and rapid transitions passed | DEFERRED — human interaction feel |
| GUI-CLN-03 | VGA/HD720/wide at 0.9/1/1.1: bounds, heading/action separation, review/Military scroll and opacity settings passed | DEFERRED — Director readability at preferred settings |
| GUI-CLN-MP-01 | Three actual clients: 65 cumulative assertions; accepted offers, Alliance/NAP, war participation, resolution and disconnect cleanup passed | DEFERRED — real-account match usability |
| GUI-CLN-MP-02 | Authoritative Domination: both remaining clients clear context, show result, allow final-map/Players inspection | DEFERRED — Director result usability |
| GUI-CLN-04 | Native conquest rejects fractional input, accepts 500 troops, locks and resolves into result | DEFERRED — human usability/balance; gameplay unchanged |
| GUI-CLN-COM-01 | Global Messages navigation remains; native account privacy/filtering was not rerun in this cleanup | DEFERRED — existing real-account verification |

## Contextual map milestone — 2026-10-10

Agent evidence is recorded in `AI/CONTEXTUAL_MAP_INTERACTION.md`; none of these entries grants Director acceptance.

| Scenario | Agent evidence | Remaining playtest status |
| --- | --- | --- |
| CTX-POL-01 | 31 pure resolver/anchor/aggregation assertions passed, including same-root personal-border Direct cases | DEFERRED — human acceptance |
| CTX-MP-01 | Three actual Local Server clients: offers, hierarchy, Alliance/NAP, local war relevance, resolution and disconnect cleanup passed | DEFERRED — real-account match usability |
| CTX-MP-02 | Synthetic successful communication receipts: aggregation, Council/Allies marker routing and acknowledgement passed | DEFERRED — native real-account delivery/filtering/privacy; synthetic receipts are not native transport verification |
| CTX-UI-01 | Solo review/cancel/confirm/500-troop handoff/result routing and empty-map dismissal passed | DEFERRED — Director discoverability and game-feel acceptance |
| CTX-UI-02 | VGA, HD720 and wide profiles at min/default/max scale; review scrolling and marker pan/zoom passed | DEFERRED — human readability/attention-density assessment |

Canonical list of tests classified **DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG**.

**Deferred does not mean PASS. Deferred means non-blocking until the appropriate testing stage.**

Standing verification/defer policy: [AGENTS.md](../AGENTS.md#verification-and-acceptance). This document owns scenario status/evidence, not a duplicate operating policy.

**Communications V0.x** is **PRE-V0.5 REQUIRED — IMPLEMENTED — PARTIALLY AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED**. Native real-account peer filtering/privacy and observer verification remain outstanding; see the Communications rows below and `AI/COMMUNICATIONS_IMPLEMENTATION.md`.

## How to use (including player bug reports)

1. Identify the system (Military, Warfare, Hierarchy, …).
2. Find the matching scenario below (or add a new row if the report is a new deferred class).
3. Compare: documented expected behavior ↔ Agent evidence ↔ player observation.
4. If the observation **contradicts** expected behavior or shows integrity/security risk, it is **no longer deferred** — treat as a blocking defect.

Status values for rows: **DEFERRED**; **VALIDATED** (playtest matched expected); **CONTRADICTED** (playtest disagreed — investigate); **PROMOTED-BLOCKING**.

---

## Military / Armies V0.1

System status: **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope). Eighteen ordinary Director PASSes are in `AI/PROGRESS.md`. Do not re-ask those PASSes. Ordinary remaining Director checks: **none**. The eight rows below that are still **DEFERRED** are overlay/race cases — **deferred ≠ PASS**; they do **not** block V0.x development. If later testing shows Troop duplication, dropped outcomes, double resolution, stuck CONTESTED, or equivalent authoritative corruption, treat it as a real defect (promote-blocking). Warfare V0.1 **Director-PASS** already covers generic participating-root disconnect and loss-of-independence **war cancellation without conquest**; the remaining deferred rows are the **Military overlay** (Troops, commitments, presentation) and two-human timing.

### MIL-MP-01 — Attacker disconnect before mechanical resolution

- **Scenario:** Attacking root leaves during unlocked or locked-but-not-dual-locked commitment.
- **Expected:** War cancels; no conquest; attacker Troops destroyed with ruler (like Gold); defender’s committed Troops unwind to Available with **zero** casualties; no duplicate/ghost commitment.
- **Status:** DEFERRED
- **Why deferred:** Needs a real second client disconnecting mid-war; not required to block V0.1 after Agent cancel/unwind paths.
- **Agent evidence:** Pre-mechanical cancel/unwind and `resolvewar` unwind restored Available with `ledgerOk`; Warfare disconnect cancel is Director-PASS for lifecycle.
- **Playtester:** After attacker leaves, defender should see war cancelled, keep land, keep their Troops (minus any unrelated losses). No stuck “Committed” on a dead war.
- **Notes:** Distinguish Troop **wipe of the leaving ruler** from **unwind of the survivor**.
- **Priority:** High (state integrity) — still non-blocking unless a concrete leak/duplication is found.
- **Playtest feedback:** —

### MIL-MP-02 — Defender disconnect before mechanical resolution

- **Scenario:** Defending root leaves during commitment, before dual-lock mechanical resolution.
- **Expected:** Same as MIL-MP-01 with roles swapped: war cancels; no conquest; defender pool gone with the ruler; attacker commitment unwinds, zero casualties.
- **Status:** DEFERRED
- **Why deferred:** Two-client disconnect timing.
- **Agent evidence:** Same unwind/cancel machinery as MIL-MP-01; Warfare defender-disconnect Director-PASS for no-conquest cancel.
- **Playtester:** Attacker should not receive the territory; commitment should clear; Total/Available should match after cancel.
- **Notes:** —
- **Priority:** High (integrity) / non-blocking until a defect is shown.
- **Playtest feedback:** —

### MIL-MP-03 — Disconnect during 5s presentation (after mechanical resolution)

- **Scenario:** Either root disconnects after dual-lock battle is calculated, during presentation.
- **Expected:** Battle already **mechanically final**. Presentation may abort for the leaver. Survivor should still receive the calculated casualties/outcome path (or documented cancel-if-explicitly-specified — current contract: mechanical result stands; Warfare applies after presentation). Confirm no second battle, no `resolvewar` overwrite, no Troop duplication.
- **Status:** DEFERRED
- **Why deferred:** Race between presentation timer, `ApplyMilitaryOutcome`, and `RulerRemoving`.
- **Agent evidence:** Dual-lock calculates immediately; `resolvewar` rejected post-mechanical; presentation is display-only. Disconnect-during-presentation not exercised with two humans.
- **Playtester:** Note whether land transfers (attacker win) or not; whether survivor Troops match the battle result toast; whether a stale war remains.
- **Notes:** If playtest shows outcome discarded or double-applied, **PROMOTE-BLOCKING**.
- **Priority:** High (integrity race) / non-blocking until observed.
- **Playtest feedback:** —

### MIL-MP-04 — Loss of independence during unlocked commitment

- **Scenario:** A war root becomes a vassal (or otherwise loses independence) while commitment is still open.
- **Expected:** War terminates; new liege does **not** inherit the war or the subject’s Troops; surviving independent opponent unwinds commitment with zero casualties.
- **Status:** DEFERRED
- **Why deferred:** Needs live vassalage during an active Military engagement.
- **Agent evidence:** Warfare loss-of-independence Director-PASS (war ends, no liege inheritance). Military troop unwind on cancel Agent-verified via debug, not via live independence change mid-commit.
- **Playtester:** “I swore vassalage mid-war” / “I accepted someone who was at war” — war gone; Troops not merged into liege.
- **Notes:** Lookup for reports that a liege suddenly owns a war or Troops.
- **Priority:** Medium–High / non-blocking.
- **Playtest feedback:** —

### MIL-MP-05 — Loss of independence after mechanical resolution / during presentation

- **Scenario:** Root loses independence after battle is calculated.
- **Expected:** Mechanical result is already final; confirm presentation vs hierarchy-cancel interaction does not double-resolve, wipe the wrong pool, or leave CONTESTED forever.
- **Status:** DEFERRED
- **Why deferred:** Same class as MIL-MP-03 plus hierarchy change.
- **Agent evidence:** Independence-cancel and post-mechanical reject paths exist separately; combination not two-client tested.
- **Playtester:** Who owns the target; whether anyone still has a commitment; whether the new liege is in the war (must not be).
- **Notes:** Promote if outcome/Troop ledger corrupts.
- **Priority:** High (integrity race) / non-blocking until observed.
- **Playtest feedback:** —

### MIL-MP-06 — Hidden commitment privacy (two human clients)

- **Scenario:** Two real players in one war; one Ready, the other still deciding.
- **Expected:** Unlocked side sees “Opponent preparing forces” (no lock/amount leak). After own lock: “Waiting for opponent” still no enemy amount. After both lock: simultaneous fielded counts only — not Total/Available, not rolls.
- **Status:** VALIDATED (pre-battle / mid-decision secrecy)
- **Why deferred:** — Director 2026-08-24: Player1 locked 237; Player2 saw only own “Accepted commitment: none”, timer, “Opponent preparing forces”; did **not** see 237. Ordinary UI secrecy for the unlocked opponent is Director PASS.
- **Agent evidence:** Ordinary State/Notices omit opponent intended/lock while unlocked; `InspectWar` (admin) shows both; third parties get public war/map outcome only.
- **Playtester:** Compare both screens before dual-lock. Report if you can infer the enemy lock or amount from ordinary UI.
- **Notes:** Simultaneous **post-dual-lock** reveal timing remains **MIL-MP-07**. Admin/debug HUD is exempt.
- **Priority:** Medium (privacy / feel).
- **Playtest feedback:** DIRECTOR PASS 2026-08-24 (locked 237 hidden from opponent).

### MIL-MP-07 — Simultaneous reveal timing (two human clients)

- **Scenario:** Both players Ready (or auto-lock) close together; both should see fielded amounts and battle presentation at the same mechanical moment.
- **Expected:** No client shows the enemy commitment **before** both are locked. Both then see the same fielded pair. 5s banner for participants.
- **Status:** DEFERRED
- **Why deferred:** Needs two clocks/eyes; Agent dual-Ready was same-process debug locks.
- **Agent evidence:** Server reveals only after both locked; mechanical calc then presentation; one-client banner/`phase == present`.
- **Playtester:** Did one client flash the enemy number early? Did banners start together?
- **Notes:** —
- **Priority:** Medium.
- **Playtest feedback:** —

### MIL-MP-08 — Multiple wars on different territories (natural multiplayer)

- **Scenario:** A player (or two pairs) fights more than one **different**-territory war at once.
- **Expected:** Allowed. Strict Available accounting; overcommit rejected; same territory still single-contest.
- **Status:** VALIDATED
- **Why deferred:** —
- **Agent evidence:** Same-target second declaration rejected; different-target wars allowed by contract; ledger `available + committed = total` on inspected wars.
- **Playtester:** Can you start a second war on another border while the first is committing? Does Available drop correctly?
- **Notes:** Do not confuse with superseded same-target multiplicity (forbidden). Director also PASS selected-territory context and duplicate same-target contest.
- **Priority:** Medium.
- **Playtest feedback:** DIRECTOR PASS 2026-08-24 (1000 Troops; first commitment reduced Available; second war used remainder only; no dual-use).

### MIL-MP-09 — Multi-ruler overextension

- **Scenario:** Several players stretch Troops across wars; someone tries to commit more than Available.
- **Expected:** Server rejects overcommit; last accepted intent unchanged; no shared realm pool; Alliance does not contribute.
- **Status:** VALIDATED (ordinary over-Available / multi-war accounting; not every chaotic multi-ruler table)
- **Why deferred:** —
- **Agent evidence:** SetCommit over Available rejected; personal pools; RecruitMax/recruit add Available only.
- **Playtester:** “I couldn’t commit 2000 with 400 Available” should hold under chaos, not only in a clean test.
- **Notes:** Director also accepted last-valid-intermediate TextBox auto-submit as-is for V0.1.
- **Priority:** Medium.
- **Playtest feedback:** DIRECTOR PASS 2026-08-24 (over-Available rejected; multi-war Available split; illegal amount not accepted).

### MIL-MP-10 — Root-only commitment when the target is subject-owned

- **Scenario:** War for a **territory** held by a vassal; commitment UI/prompt on attacker and **defender root**, not the subject holder.
- **Expected:** Subject is not the commitment actor. Liege (defender root) commits personal Troops. Subject should not receive the Military commit prompt as if they were the war root.
- **Status:** DEFERRED
- **Why deferred:** Needs human liege + human vassal + human attacker. Lookup for “the military prompt went to the wrong person.”
- **Agent evidence:** Contract and implementation restrict commit/lock to the two war roots; mock-root wars used in Agent tests, not a three-human subject-land war.
- **Playtester:** Who saw Ready/commit? Did the vassal landholder get a false “you must commit” UI?
- **Notes:** Ordinary subject TerritoryInfo may still show the war as realm-relevant; that is not the same as being the commitment actor.
- **Priority:** Medium (UX / authority confusion).
- **Playtest feedback:** —

### MIL-MP-11 — Two-client Ready vs 40s/55s timers and RecruitMax/lock races

- **Scenario:** One player Ready early, the other AFK; emergency **M** recruit then commit; last-millisecond SetCommit vs auto-lock.
- **Expected:** Dual Ready still instant; interacted auto-lock at 40s; nonresponsive attacker cancel / defender 0 at 55s; M never changes a **locked** commitment; no double Gold spend.
- **Status:** DEFERRED (partial Director coverage)
- **Why deferred:** Last-millisecond SetCommit vs auto-lock and RecruitMax spam races still not Director-tested as two-human races.
- **Agent evidence:** Timer config 40/55; auto-lock interacted; AFK attacker cancel; defender 0 unopposed; RecruitMax lock-safe; rapid M no overspend.
- **Playtester:** Feel of 40s thinking vs 55s AFK; any lock of a stale local textbox; any Gold/Troop duplication on spam M.
- **Notes:** **DIRECTOR PASS 2026-08-24** for AFK opponent → 0 into battle. **DIRECTOR PASS** recruit-after-lock. **DIRECTOR PASS** never-interacted attacker 55s cancel (ordinary acceptance; not this row). Remaining on this row: last-millisecond SetCommit vs auto-lock and RecruitMax spam races. Pacing principle: pressure indecision, not normal thinking.
- **Priority:** Medium (feel + last-second races).
- **Playtest feedback:** Timeout/AFK defender-0 path PASS; recruit-after-lock PASS; never-interacted attacker 55s cancel PASS (ordinary). Last-ms / RecruitMax races still deferred.

---

## Intentionally not listed

- Warfare V0.1 Director-PASS disconnect / loss-of-independence **lifecycle** (no conquest, no liege inheritance, no stale war) — already accepted; only Military overlays above are deferred.
- Agent-verified arithmetic (casualty bands, 1 Gold = 3 Troops, RecruitMax Gold×3, ledger identity) unless a **multiplayer** remainder exists.
- Cases the Director has already marked PASS for the same behavior (see `AI/PROGRESS.md` Military 2026-08-24 PASS list, 18 items). Do not re-ask: attacker 0 cancel, never-interacted attacker 55s cancel, defender-0 unopposed, commitment editing, recruit-after-lock, timeout/AFK defender-0, cooldown / live cooldown UI, casualty ledger, multi-war overextension, selected-territory war context, contextual Last Battle, duplicate contested territory, defender/attacker victory ownership, pre-battle enemy commitment secrecy.


## Communications V0.x replacement — 2026-10-09

Agent verification is not Director acceptance. Existing MIL rows are unchanged. Detailed actual results and evidence: AI/COMMUNICATIONS_IMPLEMENTATION.md.

### COM-MP-01 — Real-account native peer delivery and privacy

- **Status:** NOT VERIFIED; environment-limited.
- **Performed:** three synthetic Local Server clients; political distance/Council/Allies/Direct authority checks, native sender receipts and denied stale Council send. Synthetic CanUsersChatAsync returned false; peer native Success absent, correctly no custom rendering.
- **Remaining:** consenting real-account multi-client session, all four paths, permitted and blocked account/privacy combinations, platform filtering. No production privacy/filtering pass claimed.
- **Priority:** High before Communications acceptance.

### COM-MP-02 — Observer and ordinary membership lifecycle

- **Status:** PARTIAL AGENT VERIFICATION; remaining manual cases unverified.
- **Performed:** three Studio testers; distinct ordinary membership vs read-only tester sources, neutral context/title labels, Alliance break and border-loss political rejection before sync, Council/Direct ruler-removal rejection and settled cleanup. All synthetic clients are tester observers, so retained read-only sources are expected.
- **Remaining:** non-admin native source destruction, actual disconnect/rejoin, fealty break/root transitions under queued sends; real-account authorized observer receipts, Direct platform restrictions and local mute while ordinary peers continue.
- **Priority:** High before acceptance.

### COM-DESIGN-01 — Direct personal-territory adjacency clarification

- **Status:** DIRECTOR RULE RESOLVED; AGENT-VERIFIED implementation, not Director acceptance.
- **Ruling:** adjacency between personally/directly owned territories of two different rulers. Same root or political relationship alone grants nothing; no root-graph Direct check.
- **Performed:** three clients; same-root touching liege/subject allowed, same-root non-touching denied while Council works; coexistence; border loss/restoration before sync; roots adjacent only through subject holdings do not qualify; outsiders/self/malformed/landless rejected. Injected-snapshot policy checks cover fellow subjects/Allies/enemy/NAP/unrelated. 26/26 targeted checks passed; evidence communications-direct-clarification-results.json.
- **Remaining:** real-account native end-to-end and Director acceptance remain covered by COM-MP-01/02, not an unresolved design question.

### COM-UI-01 — Full presentation and sustained-load check

- **Status:** PARTIAL AGENT VERIFICATION.
- **Performed:** 1280x924 Local Server and 1150x936 Play Solo; exact help, wrapped native long message, measured scroll canvas, confirmed input clear, existing shell geometry and pointer block observed.
- **Remaining:** chosen smaller supported viewport/long names, many conversations, unread/context switches under peer receipts, match-scoped ended-context retention/load.
- **Priority:** Medium; no stress or Director acceptance claim.

## GUI / UX sprint visual follow-up — 2026-10-09

- **UX-DIR-01 — DIRECTOR VISUAL APPROVAL REQUIRED:** evaluate map-first navigation, slate/gold palette, province names, drawer widths, priority offer prominence and battle/readiness presentation. Agent evidence in `GUI_UX_SPRINT.md`.
- **UX-MP-01 — DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG:** many/long ruler names, large lists, multiple offers within one category and extended real-player multiplayer UX. Deferred is not PASS.
- **UX-COM-01 — NOT TESTABLE IN CURRENT ENVIRONMENT:** native peer filtering/privacy with production accounts; negative Studio test UserIds are ineligible. Solo native sender Success verified. Existing Communications acceptance requirements remain.

## Realm Overview visual follow-up — 2026-10-10

- **ROV-DIR-01 — DIRECTOR VISUAL APPROVAL REQUIRED:** evaluate sustained physical hold-Tab feel, typography, political details and return to prior drawer. Solo/three-client matrix in REALM_OVERVIEW.md is agent verification.
- **ROV-LOAD-01 — NOT TESTED:** 50 real connected players / prolonged network load. A 50-row projection and scrolling GUI diagnostic passed; this does not establish 50-client behavior.
- **ROV-TOUCH-01 — NOT TESTED:** physical touch/mobile navigation and list interaction. Players entry point implemented; optional gamepad bindings omitted.

## Unclaimed conquest / Domination — 2026-10-10

These rows record Agent verification separately from Director playtesting. Detailed scenario IDs and evidence are in [CONQUEST_VICTORY.md](CONQUEST_VICTORY.md). Existing deferred rows are unchanged.

| Scenarios | Agent evidence | Director status |
| --- | --- | --- |
| UC-MP-01 through UC-MP-04: militia, rejected requests, locks/cooldown, survivors, stale ownership, disconnects and subject-border root authority | PASS in actual three-client Local Server | Pending |
| VIC-MP-01 through VIC-MP-05: threshold, outcomes, pending battle freeze, fealty/independence, winner disconnect and late join | PASS in actual multiplayer sessions | Pending |
| UC-SOLO-01/02, VIC-SOLO-01: setup authorization and normal mouse conquest/title/victory flow | PASS | Pending |
| VIC-UI-01/02: HD720/VGA bounds, modal input block and post-end inspection | PASS | Pending |
| UC-BAL-01: complete human match, 300 militia and 70% pacing | Not tested; deferred to human playtest | DEFERRED |
| VIC-PROD-01: published server, touch interaction and larger-player performance | Not tested | DEFERRED |

No deferred scenario is a pass or Director acceptance. Neutral regeneration is deferred implementation, not a failed or passed test. Communications production transport/filtering acceptance remains governed by its existing backlog.

## Creator presentation settings — 2026-10-10

Agent results are recorded in AI/GAME_PRESENTATION_SETTINGS.md. They do not imply Director acceptance.

| Scenario | Status | Remaining verification |
| --- | --- | --- |
| PRES-01 | DIRECTOR VERIFICATION REQUIRED | Judge game font hierarchy, readable density and audio feel with native GAME UI/GAME AUDIO controls. |
| PRES-02 | NOT TESTABLE IN CURRENT ENVIRONMENT | Published ordinary-account category hiding/remote denial and group-experience creator resolution; Studio uses synthetic tester IDs and an owner account. Server/mock/real remote checks already passed. |
| PRES-03 | NOT TESTABLE IN CURRENT ENVIRONMENT | Kohl personal saved-appearance backend with Studio API services disabled. No game values use that backend; global game persistence remains future work. |

## Playable match / GUI consistency — 2026-10-13

Current agent evidence in [GUI_UX_SPRINT.md](GUI_UX_SPRINT.md#playable-match--gui-consistency-milestone--2026-10-13) supersedes no historical acceptance. Natural Solo loop and separate three-client regression passed; this does not establish a human competitive match.

- **LOOP-DIR-01 — DIRECTOR VERIFICATION REQUIRED:** ordinary human multiplayer join/orientation, conquest/defense, earned recruitment, diplomacy/fealty, natural end and final inspection; assess pacing without agent inspection pauses. Next: follow report walkthrough with real players.
- **GUI-DIR-13 — DIRECTOR VERIFICATION REQUIRED:** normal/compact typography, scroll reach, primary/secondary/error/offer/result distinctions and audio/animation feel with creator settings. Current agent geometry/settings/native checks passed; human usability remains untested.
- **PRESTIGE-DESIGN-01 — UNRESOLVED DESIGN / NOT IMPLEMENTED:** decide ordinary earning sources, formula, caps/pacing and abuse safeguards. Existing thresholds enforced; Domination success is not natural title progression. No fixture grants imply completion.
- **GUI-PROD-13 — NOT TESTABLE IN CURRENT ENVIRONMENT:** physical touch and published-account communications/filtering/personal saved-settings behavior. Retain existing production/load backlog; no deferred case is PASS.

## Rank/commitment follow-up — 2026-10-13

- RANK-COMMIT-UX — **DIRECTOR VERIFICATION REQUIRED:** normal/compact readability, five-stop click/drag and accepted-versus-preview wording. Agent evidence in GUI_UX_SPRINT; no novice usability claim.
- RANK-COMMIT-NET — **NOT TESTABLE IN CURRENT ENVIRONMENT:** real-account delayed/rejected/queued commit delivery. Pure edit-state policy and Solo rejection/retry passed; this is not multiplayer latency acceptance.

## Political council foundation follow-up — 2026-10-13

- COUNCIL-UX — **DIRECTOR VERIFICATION REQUIRED:** compact/normal Realm readability, membership interpretation and no-permission/chat distinction. [Evidence](OPENFRONT_PLAYABILITY_REVIEW.md#political-authority-and-council-foundation--2026-10-13-implementation).
- COUNCIL-SIX — **DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG:** six-plus connected direct subjects exercising live-service timed replacement and multiple challengers. Pure synthetic policy and real30-second synthetic server policy passed; not a live six-player service pass.
- COUNCIL-NET — **NOT TESTABLE IN CURRENT ENVIRONMENT:** published-account network conditions; three Studio clients verified delivery scopes. Touch/gamepad not verified.

## Repeat-play follow-up — 2026-10-13

- **REPLAY-PROD — NOT TESTABLE IN CURRENT ENVIRONMENT:** TeleportService cannot transfer in Studio; no publication authorized. Next after separately authorized publication: distinct fresh reserved JobId/requester alone, normal startup/resource lifecycle, other players preserving ended server, duplicate protection and real API/init-failure retry. Pure fake transport and seeded Solo are not routing passes.
- **REPLAY-UX — DIRECTOR VERIFICATION REQUIRED:** normal/compact result wording, inspection/reopening while waiting and readable retry feedback. Agent themed geometry/native inspection checks passed; no human usability acceptance. [Evidence](CONQUEST_VICTORY.md#requester-only-play-again--2026-10-13).

## Recruitment follow-up — 2026-10-13

- **RECRUIT-UX — DIRECTOR VERIFICATION REQUIRED:** affordable-percent meaning, preview/action distinction and compact scroll readability. Agent native input and geometry checks passed; no human acceptance.
- **RECRUIT-NET — NOT TESTABLE IN CURRENT ENVIRONMENT:** published-account latency/disconnect timing and physical touch/gamepad. Current duplicate receipts and synthetic stale-Gold rejection are not a real network pass. [Evidence](GUI_UX_SPRINT.md#fixed-stop-affordable-recruitment--2026-10-13).


## Political permissions/autonomy/betrayal follow-up — 2026-10-13

- **POLITICS-UX — DIRECTOR VERIFICATION REQUIRED:** ordinary two-player grants/revokes, blocked reasons, autonomy without scores, explicit transfer and compact scrolling. [Agent evidence](OPENFRONT_PLAYABILITY_REVIEW.md#liege-permissions-autonomy-and-betrayal--2026-10-13), not human acceptance.
- **POLITICS-NET — NOT TESTABLE IN CURRENT ENVIRONMENT:** published latency/disconnect/hostile delivery scheduling and physical touch/gamepad. Next: separately authorized real-account stale/duplicate review, direct-edge transitions and final inspection. Core remote denials/transactions/same-turn invalidation passed focused Studio/fixtures; not published-network evidence.


## Vassalage combat follow-up — 2026-10-13

- **VASSAL-COMBAT-UX — DIRECTOR VERIFICATION REQUIRED:** own bonus wording/compact scrolling and uncapped balance; no human acceptance claimed.
- **VASSAL-COMBAT-NET — DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG:** focused real-player offense/defense/result delivery under latency. Core mechanical integration, actual troop ledgers and private actor projection verified in one actual Solo client with synthetic hierarchy. Next: two-player combat, direct/subject-owned targets and own-only result modifier. [Evidence](OPENFRONT_PLAYABILITY_REVIEW.md#vassalage-combat-bonuses--2026-10-13).


## Vale coastal/naval follow-up — 2026-10-13

- **VALE-COAST-UX — DIRECTOR VERIFICATION REQUIRED:** human neck/coast readability, personal departure selection, transport-marker visibility and cosmetic versus authoritative ownership. Agent native/geometry evidence does not imply acceptance.
- **VALE-NAVAL-NET — NOT TESTABLE IN CURRENT ENVIRONMENT:** published accounts/latency and physical touch/gamepad; actual three-client Studio authority/privacy/cancellation and disposable disconnect passed. Next: separately authorized published two-player departure/arrival/cancellation and final-map inspection. [Evidence](CONQUEST_VICTORY.md#vale-coastlands-naval-transport-and-conquest-fronts--2026-10-13).
## Vale32 / shared restart / staff routing — 2026-10-13

Current [evidence](CONQUEST_VICTORY.md#vale32-automatic-naval-and-shared-restart--2026-10-13) supersedes requester-only reserved replay as the active design, not its historical verification record.

- **VALE32-UX — DIRECTOR VERIFICATION REQUIRED:** geography, coastal targeting, result fronts and shared-vote clarity at normal/compact desktop sizes; assess actual pacing/readability.
- **RESTART-LATE — DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG:** confirm one actual late spectator arrives during final inspection, receives final state, votes and participates in reset. Attempt did not confirm arrival; pure join/threshold checks passed. Two actual shared resets and disconnect-triggered reset passed.
- **STAFF-ROUTING — NOT TESTABLE IN CURRENT ENVIRONMENT:** published MemoryStore expiry/discovery and authorized/unauthorized public/private/reserved joining, failures/retry. Studio trusted-role/policy checks passed; no published API/teleport pass claimed. Requires deployed configuration and registered reserved credentials where applicable.
- **VALE32-VISUAL-EDGES — DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG:** targeted revised pooled-front repulsion/disabled-animation runtime and reset-failure feedback injection; compiled/static checks are not runtime passes. Next: one bounded affected-branch fixture, without full-match rerun.
## Farm stage one — 2026-10-14

- **FARM-UX — DIRECTOR VERIFICATION REQUIRED:** normal/compact Build/Upgrade/Max readability, disabled reasons and low-income pacing. Agent native walkthrough and Solo synthetic authority checks passed; [current evidence](BUILDINGS_BALANCE_PROPOSAL.md#farm-stage-one--2026-10-14-implementation), not human acceptance.
- **FARM-NET — NOT TESTABLE IN CURRENT ENVIRONMENT:** published-account latency/disconnect/reconnect and touch. Farm retention follows unchanged unclaim lifecycle; actual disconnect/multi-client Farm receipt delivery was not exercised here. Next: real owner leaves developed land, another owner receives intact Farm income, retry/stale purchase rejects without charges. No full-match rerun needed.
