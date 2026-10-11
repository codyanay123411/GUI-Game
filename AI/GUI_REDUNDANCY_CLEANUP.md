# GUI redundancy cleanup — 2026-10-10

## 2026-10-11 — Radial background passes map input

Input-only correction: the radial CanvasGroup declares MapInputThroughBackground; ContextTransitions keeps that root Active=false and BlocksMapInput=false while leaving descendant interaction enabled. The decorative heading is inactive. Each generated action button remains active and carries BlocksMapInput=true, so the existing map guard protects only button bounds. Drawers/offers retain their existing blocking behavior. Appearance, animation timing, opacity and gameplay are unchanged.

Studio HD720 Play verification: three runtime audits passed across open/hide/reopen; no active decorative descendants or full-area button/hitbox exists. Native empty-circle click selected Westmere beneath Northvale's radial; later empty-side click selected Northvale. Province info, Conquer, Military and Realm info each emitted MouseEnter and Activated and opened the expected view without selecting a province under the button. Conquer review was cancelled without declaration. Wheel zoom and drag beginning through the center/heading moved the map; drag retained selection. Final two changed sources matched Studio, temporary tests were removed, and compile/whitespace checks passed. Output: docs/verification/radial-input-output-2026-10-11.txt. Agent verification is separate from Director acceptance.

Final ignored local snapshot: docs/verification/radial-input-final-2026-10-11.rbxl; SHA-256 53A7E4DEDDF79F152ABAB70B62EA996F203F349ACDB327EDC6DD36E7096E9DFC. Export saved the Studio draft; no Roblox Publish action. Prior snapshots remain preserved.

Director-authorized presentation migration. Server gameplay, validation, remotes, rules, resources and match authority are unchanged. This replaces the prior milestone's intentional temporary retention of full legacy navigation. Agent verification is separate from Director acceptance.

## Surface audit and decisions

"Persistent" means available from the global shell; global detail panels still open only on request.

| Surface | Classification | Final purpose |
| --- | --- | --- |
| Map, navigation, ruler/Gold/troop summaries, map hint | A — keep persistent | Map is the default; summaries remain brief. |
| Realm | A global access / C detail | Your own greater-realm hierarchy and personal ruler details. The duplicate all-player list and outbound fealty buttons are retired. |
| Titles | A global access / C detail | Progression and existing establishment action. |
| Economy | A global access / C detail | Treasury, income and payout breakdown. |
| Messages | A global access / C detail | Existing conversations, contacts, sending, help and separate Observer controls. Contextual Message chooses an existing conversation. |
| Players / Realm Overview | A global access / C detail | Match-wide public player comparison and expandable realm trees; existing Tab behavior retained. |
| Radial map actions | B — contextual only | One selected province, concise relationship and eligible actions. |
| Province / Realm Info | B — contextual only | One shared focused drawer using existing public snapshots; no old Territory destination. |
| War / Conquer review | B — contextual only | Existing declaration intent and initial commitment handoff. |
| Military / recruitment / commitment / battle details | B — contextual only | Existing MilitaryController fields and handlers moved into MilitaryWorkflowPanel; own holding opens recruitment, contested target opens commitment. |
| Incoming vassalage / treaty offers | B — priority context | Existing offer cards and Accept/Decline handlers; brief open transition. No second incoming list. |
| Attention markers | B — contextual only | Existing event anchoring, aggregation, acknowledgment and one-time pulse. |
| Battle banner / result toast | B — temporary attention | Brief map notification; battle banner suppressed while its military detail is open. |
| Victory / Match Result | C — secondary result | Existing authoritative result; conditional result navigation retained. |
| Admin inspection and Kohl settings | C — secondary tools | Existing authorized tooling and GAME UI/AUDIO integration. |
| TerritoryInfo / DiplomacyPanel | D — retired | Replaced by context; absent from StarterGui and PlayerGui. |
| Old MilitaryPanel destination | D — retired | Its useful controls are reused inside a new contextual shell; no global Military button. |
| Territory / Diplomacy / Military navigation | D — retired | Final ordinary navigation is Map, Realm, Titles, Economy, Messages, Players. |
| Realm PlayerList, PlayersHeader, IncomingList, IncomingHeader, hidden Notice | D — retired | Players/context/offer cards/shared result toast supply their functions. |
| PlayerRow, DiplomacyRow, RequestRow templates; unused offer Body/Buttons | D — retired | No active construction or action bindings remain. |

## Assets and controller reuse

Twenty retired objects are retained outside active player GUI under `ServerStorage.GuiRedundancyRecovery_20261010`. Historical recovery and verification snapshots are preserved. The pre-migration offline place is `docs/verification/contextual-map-final-2026-10-10.rbxl` (ignored local binary).

Studio assets now use CanvasGroup roots for ContextRadialPanel, ContextWorkflowPanel, MilitaryWorkflowPanel and both incoming offer overlays. Each drawer contains a Content ScrollingFrame; Military retains its original recruitment/commitment widgets and adds BackButton. `PresentationState.SelectedTerritoryId` is a view-independent selection value used by the map, military and selection audio. This is client presentation state, never authority.

TerritoryMapController retains map rendering, authoritative snapshot consumption, selection and input. Its retired label rendering is removed. MilitaryController retains recruitment, debounce, accepted commitment, lock, result cache and server contracts. DiplomacyController and PoliticalHierarchyController retain snapshots, incoming cards, notices and authorized responses. WarfareController retains its notice adapter; duplicated obsolete declaration UI eligibility/render/bindings are removed because existing contextual state and review already provide those functions. No second gameplay implementation is introduced.

Top troop summaries consume presentation attributes emitted from MilitaryController's existing snapshot, independent of retired labels. Info and Diplomacy no longer link to obsolete full views. Empty map selection closes contextual Military; Back returns to the selected radial. Offers, Players and Victory dismiss territory context. Intentionally opened global detail views remain navigation destinations.

## Transparency and transitions

Radial authored background transparency is 0.42; center is 0.70; action buttons retain the more opaque existing theme. Existing PanelOpacity applies `1 - (1 - baseTransparency) * PanelOpacity`, with no new setting.

ContextTransitions animates CanvasGroup transparency and a dedicated UIScale. Open is 0.16 seconds (radial/modal 0.94 to 1; drawer 0.98 to 1 plus a 10-pixel slide); close is 0.12 seconds with a slight scale-down. Durations divide by AnimationSpeed. AnimationsEnabled=false snaps to the final presentation. Settings changes cancel pending transitions cleanly. Logical dismissal clears ContextOpen, interaction and map-blocking immediately, before any cosmetic fade completes. Tokens prevent an old completion from hiding a newly reopened context.

Existing button feedback, font, semantic audio and marker pulse are reused. No transition delays a server request or accepted state. Battle/ownership/diplomacy/victory timing is unchanged.

## Verification

**Agent verification passed; Director acceptance remains pending.**

| Check | Evidence / result |
| --- | --- |
| Final source and active assets | 77/77 disk sources exactly match Studio after the last lifecycle fix; GUI_SOURCE_EQUALITY_PASS at 23:46:50.210. Final retired/temporary asset audit passed (20 recovery objects), 23:46:50.222. All 77 production sources and seven manual fixtures compile; git diff --check passes. |
| Responsive | VGA 640×422, HD720 1280×662, wide 1920×660 at UI scale 0.9/1/1.1 passed. Actual TextBounds/GUI bounds, eight relationship labels, six-action edge fallback, review/Military scroll and Back reachability checked. Compact heading overlap was reproduced, corrected and rerun at all VGA scales. These synthetic label/action checks are layout evidence, not new gameplay actions. |
| Existing settings | Actual GAME UI requests applied PanelOpacity 0.8/1 and scale variations; settings reset after matrix. Animations off/on, speeds 0.5/1/2 and rapid reopen passed without stale hiding or invisible input capture. |
| Lifecycle | Native Info→Back→radial, Military→Back, empty-map dismissal and drawer background blocking checked. Final Solo regression (including empty selection preserving Realm/Titles/Economy/Messages) passed at 23:45:22.269, 1280×662. Earlier compact Solo lifecycle passed at 23:20:36.527. |
| Native input | Radial buttons over neighboring provinces retain the selected Northvale; drawer background does not select beneath it. Dismissal restores wheel zoom and map dragging. Retired instances are outside StarterGui/PlayerGui. |
| Native conquest | Unclaimed review rejects fractional 1.5 without leaving review; 500 is accepted through existing SetCommit, Ready locks and normal battle resolves against 300 militia. Existing result reports 73 casualties/427 survivors, 927 total troops. No gameplay tuning. |
| Three-client Local Server | Actual Player1/Player2/Player3: 33/18/14 cumulative assertions (65 total). Own-holding context, simultaneous incoming fealty/Alliance priority, native Accept, marker cleanup, subject/Alliance/NAP relations, local war Battle workflow without Recruit, cancellation and disconnect cleanup passed. Native Break Alliance and War review→Confirm→commit observed; Enemy radial captured. No claim that the later native Enemy Battle click succeeded after the commitment deadline. |
| Authoritative match result | After third-client disconnect, existing service ownership changes trigger Domination. Both remaining clients pass Victory cleanup at 23:34:50.688, including context noninteraction, enabled Back and conditional Match Result. Native Inspect Final Map and Players work after match end. |

Manual fixtures are in docs/verification/gui-cleanup-*.luau and are never bootstrapped into production. The multiplayer result JSON records actual Output pass lines. Solo/final-regression/parity Output text and screenshots preserve observed evidence. Temporary test scripts and ContextVerification were removed before final save. See [map](../docs/verification/gui-cleanup-map-2026-10-10.png), [Military](../docs/verification/gui-cleanup-military-2026-10-10.png), [offers](../docs/verification/gui-cleanup-offers-2026-10-10.png), [enemy](../docs/verification/gui-cleanup-enemy-2026-10-10.png) and [Victory](../docs/verification/gui-cleanup-victory-2026-10-10.png).

Final offline place: docs/verification/gui-redundancy-final-v2-2026-10-10.rbxl, SHA-256 516D63B4D9F34035B7301CD8AFC53BF7A88AE93935DF36913CF8E2119D8BA2FC. This preserves the Studio-managed GUI, recovery assets and final source. It is locally ignored under the existing place-binary policy; the checked-in asset inventory documents the GUI contract. The prior final and pre-migration snapshots remain intact. Download a Copy saved the Studio draft as part of exporting; no Publish action was performed.

**Limits:** Director readability/feel and real-account Communications privacy/filtering are still outstanding; this cleanup does not claim those passes. Existing Kohl API/HTTP/DataStore-disabled warnings were not addressed by enabling settings. An installed Model To Pixel plugin reports a nil MainTextShadow error when stopping Play; it is outside project source. One temporary Victory fixture initially attempted Source writes from a normal Script (Plugin capability required); that fixture was corrected to install its observer through Studio Command Bar and then passed. This was a test harness error, not a production permission change.

## Intentional remaining overlap

Brief topbar resource summaries also have detailed global/context views; this supports at-a-glance reading and intentional drill-down. Province and Realm modes reuse one drawer, rather than simultaneous duplicate panels. Result toast/markers draw attention while the detailed result is requested separately. Realm is your hierarchy; Players compares all public rulers. No legacy territory, diplomacy or global military destination is retained.
