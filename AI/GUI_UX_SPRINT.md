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
