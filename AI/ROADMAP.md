# Roadmap

Phases describe **dependency and preferred order**, not a hard ban on touching another area when it is technically necessary (for example a small shared type or UI hook required by the current phase).

AI agents must **not** prematurely implement major later-phase gameplay systems merely because they appear on this list. If work would skip ahead, stop and ask, or stay within the current phase.

Gameplay implementation has not started. **Current phase: 1 — Foundation & Architecture.**

## 1. Foundation & Architecture

Source layout, Script Sync, Studio MCP workflow, shared types/config/util conventions, remotes reservation, thin bootstraps, GUI-first client/server split. No major gameplay systems.

## 2. Character Simulation

Authoritative character model and the first playable character loop. Later systems depend on this.

## 3. Family & Dynasty

Kinship, houses/dynasties, and family structure built on characters.

## 4. Time, Aging & Death

Game clock, aging, and death, so later succession and events have a time base.

## 5. Succession

Inheritance of status and titles when characters die or are displaced.

## 6. Titles & Territory

Holdings, titles, and map/territory representation (GUI-first).

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

Economy, holdings development, and related resources.

## 14. Persistence

Saving and loading authoritative state.

## 15. UI/UX Refinement

Presentation pass on existing systems; not a license to add skipped gameplay.

## 16. Expansion & Advanced Systems

Post-core expansions. Do not start these while earlier phases are undefined or unimplemented.
