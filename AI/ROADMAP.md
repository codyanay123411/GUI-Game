# Roadmap

Phases describe **dependency and preferred order**, not a hard ban on touching another area when it is technically necessary (for example a small shared type or UI hook required by the current phase).

AI agents must **not** prematurely implement major later-phase gameplay systems merely because they appear on this list. If work would skip ahead, stop and ask, or stay within the current phase.

Gameplay implementation: **Political Hierarchy V0.1 is accepted / complete** (see `AI/PROGRESS.md`). **Territory / Map Foundation V0.1 is accepted / complete.** **Title Progression V0.1 is accepted / complete.** **Diplomacy V0.1 is accepted / complete.** **Warfare / Conquest V0.1 is IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** **Economy / Resources V0.1 is IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED.** **Military / Armies V0.1 is IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope; eight MIL-MP overlay cases remain deferred). **Communications V0.x is PRE-V0.5 REQUIRED — DESIGN FREEZE IN PROGRESS — NOT IMPLEMENTED** (current authorized design milestone; implementation not authorized). Later phases are not started. Completing Military V0.1 does **not** start Phase 2 Character Simulation.

Studio Play / Local Server / MCP / Director acceptance sessions are **development verification**, not the **first real playtest** (published Roblox server, one complete map, friends/humans, ~30-minute coherent match, determinable winner). See `AI/GAME_DESIGN.md`. Cumbersome remaining multiplayer tests may be **DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG** (`AI/PLAYTEST_BACKLOG.md`); deferred is not PASS.

**Product-development stages (direction):** V0.1–V0.4 core build/integration (ugly OK, confusing is not); around **V0.5** first serious playtesting; V0.5–V0.9 iterate from feedback; **V1.0** release target. Not a claim that V0.5 equals 50% of all features.

**PRE-V0.5 REQUIRED — Player communications / chat:** **DESIGN FREEZE IN PROGRESS — NOT IMPLEMENTED.** Current authorized **design** milestone. Usable Diplomatic, Council, Allies, and Direct paths (plus Admin/Observer) must exist **before entering serious V0.5 multiplayer playtesting**. **General** is retired as the player-facing name (replaced by **Diplomatic**). Implementation (remotes, GUI, TextChatService config, Kohl permission changes) is **not** authorized. Not a Military / Armies V0.1 blocker, not a current defect/regression, and not a `AI/PLAYTEST_BACKLOG.md` item. Full freeze: `AI/GAME_DESIGN.md` Player communications.

Do not implement aging, family simulation, or succession as currently approved core design. Do not implement a real Prestige economy, title-loss, Military / Armies V0.2, opinion, vassal diplomatic autonomy, buildings/development, or delegated greater-realm permissions unless directors authorize that work. Do not implement pre-playtest polish (map orientation, admin copy/reuse dashboard) unless the Director authorizes it. Do not implement public-product lobby / matchmaking unless the Director authorizes it. Do not implement Communications until the Director authorizes an **implementation** pass (design freeze is in progress).

## 1. Foundation & Architecture — COMPLETE

Source layout, Script Sync, Studio MCP workflow, shared types/config/util conventions, remotes reservation, thin bootstraps, GUI-first client/server split. Performance philosophy: store authoritative state and recalculate on meaningful change (do not prematurely optimize nonexistent systems). No major gameplay systems. Closed after audit result PASS WITH MINOR CLEANUP.

**Admin / Testing Infrastructure V0.1** (tooling, not a gameplay phase): official Kohl's Admin (@Scripth) installed; AdminBridge GameTester commands live; Studio `*Debug` fallback preserved.

## 2. Character Simulation

Authoritative character model as needed for later systems. **Not** the first gameplay prototype; political hierarchy comes first when implementation is authorized.

## 3. Family & Dynasty

Kinship, houses/dynasties, and family structure built on characters.

## 4. Time, Aging & Death

Game clock, aging, and death, so later succession and events have a time base.

## 5. Succession

Inheritance of status and titles when characters die or are displaced.

## 6. Titles & Territory

GUI political map as the primary board; multiple selectable fictional maps with stable geography distinct from political realm names; holdings and title establishment (dynamic map-configured greater-realm control + Prestige threshold; manual establish; server revalidation).

**Territory / Map Foundation V0.1** (data-driven `MapConfiguration`, 16-territory irregular-polygon test map, random unique human starts, Unclaimed remainder, pan/zoom/select, adjacency, greater-realm vs owner visualization) is **accepted / complete**. **Title Progression V0.1** (sequential ranks, Vale test thresholds, greater-realm control, manual establish, server revalidation, test Prestige not spent) is **accepted / complete**. Do not mark this phase complete. Additional maps, lobby voting, real Prestige economy, and title-loss remain unresolved / deferred. Player/map orientation (center-on / show-my-realm) is **required before the first published playtest**, not part of Territory V0.1. **Warfare / Conquest V0.1** is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (V0.1 only; not a complete military game).

## 7. Relationships

Opinion, bonds, rivalries, and other character-to-character relations.

## 8. Vassals & Realm Management

Liege/vassal structure and realm administration.

**Delegated greater-realm authority** (rank defaults + individual overrides = effective permissions) is **future architecture**, specified in `AI/GAME_DESIGN.md` / `AI/DECISIONS.md`. **Not implemented.** Do not retrofit into accepted V0.1 systems. Permission catalog unresolved.

## 9. Diplomacy

Negotiated relations between independent greater realms.

**Diplomacy V0.1** (Alliance + Non-Aggression Pact between root rulers; pending requests; consume hierarchy; dissolve on loss of independence) is **accepted / complete**. Do not implement deferred military systems, opinion, or vassal diplomatic autonomy from this Diplomacy checkpoint. Political Hierarchy, Territory / Map, and Title Progression V0.1 remain **accepted / complete**.

## 10. Politics, Factions & Schemes

Internal politics, factions, and covert schemes.

## 11. Warfare

Conflict resolution once realm and diplomatic context exist.

**Warfare / Conquest V0.1** (independent-root external wars for one enemy-controlled bordering **territory**; NAP blocks declaration; Alliance does not auto-join; multiple simultaneous wars on **different** territories; server-only debug resolution; attacker victory grants the target to the attacking root after revalidation; stale wars do not transfer) is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**. This accepts **V0.1** war-lifecycle authority. **Military / Armies V0.1** **supersedes** same-target multiplicity (at most one active war per territory; 10s post-war territory cooldown) and is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED** (ordinary V0.1 scope; 18 Director PASSes in `AI/PROGRESS.md`; eight MIL-MP overlay/race cases remain **DEFERRED ≠ PASS** in `AI/PLAYTEST_BACKLOG.md`). Full Director-locked Military contract is in `AI/GAME_DESIGN.md`.

## 12. Dynamic Events

Event content and emergent storytelling on top of simulation state.

## 13. Economy & Development

Match resources Gold / Prestige / Influence (reset per match, distinct roles). Account-level Crowns and Lifetime Support are not match-power currencies.

**Economy / Resources V0.1** (Gold foundation: start 150; Vale `baseGoldIncome` 10 Gold/min; global +1 Gold / 6 sec per owned baseline territory; direct-owner income; Unclaimed pays nobody; no automatic tax; conquest does not steal treasury; no required player Gold sink) is **IMPLEMENTED — DIRECTOR-VERIFIED — DIRECTOR-ACCEPTED**. This accepts **V0.1 Gold only**. Director Local Server **PASS** items (including spend/overspend and disconnect Gold wipe) are recorded in `AI/PROGRESS.md`. Buildings, development, taxation, trade, and **tall-vs-wide** quality investment remain later. Prestige remains Title V0.1 test Prestige. Influence remains deferred. Landless-liege political consequences remain unresolved and are not part of this acceptance.

## 14. Persistence

Account-level Crowns and Lifetime Support persist across matches. Match save/load of political state remains later unless directors specify it.

## 15. UI/UX Refinement

Presentation pass on existing systems; not a license to add skipped gameplay.

**Required usability before the first published playtest** (schedule here or immediately before that playtest; do not treat as optional decoration): player/map orientation; useful ownership identification; player-relevant information visibility; coherent GUI layout; admin copy/reuse UX for Director testing; major interaction clarity. Exact keybinds/art are not locked. The first playtest may use temporary/default binds if any keys are later authorized. **Player-configurable** Settings / Controls remapping is a **long-term public-product** requirement, **not** automatically part of that first-playtest list. Do not implement these unless the Director authorizes it.

## 16. Expansion & Advanced Systems

Post-core expansions. Do not start these while earlier phases are undefined or unimplemented.

**Public product match entry (future):** lobby / hub or menu; select available world/map as appropriate; join/queue; matchmaking / queue population; enter the selected match/server; start when required conditions are met. **Not** current work. **Not** Military / Armies V0.1. **Not** required for the first published playtest (a simple single published map/server remains allowed). Do not implement matchmaking, queue service, lobby, world selector, or multi-map server browser unless the Director authorizes that work.

**Public product Settings / Controls (future):** view and rebind supported gameplay and GUI logical actions. Extends the existing centralized (currently unassigned) keybind architecture. **Not** current work. **Not** Military / Armies V0.1. **Not** automatically required for the first published playtest.

**Player communications / chat (PRE-V0.5 REQUIRED — DESIGN FREEZE IN PROGRESS — NOT IMPLEMENTED):** current authorized **design** milestone; gate **before** serious V0.5 playtesting; not a numbered gameplay-system phase; **not** Phase 2. Full freeze in `AI/GAME_DESIGN.md`. Implementation not authorized. Do not start Character Simulation or Military V0.2 from this line.

**Battle History / War Chronicle (future optional):** scrollable prior battles / statistics. **Not** Military V0.1. Do not implement unless the Director authorizes it.
