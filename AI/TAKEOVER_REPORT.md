# Development takeover — 2026-10-09

Historical investigation report. Subsequent authorized replacement, GUI/Overview and conquest/victory work supersedes its baseline/status findings; current state is tracked in `AI/PROGRESS.md` and the implementation reports. Recovery provenance findings remain historical evidence.

Agent investigation and development verification only. No new Director acceptance. No gameplay source edits, commit, push, publication, or security-setting changes.

## 1. Current game state

The clean checkout began on `codex/player-communications-v05`, HEAD `5d495f8` (Add Codex project instructions). Local `main` and cached `origin/main` point to `322b072`. The remote was not fetched, so this is not a claim about current GitHub HEAD.

The checked-in memory and source agree on accepted Hierarchy, Territory, Title, Diplomacy, Warfare, Gold foundation, Military V0.1, and current AdminBridge tools. Communications is explicitly design-only in that checkout.

**The open Studio place materially differs.** Play Output reports `[Communications] V0.x started` at CommunicationsService:1143 and registers `inspectcomms` and `announce`. A server-side source inventory found CommunicationsService (33,175 characters), CommunicationsController (12,256), CommunicationsConfig (826), and bootstraps with Communications integration. The service also requires `Shared.Util.RealmGraph`, absent from disk. These are existing Studio changes, not changes made during this takeover. Their author, authorization, sync mapping, and acceptance remain unresolved.

A validated five-script JSON preservation snapshot is saved in `docs/verification/2026-10-09-studio-communications-snapshot.json`, outside synced script directories. It includes Communications service/controller/config and both bootstraps. **It is partial:** GUI, remotes, RealmGraph, admin integration changes, and other place assets are not captured. Do not use it as a complete place backup or blindly sync the old checkout into Studio.

## 2. Architecture and player loop

Hierarchy owns match ruler identities and nested liege/subject trees. Territory owns direct land ownership and unique random starts. Titles read subordinate-tree land control plus server test Prestige; players explicitly establish the next rank. Diplomacy owns independent-root Alliance/NAP pairs and expiring offers. Warfare validates root authority, enemy ownership, map-configured greater-realm adjacency, NAP, contest, and cooldown. Military reserves personal Troops, locks commitments, calculates one battle, applies casualties, then calls Warfare for the land outcome. Economy pays direct owners and handles recruitment spending. AdminBridge calls existing server APIs behind the GameTester gate; Kohl supplies command UI.

The implemented expansion loop is Territory → Gold → recruitment → Troop commitment → battle → conquest → future income. Vassalage builds greater realms while preserving personal land/resources. Alliances do not pool Troops or automatically join wars. NAP blocks declaration. Vale title thresholds are 2/100, 5/250, 10/500; Prestige is test state, checked rather than spent. A complete timed match/winner, real Prestige/Influence economies, and account persistence are not implemented by this baseline.

Bootstraps remain modular and ordered. Public political/territory snapshots are JSON events; Gold and Military state use per-player pushes. GUI instances remain Studio-owned. PlayerRelevantView filters ordinary war presentation rather than providing authority.

## 3. Runtime observations

Observed in the existing Studio version using Play Solo and a Local Server with two synthetic clients:

| Check | Agent observation |
| --- | --- |
| Start | Solo Independent Lord; server assigned Riverholt; 1,000 Total/Available Troops, 0 committed; Local Server produced two Lords with distinct colored holdings |
| Gold | +10 Gold/min, repeated +1 payout increases and cycling countdown; server startup logged starting Gold 150 / interval 6 |
| Map | Brightfen click selected it and added gold ring; wheel zoom changed scale; drag panned without changing selection |
| Input | Wheel over Military did not zoom map; clicking M did not change selected Brightfen |
| Recruitment | M spent 164 Gold, added 492 Troops, changed Total/Available 1000 → 1492, Gold → 0; visible result toast |
| Diplomacy | Player1 offered Alliance; Player2 received overlay and accepted; both clients reflected Alliance; Player2 offered NAP; Player1 declined; Alliance remained; Player1 broke Alliance |
| Vassalage | Player1 offered to Player2; Player2 accepted; Player2 displayed direct vassal Player1 and realm control 2/2; personal income remained +10 |
| Title | Runtime-only AdminDebug set Player2 Prestige 100; player clicked Establish Duchy; rank became Duke, Prestige stayed 100, direct vassal remained, next requirement 5/250 |
| Combat arithmetic | MilitaryDebug SelfTest returned true: nine PASS cases, including casualty bands, flooring, unopposed battle, and defender-favored ties |
| Cleanup | Solo stop Output unclaimed Riverholt and removed the ruler; multiplayer teardown was requested after testing |

These observations do not prove disk/Studio parity. No ordinary chat text was sent, so filtering and delivery are unverified. Multiplayer war declaration, commitment/battle/conquest, NAP acceptance/break, vassalage decline, and full disconnect overlays were not independently exercised this session.

## 4. Bugs and discrepancies supported by evidence

- **Source/Studio divergence:** confirmed by live service startup, commands, source inventory, and absent disk modules. Reconciliation is necessary before an implementation/fix can be reliably synchronized or attributed.
- **Narrow-viewport overlay clipping:** with Tool Grip Editor and Explorer open, incoming diplomatic Accept extended past the visible game viewport; vassalage text clipped on the opposite side. Maximizing exposed diplomacy controls. This is observed layout behavior in the live version; attribution to the accepted baseline is not established.
- **Player information loss in live TerritoryInfo:** selecting Brightfen showed name/ID/war/selection but not the documented owner/rank/root details. This contradicts the intended selected-territory information and needs a live-controller comparison.
- Output reported Kohl DataStore access disabled and an unrelated `cloud_9458961875.Model To Pixel.MainScript:331` `MainTextShadow` nil error during solo teardown. Neither establishes a gameplay authority defect. Settings/plugins were left untouched.

No Troop duplication, double resolution, or conquest corruption was reproduced. Unrun war cases are not passes.

## 5. Meaningful technical debt / authority review

Disk remote handlers derive the acting ruler from Player.UserId. Vassalage acceptance checks the intended recipient and revalidates the hierarchy. War declaration derives ownership/root/adjacency/NAP. Military restricts commitment to war roots and rejects malformed/negative/over-Available values; recruitment uses Economy.TrySpend. Gold client intents are Ready-only. AdminConfig denies non-allowlisted production users and limits negative-ID convenience to Studio. This is static inspection, not a forged-remote runtime test.

**Information-boundary concern:** disk Hierarchy and Diplomacy broadcast all pending requests to every client; Title broadcasts all test Prestige rows; Warfare broadcasts global war state before client filtering. Filtering ordinary GUI is not a network privacy boundary. Global pending requests/test Prestige need explicit public/private classification and recipient-safe replication if private. Per-player Economy/Military payloads are stronger boundaries; Military omits opponent intent/lock and pools before dual-lock.

Live Communications has a custom remote Send path plus TextChatService channels and TcsEcho, per-recipient filtering, and repeated realm-graph reconstruction. Audit both transport paths, filtering failure behavior, platform eligibility, stale Council membership, observer authorization, and performance before acceptance. No current Roblox API compliance claim is made without an API audit.

## 6. Deferred tests

MIL-MP-01–05, 07, 10, and remaining 11 races retain their existing **DEFERRED** status. No row was promoted to PASS/VALIDATED. MIL-MP-06/08/09 preserve prior Director evidence. Two clients were available, but no war was created in this run; the Military overlay/race matrix remains unverified here. Source reconciliation must precede attributing future regression results to the checked-in baseline.

## 7. Communications design status

Canonical disk freeze: Diplomatic uses sender-relative realm-graph distance ≤2, intentional asymmetric delivery, and send-time eligibility. Council is a ruler plus direct subjects; upward/downward contexts stay separate. Allies is one context per actual Alliance, without NAP or subject inheritance. Direct is two participants with current inter-realm adjacency; border loss cuts future sends immediately, restored borders may restore access, and delivered match history may remain. Disconnect removes participant availability. TextChatService/platform eligibility and Roblox filtering remain required.

Title is live for future messages. Diplomatic/Direct allow one viewer-relative Liege/Subject then Ally tag; Council/Allies use Title only. Admin observation is separate and context-explicit, with its own mute control; observer mute must not stop player communication. Voluntary intelligence speech is not keyword/number censored.

Selectors, native/custom frontend justification, formatting, help wiring, observer/announcement UX, history/search, stress behavior, and final acceptance matrix remain unresolved in disk design. The live implementation makes choices in these areas; its existence does not prove those choices were authorized or accepted. Persistent TextChannels plus derived political membership are visible in captured source; this is an implementation observation, not a new design decision.

## 8. Single recommended next action

**Reconcile the existing Studio Communications work with the intended authoritative checkout and its authorization history.** Preserve/export the full place and all changed scripts/dependencies first; compare before any sync. A provenance question is pending with the Director. Do not replace live work or label Communications accepted from the current evidence.

## 9. Concrete next milestone plan

1. Identify the Studio work's source/author and intended version; preserve full GUI/remotes/script state and compare with disk.
2. Inventory Communications dependencies and admin changes; audit current TextChatService capabilities against the frozen rules; list implementation choices that still need Director design decisions.
3. Run the accepted gameplay regression matrix on the reconciled version, including war outcomes and the available MIL-MP disconnect/independence cases. Record exact evidence.
4. Reproduce and fix only attributable defects with minimal changes; verify input layering, owner information, network visibility, and surrounding accepted behavior.
5. Once Communications implementation scope is confirmed, verify membership changes, adjacency loss/restoration, two-hop asymmetry, filtering/eligibility, observer isolation, and malformed requests before Director acceptance.
