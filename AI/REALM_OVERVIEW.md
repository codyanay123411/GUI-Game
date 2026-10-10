# Realm Overview — 2026-10-10

**IMPLEMENTED — AGENT-VERIFIED — NOT DIRECTOR-ACCEPTED.** Director explicitly authorized a custom political player list and hold-Tab input. This is presentation only; existing gameplay authorities and Communications eligibility remain unchanged. No commit, push or publication.

## Behavior and architecture

Hold Tab opens the centered slate/gold overview; release closes it, including processed release events. Typing/focused TextBoxes suppress opening. Losing window focus closes it; focusing a TextBox while holding Tab also closes it. The Players navigation button opens the same view with an explicit Close button for nonkeyboard access. Closing restores the previously selected system drawer.

RealmOverviewController disables only `Enum.CoreGuiType.PlayerList` through supported StarterGui controls. Failed initialization has a bounded retry, and CharacterAdded reapplies the setting and closes the overview. Chat, Backpack and unrelated CoreGui are untouched. ResetOnSpawn remains false. Start is guarded; opening never creates another subscription set.

RealmOverviewView creates an allowlisted projection of connected Players and existing local snapshots. No new remotes, services or political authority. RealmOverviewController subscribes to State events from Hierarchy, Territory, Diplomacy, Warfare and Communications, sends their existing Ready handshake once, and batches refreshes with task.defer. PlayerAdded/PlayerRemoving and viewport changes also refresh. Rows are keyed by UserId, reused on updates, and destroyed on departure. There is no per-frame polling.

| Displayed field | Existing source / visibility boundary |
| --- | --- |
| Display name, username, local-player marker | Connected Roblox Players |
| Title/rank, independent or subject, liege, root, liege indicator | Public Hierarchy State; direct-subject count only supplies the Liege indicator |
| Personal holdings | Public Territory owners counted for this ruler |
| Greater-realm holdings | Public owners mapped through current Hierarchy root; unclaimed land excluded |
| Alliance/NAP/war relation | Existing diplomacy agreements and wars, projected only against the local player's root |
| Direct availability | Existing Communications contacts for the local player; no new eligibility calculation |
| Diplomacy relevance hint | Existing independence/root metadata; informational, no action intent |

Gold, Troops, commitments, battle rolls, Prestige, pending requests, observer identity envelopes and admin data are not projected or displayed. Missing initial snapshots show awaiting-state labels / em dashes. Detail rows are informational; no political action is performed.

The default Realm sort orders independent rulers first, then descending rank, descending greater-realm holdings, display name, username and UserId. Title sorts descending rank, Territory descending personal holdings, Name by name; each uses deterministic name/UserId fallbacks. Flat sorting avoids fragile hierarchy grouping. Relationship priority is You, Your liege, Your subject, Your realm, At war, Ally/NAP, Ally, NAP, Unrelated. Details show separate Alliance/NAP/War fields even when the primary relation is hierarchical.

## Source and Studio assets

- New `ReplicatedStorage/Shared/Config/PresentationBindings.luau`: Director-authorized temporary HoldRealmOverview = Tab. Settings/remapping remain future work.
- New `ReplicatedStorage/Shared/Util/RealmOverviewView.luau`: public projection and sorting.
- New `StarterPlayerScripts/Controllers/RealmOverviewController.luau`: CoreGui lifecycle, event subscriptions, keyed rendering, detail and responsive layout.
- Changed `StrategyPresentationController.luau`: Starts Overview, central Tab/focus handling, Players navigation and underlying-navigation guard.
- Changed `TerritoryMapController.luau`: overview blocker recognition; rejects press/wheel and cancels in-progress pan when overview opens. Map geometry, camera math and ownership rules unchanged.
- Bootstrap.local remains the existing entry point; presentation starts after gameplay controllers and starts Overview internally; VictoryController starts afterward.

Studio-only assets under StarterGui.HierarchyPrototypeGui: `RealmOverviewOverlay` (fullscreen active dim blocker), `Panel` with Header, Subtitle, Close, Sorts (Realm/Title/Territory/Name plus horizontal UIListLayout), Columns, List (ScrollingFrame with UIListLayout / AutomaticCanvasSize Y), Detail; `Templates.RealmOverviewRow` (TextButton with Accent, Identity, Username, Politics, Realm, Holdings, Relation); and `StrategyNavigation.Players`. Navigation canvas extended to accommodate Players.

Panel width is capped at 1120 with 16px margins. Below 720px panel width, rows become 94px stacked cards and relationship moves into the username line; desktop rows are 74px with five columns. Selected details reserve a wrapped footer. Map/nav stay blocked while open; incoming priority requests, admin and transient toasts retain their existing higher visual layers.

## Agent verification

Tests ran in Studio Solo and an actual three-client Local Server. Temporary verification scripts, political fixtures and diagnostic rows existed only in running test sessions; they were discarded when sessions ended. Evidence is in `docs/verification/realm-overview-*`.

| ID | Result and evidence |
| --- | --- |
| ROV-01 | PASS: native Tab press produced visible=true then visible=false; 20 repeated press/release cycles and actual character respawn left one player row, closed overlay and default PlayerList disabled. `realm-overview-lifecycle.jpg` |
| ROV-02 | PASS: focused Communications TextBox retained its draft and Tab did not open overview; no message sent. Window-focus loss closed it. `realm-overview-typing-focus.jpg` |
| ROV-03 | PASS: overview intercepted underlying nav/map click, drag and wheel with unchanged selection, camera and navigation; closing restored zoom and territory selection. `realm-overview-input-results.jpg`; Output markers OVERLAY_BLOCKS_REPEAT true true true / MAP_RESTORED true true |
| ROV-04 | PASS: 12 pure-projection scenario groups covered sorting, missing snapshots, connection filtering, holdings/root changes, Direct revocation and excluded private fields. `realm-overview-projection-checks.txt` stores the replay command; Output OVERVIEW_PROJECTION_CHECKS_PASS 12 |
| ROV-05 | PASS: real Local Server clients appeared as 2 then 3 rows; local player correctly highlighted. Actual title change, Alliance + NAP acceptance and declared war rendered. `realm-overview-mp-two.jpg`, `realm-overview-mp-relations.jpg`, `realm-overview-mp-detail.jpg` |
| ROV-06 | PASS: cancellation/breaks cleared relationships; fealty updated both views, personal 2 / realm 3 on liege and personal 1 / realm 3 on subject. Independent-before-subject sort observed. `realm-overview-mp-hierarchy-result.jpg`, `realm-overview-mp-subject-result.jpg` |
| ROV-07 | PASS: outsider view remained Unrelated; PlayerList false, Chat true, Backpack true on subject. `realm-overview-mp-outsider-result.jpg`, `realm-overview-mp-subject-result.jpg` |
| ROV-08 | PASS: selected opponent disconnect removed its row and cleared details; liege disconnect made remaining subject Independent with personal/realm 1. `realm-overview-mp-disconnect-result.jpg`, `realm-overview-mp-independence-result.jpg` |
| ROV-09 | PASS: same-root adjacent liege/subject detail displayed Direct Available; moving subject's personal holding to nonadjacent Brightfen changed it to Unavailable without losing subject status. `realm-overview-direct-revoked.jpg`, `realm-overview-direct-result.jpg` |
| ROV-10 | PASS: 50-row projection plus a rendered 50-row diagnostic list scrolled to CanvasPosition Y=1333; canvas Y=3994/window Y=309. Diagnostics removed afterward. This is UI scalability verification, not 50 real clients. `realm-overview-50-row-scroll.jpg`, `realm-overview-scroll-result.jpg` |
| ROV-11 | PASS: VGA preset actual GUI 640x422, panel 608x390, list 576x230; compact rows and selected detail readable. Native wider multiplayer window also rendered columns and details. `realm-overview-small.jpg`, `realm-overview-small-detail.jpg`, `realm-overview-mp-hierarchy.jpg` |
| ROV-12 | PASS: HD720 1280x720 preset, actual inset GUI 1280x661, panel 1120x629, selected-detail list 1088x389. Name sort activation, rows and wrapped detail rendered. `realm-overview-hd720.jpg`, `realm-overview-hd720-detail.jpg`, `realm-overview-hd720-output.txt` |

## Limits / acceptance

Director visual acceptance remains outstanding. Automation emitted Tab down/up together, so the callback transition and repeated lifecycle were verified; sustained physical hold feel should be checked by the Director. Physical mobile/touch and gamepad were not tested (Players button supplies the nonkeyboard entry point). No 50-real-player/network-load test. Existing Kohl Studio API/DataStore warnings and Model To Pixel plugin errors occurred independently; no overview production runtime error remained after repairs. A temporary fixture assertion using a nonexistent child name was corrected for subsequent probes; it is not counted as a pass.

Earlier recovery archives, Communications snapshots and GUI sprint snapshot remain preserved. Five final Studio sources matched disk and static assets passed the edit-mode integrity probe (REALM_OVERVIEW_FINAL_INTEGRITY_PASS 5; realm-overview-final-integrity.jpg). git diff --check passed. Sources are saved on disk and GUI assets remain in the open Studio place. The dedicated Overview export attempt initially failed to activate its save dialog. This limitation was subsequently superseded by the successfully saved full-project snapshot `docs/verification/conquest-victory-2026-10-10.rbxl`, which includes Realm Overview. The dialog has been closed. Creation/sync commands are preserved as realm-overview-create-assets.txt / realm-overview-sync.txt for recovery. Earlier snapshots were not overwritten.
