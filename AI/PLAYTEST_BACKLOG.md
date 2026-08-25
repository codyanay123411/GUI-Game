# V0.5 Playtest Verification Backlog

Canonical list of tests classified **DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG**.

**Deferred does not mean PASS. Deferred means non-blocking until the appropriate testing stage.**

Standing rule: `.cursor/rules/project.mdc` rule 29. Do not mark Director-verified or Director-accepted from Agent-only tests. Do not rewrite “not tested” into “verified.”

**Communications V0.x** is **not** listed here. It is **PRE-V0.5 REQUIRED — DESIGN FREEZE IN PROGRESS — NOT IMPLEMENTED** (`AI/GAME_DESIGN.md`). Design freeze is not PASS and is not an implementation acceptance.

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
