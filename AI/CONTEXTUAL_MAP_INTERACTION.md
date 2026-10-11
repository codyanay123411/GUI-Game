# Contextual map interaction and attention markers

Status: IMPLEMENTED — AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED. No Roblox publication.

## Architecture

`ContextActionResolver` derives presentation actions from read-only snapshots of existing services. `MapContextState` subscribes to their existing remotes. Territory selection feeds `ContextRadialController` and the single scrolling `MapContextController` workflow drawer. Permanent navigation and full Territory, Realm, Military, Diplomacy and Communications views remain available; automatic Territory/Military panel opening on ordinary map selection is demoted.

Studio owns `ContextRadialPanel`, `ContextWorkflowPanel` and `MapAttentionLayer` under `HierarchyPrototypeGui`. Buttons and markers are runtime children. These GUI assets require an offline place snapshot; filesystem scripts alone do not include them.

The resolver distinguishes personal ownership, direct subject/liege, greater realm, Alliance, NAP, active enemy, Unclaimed and distant/unrelated rulers. Direct eligibility comes from authoritative personal-border contacts; Council, Allies and targeted Diplomatic channels retain existing membership and range rules. No gameplay service or rule is changed.

War/Conquer first opens public target, relationship, troop availability, militia and constraint information. Confirm submits the existing declaration intent, then hands the initial amount to the existing Military commitment controller. Lock and battle resolution remain in that controller. Cancel returns to map actions without declaring war. Incoming offers, Realm Overview and Victory take presentation precedence.

`MapAttentionPolicy` chooses a ruler's personally owned province nearest the player's greater realm, preferring authored borders and breaking ties deterministically. `MapAttentionController` aggregates communication, incoming diplomacy, war and result events by province. War/result anchors use the actual target. Highest priority determines the glyph and total count is shown. Existing native communication receipt and acknowledgement events drive unread markers; no new message transport exists. Expiry, consumed requests, resolved wars and disconnected rulers clear corresponding events.

Programmatic selection carries an explicit workflow hint so deferred selection callbacks cannot reopen map actions over the intended Military, offer or Communications destination. Actual mouse routing verified that correction. Circular headings use short relationship labels; the drawer retains the full relationship description.

## Agent verification — 2026-10-10

- All 76 production Luau sources and four retained fixtures compile with Luau 0.740; `git diff --check` passes. All 76 production sources match Studio after normalizing line endings and mapping Script Sync's `init.luau` to its parent script. Temporary Solo/multiplayer executables were detached before saving the snapshot.
- Studio edit-mode pure policy fixture passed 31 assertions, including same-root adjacent Direct/Council and non-adjacent Council-only cases, Alliance/NAP war constraints, Unclaimed militia, local war relevance and deterministic marker aggregation/anchoring.
- Solo mouse flow opened Unclaimed conquest review without mutation, cancelled back to map actions, dismissed on empty map, declared with 500 troops, accepted that commitment in the existing Military workflow and resolved against 300 militia. Observed 444 survivors, 56 casualties, ownership transfer, released troop ledger and target result marker. Result marker expired after 20 seconds. Scrolling Military did not zoom the map.
- Clean three-client Local Server rerun passed baseline, incoming Alliance/Fealty offers, acceptance, independent/subject action distinctions, accepted NAP war blocking, communication aggregation, local war relevance and resolved-war cleanup. Player1 fixture reached 27 checks before repeat-message/disconnect exercises; Player2 reached 11 and Player3 reached 9. These are agent checks, not Director acceptance.
- Actual mouse clicks opened aggregated Northvale Allies messages, distant Highmarch Council messages and the Westmere defender Military workflow. Acknowledgement removed the respective marker and deferred selection did not reopen radial actions. Repeated messages recreated attention; scroll zoom and drag pan kept markers attached to their provinces.
- Disconnect removed the departed ruler's Highmarch attention after its authoritative snapshot arrived. The initial fixture's fixed 0.8-second check was premature; a normal running-client LocalScript subsequently asserted two rulers and no stale marker (`CONTEXT_DISCONNECT_PASS 2`). The retained fixture now waits for that snapshot. Command Bar requires use a separate module cache, so they were not accepted as runtime-controller evidence.
- VGA (640×480), HD720 (1280×720) and wide (1920×720) device profiles passed minimum/default/maximum UI and font scales (0.9/1/1.1). Actual ScreenGui heights exclude Roblox's topbar. Six-action geometry, heading overlap, screen bounds, text reflow and scroll-reachable Cancel were checked; additional short-height fallback passed. Final heading checks cover eight relationship labels with a nine-character province name.
- Final VGA mouse confirmation accepted and prefilled 500 troops in Military, then Ready resolved 500 versus 300 militia through existing mechanics. Clicking the resulting target tick opened Northvale Info and acknowledged it without reopening radial actions.
- Running-client priority checks passed all four suppression paths: Overview/Victory presentation flags and both incoming-offer overlays. This checks UI precedence; it does not claim a new full Domination regression test.
- During verification, corrected incoming-offer marker expiry assumptions: existing services send `os.clock` deadlines, so authoritative request-removal snapshots control marker expiry. No server clock or gameplay contract changed. Initial fixture setup/deferred-callback mistakes were corrected before the clean rerun.

## Source and Studio assets

New sources: `Shared/Util/ContextActionResolver`, `Shared/Util/MapAttentionPolicy`, and client `MapContextState`, `MapContextController`, `ContextRadialController`, `MapAttentionController`. Integration changes: client Bootstrap, TerritoryMap, StrategyPresentation, Military, Communications, Diplomacy and PoliticalHierarchy controllers. Server services and gameplay configuration have no diff. Four reproducible fixtures live under `docs/verification/context-*.luau`; none is started by a production bootstrap.

Studio GUI assets are `HierarchyPrototypeGui.ContextRadialPanel` (Frame, Heading), `ContextWorkflowPanel` (ScrollingFrame, Heading, Body, CommitAmount, Actions, CancelButton), and `MapAttentionLayer` (nonblocking Frame with individually blocking markers). Runtime buttons use the existing theme and audio settings. Full panels/navigation remain; only automatic map-selection panel opening is demoted. Offline snapshot saved through File → Download a Copy: `docs/verification/contextual-map-final-2026-10-10.rbxl` (753,016 bytes; ignored binary, local only). Roblox publication was not invoked.

## Known limits and next milestone

Synthetic successful Communications receipts verify attention presentation only. Native real-account peer delivery, filtering, privacy and Observer behavior remain distinct outstanding Communications checks. Studio's existing Kohl datastore/API-disabled warnings were observed; security/API settings were not changed. No new persistent notification store or transport is introduced.

Director acceptance remains pending for action discoverability, readability, notification density and overall game feel. Nearest ruler anchor uses authored borders, then centroid proximity and stable ID; a ruler with no personally held land has no province marker. Existing offers/toasts/full views remain accessible. An already declared war retains its existing cancellation/commitment rules; drawer Cancel is a pre-declaration navigation action.

Next milestone recommendation: Director playtesting of map action discoverability and attention density, followed by real-account Communications checks before serious multiplayer playtesting. Do not infer gameplay acceptance from agent presentation checks.
