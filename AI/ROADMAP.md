# Roadmap

Phases describe **dependency and preferred order**, not a hard ban on touching another area when it is technically necessary (for example a small shared type or UI hook required by the current phase).

AI agents must **not** prematurely implement major later-phase gameplay systems merely because they appear on this list. If work would skip ahead, stop and ask, or stay within the current phase.

Gameplay implementation: **Political Hierarchy V0.1 is accepted / complete** (see `AI/PROGRESS.md`). **Territory / Map Foundation V0.1 is accepted / complete.** **Title Progression V0.1 is accepted / complete.** **Diplomacy V0.1 is accepted / complete.** **Warfare / Conquest V0.1 is implemented — partially director-verified — acceptance testing paused — not director-accepted.** Later phases are not started. Completing warfare V0.1 does **not** start Phase 2 Character Simulation. Do not implement aging, family simulation, or succession as currently approved core design. Do not implement a real Prestige economy, title-loss, armies/battles, opinion, or vassal diplomatic autonomy unless directors authorize that work.

## 1. Foundation & Architecture — COMPLETE

Source layout, Script Sync, Studio MCP workflow, shared types/config/util conventions, remotes reservation, thin bootstraps, GUI-first client/server split. Performance philosophy: store authoritative state and recalculate on meaningful change (do not prematurely optimize nonexistent systems). No major gameplay systems. Closed after audit result PASS WITH MINOR CLEANUP.

**Admin / Testing Infrastructure V0.1** (tooling, not a gameplay phase): architecture recorded; Admin Bridge foundation for current systems; official Kohl's Admin loader **not** in the place yet.

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

**Territory / Map Foundation V0.1** (data-driven `MapConfiguration`, 16-territory irregular-polygon test map, random unique human starts, Unclaimed remainder, pan/zoom/select, adjacency, greater-realm vs owner visualization) is **accepted / complete**. **Title Progression V0.1** (sequential ranks, Vale test thresholds, greater-realm control, manual establish, server revalidation, test Prestige not spent) is **accepted / complete**. Do not mark this phase complete. Additional maps, lobby voting, real Prestige economy, and title-loss remain unresolved / deferred. **Warfare / Conquest V0.1** is specified separately and is **implemented — not director-accepted** (acceptance testing paused).

## 7. Relationships

Opinion, bonds, rivalries, and other character-to-character relations.

## 8. Vassals & Realm Management

Liege/vassal structure and realm administration.

## 9. Diplomacy

Negotiated relations between independent greater realms.

**Diplomacy V0.1** (Alliance + Non-Aggression Pact between root rulers; pending requests; consume hierarchy; dissolve on loss of independence) is **accepted / complete**. Do not implement Warfare / Conquest V0.1, opinion, or vassal diplomatic autonomy from this Diplomacy checkpoint. Political Hierarchy, Territory / Map, and Title Progression V0.1 remain **accepted / complete**.

## 10. Politics, Factions & Schemes

Internal politics, factions, and covert schemes.

## 11. Warfare

Conflict resolution once realm and diplomatic context exist.

**Warfare / Conquest V0.1** (independent-root external wars for one enemy-controlled bordering territory; NAP blocks declaration; Alliance does not auto-join; multiple simultaneous wars; server-only debug resolution; attacker victory grants the target to the attacking root after revalidation; stale wars do not transfer) is **implemented — partially director-verified — acceptance testing paused — not director-accepted**. Resume at **Defender Victory**. Do not start armies, battles, claims, peace, or other deferred military systems from this checkpoint. Hierarchy, Territory / Map, Title Progression, and Diplomacy V0.1 remain **accepted / complete**.

## 12. Dynamic Events

Event content and emergent storytelling on top of simulation state.

## 13. Economy & Development

Match resources Gold / Prestige / Influence (reset per match, distinct roles). Buildings and detailed formulas later. Account-level Crowns and Lifetime Support are not match-power currencies.

## 14. Persistence

Account-level Crowns and Lifetime Support persist across matches. Match save/load of political state remains later unless directors specify it.

## 15. UI/UX Refinement

Presentation pass on existing systems; not a license to add skipped gameplay.

## 16. Expansion & Advanced Systems

Post-core expansions. Do not start these while earlier phases are undefined or unimplemented.
