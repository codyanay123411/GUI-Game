# Roadmap

Phases describe **dependency and preferred order**, not a hard ban on touching another area when it is technically necessary (for example a small shared type or UI hook required by the current phase).

AI agents must **not** prematurely implement major later-phase gameplay systems merely because they appear on this list. If work would skip ahead, stop and ask, or stay within the current phase.

Gameplay implementation: **Political Hierarchy V0.1 is accepted / complete** (see `AI/PROGRESS.md`). **Territory / Map Foundation V0.1 is accepted / complete.** Later phases are not started. Completing the map foundation does **not** start Phase 2 Character Simulation. Do not implement aging, family simulation, or succession as currently approved core design.

## 1. Foundation & Architecture — COMPLETE

Source layout, Script Sync, Studio MCP workflow, shared types/config/util conventions, remotes reservation, thin bootstraps, GUI-first client/server split. Performance philosophy: store authoritative state and recalculate on meaningful change (do not prematurely optimize nonexistent systems). No major gameplay systems. Closed after audit result PASS WITH MINOR CLEANUP.

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

**Territory / Map Foundation V0.1** (data-driven `MapConfiguration`, 16-territory irregular-polygon test map, random unique human starts, Unclaimed remainder, pan/zoom/select, adjacency, greater-realm vs owner visualization) is **accepted / complete**. Do not mark Phase 6 complete. Title-scaling numerical thresholds, additional maps, lobby voting, warfare, and conquest remain unresolved / deferred.

## 7. Relationships

Opinion, bonds, rivalries, and other character-to-character relations.

## 8. Vassals & Realm Management

Liege/vassal structure and realm administration.

## 9. Diplomacy

Negotiated relations between realms or rulers.

## 10. Politics, Factions & Schemes

Internal politics, factions, and covert schemes.

## 11. Warfare

Conflict resolution once realm and diplomatic context exist.

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
