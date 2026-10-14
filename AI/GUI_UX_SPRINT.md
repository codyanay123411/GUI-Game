# Playable match / GUI consistency milestone — 2026-10-13

**IMPLEMENTED — STUDIO SOLO AND THREE-CLIENT REGRESSION TESTED — NOT DIRECTOR-ACCEPTED.** No commit, push or publication. Historical sprint evidence below retains its original scope/date.

## Ordinary match and progression

A fresh owner-account Studio Solo match completed through native map selection, Conquer, amount entry, Confirm, Military Ready, ordinary income and recruitment, natural Domination, and final-map inspection. Starting at Ironlea with the existing 1,000 troops/150 Gold, eleven neutral conquests reached **12/16 provinces** (configured required count 12 at 70%; actual control 75%). Recruitment bought 933 troops for 311 earned Gold. Final ledger: 1,198 available/total, zero reserved, 2,012 frozen Gold. No admin commands, seeded resources/ownership/Prestige, forced results or timer overrides. Read-only runtime observers logged existing local/public state and control geometry; they did not invoke gameplay callbacks/remotes. [Ordinary match evidence](../docs/verification/gui-match-ordinary-2026-10-13.json), [observer](../docs/verification/gui-match-observer-client.luau.txt). One invalid 5,000 entry was rejected before correction to 500; one conquest used its normal deadline. Agent inspection pauses made the session about 34 minutes; this establishes an ordinary conquest-to-victory loop, **not human usability, competitive balance, a timed match target or every progression system**.

Prestige earning remains **not implemented**: TitleProgressionService initializes zero and exposes debug setters, with no ordinary earning path. Existing title thresholds remain enforced. The Titles drawer now states the limitation and the playable Domination alternative. Director must specify earning sources/triggers, formula, pacing/caps and abuse safeguards before natural title advancement can be implemented. No fake progression, rewards or new design was introduced.

## Unified surfaces and supported fixes

Causes of drift were competing authored/controller fonts, hardcoded Communications styles, generated controls missing component admission, disabled inputs lacking a common treatment, and fixed geometry ignoring supported text settings. Extended existing PrototypeGuiTheme and GameSettingsController, retaining hierarchy, relationship/map colors, urgent/error/victory distinctions and controller-owned input/visibility.

- Shared panel/text/input/scroll/primary/secondary/danger helpers; runtime descendant admission before settings base capture. Back/Help/Close/Direct/Observer/Continue are secondary; actionable mutations retain primary/danger/disabled treatment. Default GothamSSm now uses its actual font family, preserving weight/style.
- Messages authored controls and generated conversation/contact rows use existing shared helpers. Templates remain unscaled bases; live clones receive current settings.
- Titles uses one measured, scrollable drawer, with content width accounting for authored padding and scrollbar. Original Studio Frame is preserved, not deleted.
- Map legend/selection caption height adapts to text and drawer width, outside the viewport; camera limits and non-button input pass-through remain unchanged. This fixed a measured compact/max-font overflow (65 pixels in a 44-pixel allocation).
- Neutral contextual declaration is labeled Conquest; player conflict remains War. Final Economy readout says income is frozen/no further payouts instead of its stale pre-victory countdown. This fixes feedback only; server payouts/freeze were already correct.

New-task production changes: PrototypeGuiTheme; Communications, Economy, GameSettings, MapContext, StrategyPresentation, TerritoryMap and TitleProgression controllers. Existing admin and province-clarity changes, planning report and recovery assets were preserved. No new-task server/service/config gameplay edits. Durable mandatory rule: [AGENTS.md](../AGENTS.md); authoritative concise helper/exception reference: [GUI component contract](GAME_PRESENTATION_SETTINGS.md#gui-component-contract).

## Coverage and verification

Established one scoped live edit-mode baseline: PlaceId 77421850892463, reported version 158; eleven relevant source comparisons matched disk. Inspected affected GUI roots/style samples and recovery folders, then only changed sources/dependencies. GUI instances remain Studio-owned: Git scripts alone cannot reconstruct the current place. External Kohl/cloud/assets are outside this parity claim. Every source write checked the prior candidate and exact written source; recovery clones retained. `ServerStorage.GuiMatchRecovery_20261013` preserves original modules/TitlePanel and disabled disposable regression scripts, outside active GUI/bootstrap roots. Earlier admin/province recovery remains intact.

| Surface / behavior | Current agent evidence |
| --- | --- |
| Map, selection legend/reasons, radial buttons/background; conquest entry/recruitment/commit/result toast | Native ordinary full match; final caption/settings fixture; rejected amount; no additional authority |
| Realm, Titles, Economy, Messages and Players | Reopened by runtime presentation fixture; native Titles scrolling, Messages Help/empty contacts, three-player overview and frozen Economy visually inspected |
| Incoming fealty / treaty offers and generated Accept/Decline | Actual three-client incoming snapshots; both overlays visible and primary/danger helper roles asserted; acceptance through authoritative fixture APIs |
| Player attack/defense, hidden reservation, single/dual lock, calculated result and casualties | Actual three-client real commitment remotes; subject not commitment actor; opponent fielded amount hidden until permitted |
| Victory / realm victory / defeat; freeze, final inspection, navigation scrolling | Natural Solo victory plus separate seeded three-client results; native Defeat reopening/Continue and Players/Economy; server declaration/recruit denial |
| Creator GAME UI / GAME AUDIO | Native owner dashboard categories inspected; all four fonts and 0.9/1.1 font/UI scale with 0.8 opacity exercised through existing authorized setting requests; reset defaults confirmed |
| Tooltips / external controls | No independent project tooltip implementation found in relevant controllers; map hints/blocked reasons/Help inspected. Kohl native UI/promotion/personal settings remain vendor-owned, unchanged |

Additional contextual surface fixture opened Info/War/Diplomacy/Message/Realm/Military using the normal selection event path: **31 assertions** at HD720; this checks component admission and empty/self contexts, not every treaty/channel combination. [Replay](../docs/verification/gui-match-surfaces-client.luau.txt). Native post-fix empty-radial selection, Province info, Back, zoom, bounded drag and Recenter were observed.

Final presentation fixture: **82 assertions at VGA (ScreenGui 639×422) and 82 at HD720 (1279×662)**, including title text/bounds/action canvas, caption fitting, stale focus and radial flags. Earlier wide 1746×584 candidate also passed; final title-width change was subsequently verified at VGA/HD720. [Replay](../docs/verification/gui-match-presentation-client.luau.txt). Fixture corrections (wrong Establish member; deferred workflow routing) are test-harness issues, not gameplay passes. Compact caption overflow and title right-edge clipping were real defects, fixed and retested.

Three actual clients: **14 acknowledged phases, 100 cumulative assertions (47/34/19)** and final server PASS. [Evidence](../docs/verification/gui-match-multiplayer-2026-10-13.json), [server fixture](../docs/verification/gui-match-multiplayer-server.luau.txt), [client fixture](../docs/verification/gui-match-multiplayer-client.luau.txt). This deliberately seeds ownership/hierarchy/treaty/war setup and final threshold via existing services; it is separate regression evidence, never the ordinary-match claim. No timer/calculation override or Prestige grant. Synthetic clients could not configure creator settings. Temporary scripts disabled/archived before preservation.

Representative evidence: [before Titles](../docs/verification/gui-match-2026-10-13/before-titles.png), [before Players](../docs/verification/gui-match-2026-10-13/before-players.png), [ordinary victory](../docs/verification/gui-match-2026-10-13/ordinary-victory.png), [compact Titles](../docs/verification/gui-match-2026-10-13/titles-compact.jpg), [normal Messages](../docs/verification/gui-match-2026-10-13/messages-normal.jpg), [compact Players](../docs/verification/gui-match-2026-10-13/players-compact.jpg), [realm victory](../docs/verification/gui-match-2026-10-13/realm-victory-compact.jpg), [defeat](../docs/verification/gui-match-2026-10-13/defeat-compact.jpg), [correct frozen Economy](../docs/verification/gui-match-2026-10-13/economy-frozen-compact.jpg).

Final integrity: eight changed production sources matched live Studio by normalized byte length/hash; TitlePanel has one active ScrollingFrame and its original Frame remains in recovery. Changed sources and disposable fixtures compiled with the available Luau compiler; actual diff reviewed and `git diff --check` passed. Startup hashes confirmed server/admin/planning work was untouched by this milestone. Local-only snapshot: `docs/verification/gui-match-final-2026-10-13.rbxl` (776,446 bytes, saved 2026-10-13 10:42 local; SHA256 `8F6BB5BCCF6EF81C157D1D0D09212FBFD6D5EB00CA1D72A8580767B791948D2D`), confirmed ignored. No whole-place or cloud-freshness claim.

**DIRECTOR VERIFICATION REQUIRED:** ordinary multiplayer human match, readability/action prominence, sound/animation feel and title-limit wording. **NOT TESTABLE IN CURRENT ENVIRONMENT:** published-account peer chat filtering/privacy; physical touch behavior; Kohl saved preferences with Studio API access disabled. No touch or published-account pass, no new Director acceptance. Existing large-list/load and human balance backlog remains. Next step: Director walkthrough below; resolve Prestige design separately.

## Director walkthrough

1. Join fresh; read resources, Domination target and selected-province owner/root labels. Pick a `+` bordering neutral province (corners count).
2. Conquer: enter an affordable force, Confirm, check accepted reservation in Military, then Ready. Compare locked force with the calculated-result presentation and casualty/survivor feedback.
3. Use earned Gold to recruit through your own holding. Continue expansion to the displayed target. Open Realm/Messages/Players and inspect available diplomacy/fealty with another player.
4. Open Titles: verify the explicit Prestige prototype limit; no ordinary title earning is promised. At compact size scroll to the disabled Establish action.
5. After victory/defeat choose Inspect final map, reopen Match result (scroll the compact navigation), inspect frozen Economy and Players. Verify competitive actions stay unavailable.
6. As creator compare GAME UI fonts/scale/opacity with open drawers, then reset; assess GAME AUDIO separately. Human approval remains yours.

---

# GUI / UX sprint — 2026-10-09

Status: **IMPLEMENTED — AGENT-VERIFIED PRESENTATION — DIRECTOR VISUAL APPROVAL REQUIRED**. No gameplay acceptance changed. No commit, push, or publication.

## Result

Replaced the seven permanently competing panels with a map-first interface: a centralized eight-button navigation rail (Map plus the seven systems), one contextual drawer, persistent ruler/Gold/Troops summaries, province labels, consistent slate/gold typography and buttons, and a full-screen noninteractive dark gradient behind the interface. The original map geometry and political colors remain intact. Native Roblox topbar remains; the duplicate player leaderboard is hidden in favor of Realm.

Priority Vassalage and Diplomacy offers stack above the currently open drawer and keep Accept/Decline visible. A navigation notice identifies incoming offers. Military automatically opens once for a new commitment decision, reserves space for its full status, and retains existing recruitment/commit/Ready behavior. Results remain transient. Admin inspect results expand nested JSON into readable lines in a measured, scrollable window.

## Source and Studio changes

- New `StarterPlayerScripts/Controllers/StrategyPresentationController.luau`: centralized selection, responsive layout, resources, empty Realm state, priority layering, and button feedback. Client presentation only; no request remotes.
- `Bootstrap.local.luau`: start presentation after existing gameplay controllers; no additional bootstrap.
- `TerritoryMapController.luau`: camera-projected, noninteractive province labels; navigation/topbar added to existing pointer blockers.
- `PrototypeGuiTheme.luau`: shared slate/gold tokens and readable button typography. Existing Kohl theme consumes these tokens.
- `CommunicationsController.luau`: theme its generated rows and send state; panel type reflects its new ScrollingFrame. No transport, policy, Help text, or reach changes.
- `MilitaryController.luau`: taller commitment text; `WarfareController.luau`: danger style for enabled Declare War.
- `AdminFeedbackController.luau`: additional existing inspect operations, recursive readable output, measured text/canvas sizing, reset scroll for a new result.
- `AdminBridge.luau`: tiny compatibility fix: InspectComms uses existing `done()` feedback routing, just like the other inspect branches. Permissions and authoritative APIs unchanged.

Studio assets: added `StarterGui.StrategyBackground.Surface` with UIGradient; added StrategyTopbar, StrategyNavigation and MapHint in HierarchyPrototypeGui. Main, TerritoryInfo, DiplomacyPanel, MilitaryPanel and CommunicationsPanel are scrolling roots. Updated titles, spacing, Economy context copy, map framing and text styles. Priority overlays and toasts retain their controller-owned content/visibility. GUI instances remain Studio-owned, not a new on-disk UI framework.

## Preservation

Exact original GUI clone: `ServerStorage.GuiSprintRecovery_20261009.HierarchyPrototypeGui`. Original recovered Communications archive remains inactive in ServerStorage. Pre-sprint place: `docs/verification/communications-direct-clarified-2026-10-09.rbxl`. Final local place: `docs/verification/gui-ux-sprint-2026-10-09.rbxl` (ignored binary; contains GUI assets). Earlier recovery snapshots remain intact. Temporary multiplayer ownership/rank fixtures and diagnostic scripts were confined to test sessions.

## Targeted verification

Baseline Play was inspected before edits; screenshot `docs/verification/gui-sprint-before.jpg`. GUI coverage is not a full reacceptance of the underlying systems.

| Case | Evidence / result |
| --- | --- |
| UX-01 Map/navigation | All eight nav destinations exercised. Map remains visible with one drawer. Westmere selection highlighted the correct province and showed its six-line details. Map zoom and zoomed pan measured camera changes; labels followed. |
| UX-02 Realm/Titles | Empty Solo Realm state; three-player ruler list; eligible Duke action clicked after temporary server prestige fixture; rank and subsequent King requirements updated. |
| UX-03 Political offers | Three-client Local Server: simultaneous fealty and Alliance offers visible over Titles; accepted fealty, declined Alliance; requests cleared and both parties received outcomes. |
| UX-04 Military/Economy | Recruited 3 for 1 Gold via GUI; counts/cost updated. Declared war through territory UI; both participants opened Military. Defender explicitly readied 0; attacker committed 3 and decision deadline locked it. Battle progress and resulting 3-vs-0 victory observed; ownership and available/committed counts updated. This does not reverify all combat arithmetic or ready races. |
| UX-05 Communications | Exact Diplomatic Help repeated unchanged; Council context and Direct contacts observed in multiplayer. A real Solo native-filtered message appeared in the transcript. No optimistic/fallback text added. Existing 26/26 personal-border policy verification remains separate. |
| UX-06 Responsive | Ordinary Solo content measured 929×521 (near 16:9), HD720 emulator content 1280×661 / viewport 1280×719, small VGA content 639×421 / viewport 639×479; wide Local Server viewport visually checked. Small navigation, Messages and Military drawers scrolled to lower controls. Province labels deliberately hide when provinces are too narrow. |
| UX-07 Input layering | Military drawer click/drag/wheel preserved map selection/camera in multiplayer. Small-screen nav wheel and Messages outer scrolling preserved both. Priority offer surface click/drag/wheel probe preserved both (presentation-only forced visibility; real offer flow separately covered by UX-03). Admin window input preserved both. |
| UX-08 Admin inspect | Real AdminBridge InspectComms delivered and showed nested output after feedback fix. Long local diagnostic text exposed broken automatic canvas; measured repair produced canvas height 1581 and scroll Y=500 while camera/selection stayed unchanged. Fresh startup and saved-source check recorded separately. |

Screenshots in `docs/verification/`: `gui-sprint-map.jpg`, `gui-sprint-political-offers.jpg`, `gui-sprint-result.jpg`, `gui-sprint-communications.jpg`, `gui-sprint-native-message.jpg`, `gui-sprint-small.jpg`, `gui-sprint-admin-inspect.jpg`, `gui-sprint-pan.jpg`. Some screenshots show intermediate typography before final polish. Output evidence: `gui-sprint-server-output.txt`, `gui-sprint-player1-output.txt`, `gui-sprint-final-output.txt`, `gui-sprint-small-output.txt`, `gui-sprint-hd-output.txt`. Output retrieval is capped; screenshots capture additional final measurements.

## Limits / remaining weaknesses

- Multiplayer native peer filtering/privacy remains **NOT TESTABLE with Studio synthetic negative UserIds**; Solo sender Success was observed, not production peer delivery. See Communications implementation matrix.
- Existing Kohl startup notices/promotions can cover the map temporarily; no HTTP/API settings, admin permissions or vendor implementation were changed. Existing disabled DataStore access and plugin warnings are unrelated to this sprint.
- At tiny sizes the drawer consumes much of the canvas; it can be closed through Map. Small labels hide; scrolling is required to reach lower controls. Mobile/touch, gamepad and extreme aspect ratios were not accepted or fully verified.
- Multiple pending offers within one overlay, long names/large hierarchy populations, accessibility contrast review and extended battle-state races need broader playtest coverage. Admin ID copy/reuse remains a separately tracked requirement.
- Director visual approval still needed for slate/gold palette, map labels, drawer widths, navigation naming and priority-offer prominence. This sprint does not implement configurable controls, lobby, battle history, Phase 2 or Military V0.2.

### Final persisted-build check (completed after midnight 2026-10-10)

Fresh final startup confirmed inspector AutomaticCanvasSize=None and Active=true; long text scrolled to Y=500 with canvas height 1581. Real InspectComms feedback then rendered and reset scroll to zero. Final evidence: `docs/verification/gui-sprint-final-inspector-output.txt`. Source-equality check covers all nine changed modules; `git diff --check` passes. No new project-controller errors observed on final startup. Existing vendor/plugin warnings remain identified separately.

Final local snapshot saved successfully: `docs/verification/gui-ux-sprint-2026-10-09.rbxl`, 727029 bytes. Final edit-mode audit printed `FINAL_GUI_SOURCES_EQUAL 9 FIXTURES_REMOVED GUI_BACKUP_PRESENT`; evidence in `docs/verification/gui-sprint-final-integrity.jpg`.

## Rank Gold bonuses and fixed-stop commitments — 2026-10-13

**Implemented; agent verification below; not Director-accepted.** Current-rank personal Gold bonuses are Lord 0%, Duke +0.5%, King +1%, Emperor +2%. EconomyConfig owns basis-point rates; EconomyPayout/EconomyService carry fractional credits across existing six-second payouts. Subject land, starting balances, admin grants and spending do not receive bonuses. Promotion refreshes authoritative income. Existing Economy/Titles show the bonus and resulting income; Prestige and title thresholds are unchanged.

CommitmentPolicy and CommitmentBar provide one themed bar with only 10/25/35/50/75% stops for MapContext review and Military. Integer amounts still use existing server validation. New reviews default to preview-only 10%; active pools include available troops plus that war's own accepted reservation. Passive changes update previews without submitting. Serialized, debounced edits and server CommitResult receipts gate Ready until the latest edit is accepted. Off-stop accepted amounts remain accurate and unchanged until deliberate interaction; zero rounding is explained. Lock/end disable editing. Retired numeric inputs remain hidden/inactive; recruitment remains unchanged.

### Evidence and limits

- Automatic: 5,175 arithmetic/policy assertions passed ([fixture](../docs/verification/rank-commit-policy-checks.luau.txt)); affected production sources compiled. Source-baseline hashes confirm only nine existing production modules changed, plus the two new bar/policy modules; prior work was preserved.
- Studio Solo, one actual client with synthetic server opponents/ownership/ranks: four rank rates, direct-owner subject exclusion, exact admin grant/spend, five real payouts totaling 51 Gold for 100/min Emperor base, native review/active clicks and drag, off-stop 137 reservation, own/other-war separation, rejected edit/retry, passive preview change, accepted zero, and post-Domination freeze passed. [Runtime evidence](../docs/verification/rank-commit-runtime-2026-10-13.json), [screens](../docs/verification/rank-commit-2026-10-13/), and retained `rank-commit-*.luau.txt` fixtures. Setup uses existing debug APIs and extends synthetic decision windows; this is not natural progression or full-match acceptance.
- Initial fixture failures were setup timing (deferred ruler/war cleanup), corrected before passing checks. Final UI follow-up also initially ran a server fixture in the client view; its absent Duke/war state caused a failed layout assertion, not a passing test.
- Final review narrowed compact Military widths to preserve scrollbar margin, froze locked captions, and prevented stale rejection feedback from poisoning queued edits. Final-candidate checks and correspondence are recorded below as completed or unavailable; earlier screenshots may precede these presentation corrections.
- No new multi-client or published-account latency test; no human usability acceptance, touch or gamepad verification. No supplied reference image was available for visual comparison. **DIRECTOR VERIFICATION REQUIRED:** judge normal/compact readability and commitment interaction. **NOT TESTABLE IN CURRENT ENVIRONMENT:** real-account network conditions. No full historical suite was repeated.

Walkthrough: open Economy/Titles to see personal base, rank bonus and income. Select Conquer/War, choose one of five stops, inspect preview and Confirm. In Military, compare preview against server-accepted troops; choose/drag a stop, wait for acceptance, then Ready. Opening review and changing available forces alone do not reserve more troops.

### Final candidate follow-up

Compact 640×422 and normal 1279×662 each passed 149 bounds/theme assertions across four fonts, 0.9/1.1 UI/font scales and opacity settings. Native compact and normal click/drag receipts remained allowed-stop integer amounts; queued invalid 2000 followed by valid 350 recovered with Ready enabled and no stale rejection status. Native Ready locked 245; caption became `Locked: 245 troops`, editing disabled, Ready inactive. Final normal screenshot and structured follow-up are in the linked evidence. Compilation passed all eleven production sources and six retained fixtures; `git diff --check` passed. Final source/recovery correspondence status follows.

Final edit-mode read-only comparison printed `RANK_COMMIT_FINAL_SOURCE_PARITY_PASS 11`: all affected live sources equal disk, recovery folder present, runtime fixture absent. Local-only snapshot: `docs/verification/rank-commit-final-2026-10-13.rbxl` (ignored). Previous snapshots and recovery assets retained. No commit, push or publication.

## Fixed-stop affordable recruitment — 2026-10-13

**IMPLEMENTED — AUTOMATICALLY CHECKED — TARGETED STUDIO TESTED — NOT DIRECTOR-ACCEPTED.** Recruitment now reuses CommitmentBar with25/35/50/75/100 only; commitment defaults stay10/25/35/50/75. New openings default25% without recruitment. RecruitmentPolicy predicts `floor(floor(max(0, Gold)) × percent/100)` Gold and uses MilitaryConfig.TroopsPerGold for quantity; current rate3, minimum1 Gold /3 Troops, no additional existing cap. The server Recruit API still validates whole positive multiples, funds and match state. Only explicit Recruit submits. Gold changes refresh previews; zero/insufficient/loading/pending/frozen states are readable. Numeric RecruitBox and duplicate Max are retained hidden/inactive/noneditable, with their mutation listeners removed; the legacy authoritative RecruitMax API remains for compatibility/admin use.

MilitaryController serializes requests and uses actor-scoped RecruitResult receipts through the existing military remotes. Positive bounded sequence IDs prevent repeating the same or older identified request on the server; failed requests are also remembered, so a deliberate retry uses a new ID. Client receipts must match the pending ID; generic Notice/State messages cannot release it. Rejection refreshes private Gold through existing Economy Ready. Player departure clears receipt cache. No new remote, client authority, costs, gameplay cap or admin permission. StrategyPresentationController measures/reflows the existing scroll drawer; shared bar/theme/map input guards are reused. No authored GUI assets deleted or overwritten.

**Coverage/preservation:** current affected StarterGui control baseline inspected; five disk modules compared and guarded-synced, with four exact original modules retained inactive under ServerStorage.RecruitmentRecovery_20261013 and ignored tmp/recruit-bar-20261013/before. Existing saved places/recovery and prior work retained. The new bar is generated at runtime; disk does not represent the entire place. Affected source correspondence and cleanup checked after stopping; no whole-place parity claim, commit, push or publication.

**Evidence:** [66 pure assertions](../docs/verification/recruitment-policy-checks.luau.txt) passed for floor boundaries, fractional/nonfinite/zero Gold, configured rate, invalid stops and unchanged commitment snap behavior. Five production modules and six saved fixtures compile; task-scoped diff review and git diff --check pass. [Runtime receipts](../docs/verification/recruitment-runtime-2026-10-13.json), [client observer](../docs/verification/recruitment-runtime-client.luau.txt), [server fixture](../docs/verification/recruitment-runtime-server.luau.txt), [bounded stale view](../docs/verification/recruitment-stale-preview-server.luau.txt), [freeze server](../docs/verification/recruitment-freeze-server.luau.txt), [freeze client](../docs/verification/recruitment-freeze-client.luau.txt).

Focused Solo verification: opening/bar changes kept1000 Troops; clicking labeled35% and dragging through allowed stops to100% changed preview only and did not move the map selection/camera. Native maximum recruitment added474 Troops for158 current Gold; same-ID replay left1474 unchanged. An explicitly synthetic stale150-Gold view submitted336 Troops while server held2 Gold: rejected, no troops added; current Gold refresh recovered preview. A subsequent native retry added39 Troops for13 Gold. Corrected deferred Text observer verified action/bar disabled while pending. Current compact viewport639×422, default theme and Arial/1.1 density/font: measured text, ordered cost/action, scroll reach, hidden old controls and stop membership passed; zero Gold and1-Gold rounding were exercised. Normal seeded ownership APIs reached match end: Recruit rejection/unchanged total assertions executed before a fixture's later unsupported Source-write; separate correctly installed client observer passed disabled bar/button and frozen wording. This is a targeted cutoff, not a natural match rerun.

Initial fixture corrections are recorded in receipts: selection-event delivery needed a short wait before contextual opening; sampling a separate click handler ran before production input processing; runtime server scripts cannot assign another script's Source. Final fixtures correct these issues. A feedback separator rendering issue was fixed and the affected screen reloaded; no unrelated suite was broadened. [Compact preview](../docs/verification/recruitment-2026-10-13/compact-preview.jpg), [zero rounding](../docs/verification/recruitment-2026-10-13/compact-zero-rounding.jpg), [rejected preview](../docs/verification/recruitment-2026-10-13/rejected-preview.jpg).

**Remaining:** human readability/feel is DIRECTOR VERIFICATION REQUIRED; published-account latency/reconnect and touch/gamepad are NOT TESTABLE IN CURRENT ENVIRONMENT / unverified. Synthetic stale views are not real network tests. Next: select personal province → Military → click/drag a stop → inspect Troops/Gold → Recruit; reopening returns25% preview. Shared competitive rules, commitment stops and rank/Prestige work are unchanged.
