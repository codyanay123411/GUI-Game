# Creator game presentation settings

Implemented 2026-10-10. AGENT-VERIFIED; Director acceptance remains pending. Presentation/audio only; no gameplay or balance changes and no Roblox publication.

## Installed Kohl inspection and extension

Inspected the actual installed Kohl v0.17.0 Settings, UI, Theme, client source, default theme, Slider, Select and List modules before implementation. The running project theme resolves to GothamSSm, family rbxasset://fonts/families/GothamSSm.json. This was verified from the live FontFace, rather than inferred from the screenshot. Game defaults preserve that font independently of Kohl's personal APPEARANCE settings.

Kohl supports addon modules ([official addon documentation](https://github.com/kohls-admin/kohls-admin/blob/master/docs/custom_commands.mdx)), but this installed version has no supported custom Settings-category registration API. Project-owned GamePresentationKohlClient uses the existing addon delivery mechanism and Kohl's UI constructors/reactive state. It appends two native List categories to dashboard.Settings._scroller and observes dashboard.Settings._input._input for search. These two version-sensitive handles are isolated and guarded in the adapter; unsupported handles warn and leave game defaults active. A dashboard-instance mount attribute prevents duplicate categories when multiple addon containers invoke the adapter. No generated/vendor Source was changed or forked.

Kohl's ADMIN/APPEARANCE controls, Theme/Font/Font Mono/Font Size/Corner Radius/Padding and savedSettings flow remain Kohl-owned. The game never writes K.Data.savedSettings, never changes Kohl's personal theme to apply a game setting, and never stores global values in a user's Kohl preference record.

## Settings and safe ranges

| GAME UI setting | Default | Allowed values |
| --- | --- | --- |
| Font | GothamSSm | GothamSSm, SourceSansPro, Roboto, Arial |
| Font Size Scale | 1 | 0.9–1.1 |
| UI Scale | 1 | 0.9–1.1 |
| Corner Radius | 8 | 0–16 pixels, scaled with UI density |
| Padding / Spacing | 10 | 6–12 |
| Background Strength | 1 | 0.85–1 |
| Panel Opacity | 1 | 0.8–1 |
| Animation Speed | 1 | 0.5–2 |
| Province Labels | On | On/Off |
| UI Animations | On | On/Off |

| GAME AUDIO setting | Default | Allowed values |
| --- | --- | --- |
| Master UI Volume | 50% | 0–100% |
| Interface Sounds | On | On/Off |
| Hover Sounds | Off | On/Off |
| Notification Sounds | On | On/Off; also gates error notifications |
| Interaction Volume | 60% | 0–100% |
| Notification Volume | 60% | 0–100% |
| Warning / Error Volume | 60% | 0–100% |

Sliders and numeric entry share validated values. Fonts preserve authored weight/style; typography and spacing retain information hierarchy. UI Scale adjusts safe typography/navigation/drawer/row density instead of scaling the full viewport and breaking anchored layout. Rounded circles retain their scale-based corners. Animation settings affect short button hover transitions. Province-label visibility still obeys existing camera eligibility. Runtime-created descendants receive current tokens; source templates retain authored base styles to prevent double scaling.

## GUI component contract

Current game visual language: slate panels/wells, warm primary text, muted supporting text, gold actions, red destructive actions, and restrained borders/corners. `ReplicatedStorage/Shared/Util/PrototypeGuiTheme.luau` is the token/component authority; layout remains with existing controllers. Inspect the live game before changing its UI. Reuse helpers rather than copying colors or building another GUI framework.

| Component | Existing helper / pattern | Responsibility |
| --- | --- | --- |
| Panel / urgent offer | `applyPanel(panel, urgent?)` | Slate surface; gold urgency border when purposeful. Keep scrim/modal and input flags owned by controller. |
| Action / destructive action | `applyPrimaryButton(button, enabled)` / `applyDangerButton(button)` | Gold/red versus disabled tokens, wrapped text; caller owns Active/validation. |
| Navigation / Back / Help / close | `applySecondaryButton(button, enabled)` | Well/text tokens; selection/relationship rows keep their semantic controller colors. |
| Input | `applyInput(textBox)` | Well, readable text/placeholder, border/corner; caller owns TextEditable and validation. |
| Scroll / text | `applyScroll(scroll)` / `applyText(label, Heading/Body/Caption)` | Shared scrollbar and text hierarchy; caller owns measured content/canvas geometry. |
| Dynamic admission | `StyleControl(instance)` through Strategy/GameSettings descendant hooks | Inputs, scrollbars and tagged/named buttons follow the same component style before settings capture base values. Templates stay unscaled; clones receive current presentation. |

Use `ThemeRole` for component semantics, not authorization. Preserve useful state colors, map political/selection/eligibility colors, nonblocking decoration, circular corners and modal scrims. Gold urgent offers, victory emphasis, red errors/hostile relations, map label contrast and compact captions are purposeful exceptions; document new exceptions here. Native Roblox chrome and vendor Kohl controls retain their own infrastructure; project Kohl theme/settings adapter is their integration boundary, not a vendor fork.

Verify changed surfaces beside established screens at normal/compact desktop sizes, including dynamic rows, reopened workflows, empty/disabled/error states and current supported settings. Measure/reflow long text and make controls scroll reachable. Do not hardcode applied font/density values back into base settings or scale templates twice. GothamSSm means `rbxasset://fonts/families/GothamSSm.json`; do not silently substitute a different default family. Static style/compilation checks supplement runtime/visual evidence.

## Authority, replication and persistence (service contract)

GameSettingsService owns cloned defaults, authoritative runtime values and monotonic revisions. GameSettingsRequestEvent accepts Ready, Set and category Reset; the server uses the actual Player.UserId and rechecks AdminConfig.CanConfigureGame for every mutation. Unknown keys/actions, wrong types, NaN/infinity, invalid fonts and out-of-range values are rejected. Requests are throttled per player, with cleanup on leave. The controller coalesces drag updates and serializes resets; a reset cancels unsent edits for that category.

The explicit project owner and actual experience creator may configure. For group experiences, only Kohl's trusted server-resolved creatorId is used. SuperAdmin/GameTester access allows viewing, not editing; ordinary players have no category admission. Client-supplied ranks, owner flags/UserIds and attributes grant no authority. Role changes refresh UI admission, independently of mutation validation.

Sanitized snapshots replicate to all clients, including late Ready requests, so presentation is server-wide. GameSettingsController applies values through PrototypeGuiTheme and GuiSounds; gameplay controllers do not read Kohl. Creator-only category resets require a second click within five seconds.

No suitable game persistence infrastructure exists in this checkout. This pass deliberately uses runtime-only state with source defaults: a new server starts from defaults. Kohl Use Saved Settings remains personal Kohl behavior. Future persistence requires a separate game-owned, versioned global-settings record with validated load/save, creator authorization, failure handling and an explicit multi-server update policy. No DataStore or Studio API setting was enabled for this task.

## Reused audio

Game-owned SoundGroup GameGuiSounds isolates game audio from Kohl. Assets were inspected in the installed sound set, copied as IDs into the semantic layer, preloaded and verified loaded with positive duration. Master and semantic group volumes combine; disabled flags suppress playback. Short semantic debounces avoid bursts.

| Semantic sound | Roblox asset ID |
| --- | --- |
| Click | 10128760939 |
| Select | 10066968815 |
| Open | 10128766965 |
| Close | 10066914500 |
| Confirm | 17208209318 |
| Hover | 17208339919 |
| Error | 17208353912 |
| Notification | 17208372272 |

Central wiring covers active game buttons, opening/closing panels, territory selection, offers, result toasts, Victory and admin feedback. Hover is off by default. This pass adds no music or gameplay audio.

## Files and integration

New source: Shared/Config/GameSettingsConfig, Shared/Util/GuiSounds, Services/GameSettingsService, Services/GamePresentationKohlClient and Controllers/GameSettingsController. Existing changes: PrototypeGuiTheme, AdminConfig/AdminService, both bootstraps, StrategyPresentationController, RealmOverviewController, TerritoryMapController, AdminFeedbackController and CommunicationsController. Communications/admin text reflows on live font/size changes; existing transport, gameplay authority and actions are unchanged. GUI assets remain Studio-managed; StrategyBackground is a noninteractive runtime game frame.

## Verification

All 70 project Luau sources compile with Luau 0.740; git diff --check passes. Final comparison confirms all 15 changed/new production sources match Studio, both existing bootstrap classes are preserved, and temporary verification executables are removed from the active place.

Temporary verification scripts and captured output/screenshots are preserved under docs/verification/game-presentation-*. Scripts are evidence/reproduction fixtures, not production bootstraps.

- Normal server Script: 161 assertions passed for all settings, numeric limits/defaults, malformed values/keys/actions, owner admission, trusted SuperAdmin tester-only access, preserved explicit tester IDs, ordinary denial, reset and snapshot-copy isolation.
- Normal owner client LocalScript: final 99 assertions passed using actual request remotes and server acknowledgements. All four fonts, live values, dynamically cloned rows, template/base scaling, labels, opacity/background, eight loaded sound assets, playback/mutes/volumes and queued-edit reset were covered.
- Real Local Server with three clients: all 17 values matched at minimum/maximum/default snapshots; all clients were read-only, with one category of each type. Real client Set/Reset spoof requests carrying owner/rank/attribute claims left server revision and values unchanged. See multiplayer output.
- Ordinary admission projection: because synthetic Studio negative IDs intentionally count as GameTesters, a temporary server-only IsGameTester projection made one real client ordinary. Its categories hid and real spoof requests were denied; the projection was restored. Visibility checks wait for the reactive UI frame. This is not a published ordinary-account test.
- Native Kohl controls: live province toggle and game Corner Radius 8→12 worked while Kohl APPEARANCE stayed at 8; reset worked. Search matched both native/game corner rows and game audio rows, scrolling worked, and Commands/Bans/Members/Servers/Logs/Settings/About loaded. Creator rank and existing GameTester help worked. Personal Kohl appearance preview remained separate and was canceled without saving.
- Visible Realm Overview rows resize on theme changes; the targeted live-density fixture passed 0.9/1.1/default without closing/reopening the overlay.
- Responsive min/max/default checks: VGA 640×480, HD720 1280×720 and custom wide 1920×720. Actual usable ScreenGui dimensions exclude Roblox topbar inset; output records those exact dimensions. Each profile checks navigation text/bounds, drawers/buttons, long Communications canvas, generated Realm Overview row text, long Victory text and real adminhelp result canvas.

Existing disabled Studio API/HTTP warnings prevent backend verification of Kohl saved preferences. The unrelated Model To Pixel plugin reports MainTextShadow on session stop. Neither warning was addressed by changing security settings or vendor code. Subjective font/audio feel, a real published ordinary account and live group-creator resolution remain Director/playtest verification; no agent test is Director acceptance.

## 2026-10-13 component follow-up

Shared helper/descendant admission now covers authored and generated ordinary game controls without changing permissions. Final owner runtime checks exercised all four fonts, 0.9/1.1 font/UI density and 0.8 opacity at VGA/HD720, then reset defaults; native GAME UI/GAME AUDIO categories were inspected. Synthetic multiplayer clients retained `canConfigure=false`. Measured Titles/map captions fixed observed clipping. Full current scope/evidence and semantic exceptions are recorded in [GUI_UX_SPRINT.md](GUI_UX_SPRINT.md#playable-match--gui-consistency-milestone--2026-10-13); older settings verification retains its date/scope. Director visual/audio approval and published-account limitations remain.

### Commitment bar admission — 2026-10-13

The dynamically created CommitmentBar uses existing Caption text roles, theme stroke/gold/disabled colors and settings admission in existing drawers. One active Frame blocks map input; its five labels are not independent preset buttons. Retired numeric commitment controls are hidden/inactive; recruitment input remains unchanged. [Verification](GUI_UX_SPRINT.md#rank-gold-bonuses-and-fixed-stop-commitments--2026-10-13).

### Political council section — 2026-10-13

Dynamic CouncilHeader/Body inside Realm use shared Caption/Body roles with left-aligned text. StrategyPresentation measures council/current-ruler height and width within scrollbar margins; existing outer Realm scrolling handles five-seat own/direct-liege councils on compact desktops. No new screen, color exception, numerical authority display or interactive permission control. Theme/layout evidence is in AI/OPENFRONT_PLAYABILITY_REVIEW.md's political foundation section.

### Recruitment bar admission — 2026-10-13

Military's recruitment surface reuses CommitmentBar with its own25/35/50/75/100 stops; default commitment choices are unchanged. Caption, measured existing CostLabel, primary Recruit and outer scroll follow existing theme/settings/input guards. Numeric/Max instances remain hidden and disabled for recovery. No separate progression or recruitment panel. [Evidence](GUI_UX_SPRINT.md#fixed-stop-affordable-recruitment--2026-10-13).
