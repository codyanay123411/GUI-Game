# Strategy admin command audit — 2026-10-11

**IMPLEMENTED — AUTOMATICALLY CHECKED — STUDIO SOLO TESTED — NOT DIRECTOR-ACCEPTED.** This scoped audit does not change gameplay, AdminConfig access, competitive lifecycle or prior acceptance records. No commit, push or Roblox publication is authorized by this task.

## Coverage and inventory

The starting main was clean at `ebe10389ef59128290914743b04f38d93e236f05`. Git contains project services, addons, loader and shared configuration, not the whole place or generated vendor code. Before applying edits, the three live admin service sources matched that Git baseline. Read-only inspection covered live Kohl Config/Addons, auto-update settings, installed Auth/Registry and all nine default command modules. The inspected place reports PlaceId 77421850892463, PlaceVersion 145, AutoUpdate=true, Legacy=false. These cloud metadata values do not prove the unsaved local place is published/current in Roblox.

Installed edit sources contain 262 named vendor definitions. Studio runtime exposes **302 canonical definitions**: those 262, 24 project commands (21 existing + 3 new), and 16 dynamically registered role/custom-command definitions. Aliases resolve to their canonical definitions and are checked separately. Existing Example addons, theme addon and GAME UI/GAME AUDIO integration remain; the latter is a settings surface, not additional game-state commands. Detailed command descriptions, aliases, classification reasons, installed-source hashes and effective runtime names are in [the inventory](../docs/verification/admin-command-inventory-2026-10-11.json). Read-only vendor captures/compiler remain ignored under tmp/admin-audit.

Before updating live configuration, old admin sources and the entire Kohl Config were preserved under `ServerStorage.AdminCommandRecovery_20261011`; clone tags were removed so recovered configuration cannot register addons. Temporary verification Scripts are archived there disabled. Existing snapshots/recovery assets were preserved. Final local-only snapshot: `docs/verification/admin-command-audit-2026-10-11.rbxl`, saved through Download a Copy after four-source/live-addon equality and disabled-fixture cleanup (763,519 bytes; SHA-256 in the inventory). It captures this edit-mode state and inactive recovery, not published runtime/account freshness. Older saved snapshots predate this audit and cannot establish its final coverage. External auto-updated assets, published accounts, data stores and future vendor versions remain outside this pass.

## Recoverable cleanup

155 explicit names and their aliases are disabled by `AdminCommandPolicy`; 107 other vendor definitions and dynamic authorization/help definitions remain under their original permission rules. Policy follows inspected behavior/dependencies, not blanket group disabling. Character physics/effects, avatar/accessories, physical item spawning, terrain physics and Roblox Teams/leaderstats mutations do not operate this strategy game's authoritative systems.

The project addon uses supported Registry definition overrides with harmless disabled handlers, retaining initialized environments needed by other commands. It wraps registration for later replacements of known names and adapts Auth.hasCommand on server/client to deny those definitions, including creator access. Installed Kohl's creator/admin fast paths bypass ordinary per-role denial, so role configuration alone would not disable them. Vendor MainModule source and ranks are unchanged. Runtime original definitions are retained in `_strategyCommandPolicy.archive`; the unchanged vendor and pre-edit snapshot also provide recovery. To restore a selected command, remove its explicit policy entry and restart with synced source; do not hot-enable archived code during a match.

Auto-updates remain enabled. Known names stay restricted when registered again; newly added/renamed commands retain vendor permissions pending another behavior audit. Future Registry/Auth compatibility is unverified. This policy governs command execution, not arbitrary privileged server scripting; retained creator script tools retain their existing powers. Existing initialized dependencies/remotes are not casually removed.

| Vendor group | Disabled canonical names | Retained canonical names |
| --- | --- | --- |
| Administration | `gear`, `insert` | `announce`, `place`, `removemember`, `role`, `serverlock`, `temprole`, `unannounce`, `unrole`, `unserverlock` |
| Creator |  | `clearlogs`, `hidelogs`, `localscript`, `script` |
| Environment | `airdensity`, `gravity`, `watercolor`, `waterreflectance`, `watersize`, `waterspeed`, `watertransparency`, `winddir`, `windspeed` | `ambient`, `atmosphere`, `brightness`, `colorshift`, `diffusescale`, `exposure`, `fix`, `fogcolor`, `fogend`, `fogstart`, `latitude`, `outdoorambient`, `shadows`, `skybox`, `specularscale`, `time` |
| General | `clip`, `fly`, `link`, `noclip`, `notrip`, `title`, `unfly`, `unlink`, `watch`, `xray` | `clean`, `countdown`, `fullmessage`, `grouprank`, `hint`, `message`, `notify`, `pause`, `pitch`, `play`, `playercount`, `privatehint`, `privatemessage`, `resume`, `spectate`, `stop`, `tts`, `unspectate`, `volume`, `vote`, `whois` |
| SuperAdmin | `btools`, `clearterrain` | `badge`, `chat`, `explorer`, `global`, `incognito`, `incognitolist`, `reserve`, `shutdown`, `unreserve` |
| Utility | `emote`, `emotes` | `about`, `age`, `cmdbar2`, `commandbar`, `commands`, `dashboard`, `donate`, `gameid`, `jobid`, `log`, `ping`, `placeid`, `prefix`, `rejoin`, `serverage`, `settings`, `showfps`, `version`, `viewas`, `wait` |
| Fun | `char`, `clone`, `confuse`, `control`, `creeper`, `dog`, `explode`, `fling`, `glitch`, `infect`, `loopfling`, `noobify`, `nuke`, `poison`, `rocket`, `seizure`, `setgravity`, `size`, `skydive`, `slim`, `slippery`, `smite`, `spin`, `trip`, `unchar`, `uncreeper`, `undog`, `unseizure`, `unspin` | `disco`, `jumpscare` |
| VIP | `bodycolor`, `bundle`, `cape`, `crm`, `crowncolor`, `face`, `fire`, `goldify`, `hat`, `head`, `headless`, `headsize`, `highlight`, `korblox`, `light`, `normal`, `pants`, `particle`, `rainbowcrown`, `rainbowwings`, `removehats`, `shine`, `shiny`, `shirt`, `silverify`, `smoke`, `sparkles`, `swagify`, `trail`, `tshirt`, `uncape`, `unfire`, `ungoldify`, `unlight`, `unparticle`, `unsmoke`, `unsparkles`, `unswagify`, `untrail`, `vampire`, `werewolf`, `wingscolor` |  |
| Moderation | `bring`, `cameraoffset`, `change`, `clearteams`, `collide`, `copytools`, `createteam`, `editteam`, `forcefield`, `freeze`, `give`, `heal`, `health`, `hidename`, `hurt`, `immortal`, `invisible`, `jail`, `jump`, `jumppower`, `kill`, `lock`, `loopkill`, `punish`, `r6`, `randomizeteams`, `refresh`, `removearms`, `removelegs`, `removelimbs`, `removeteam`, `resetstats`, `respawn`, `showname`, `sit`, `slopeangle`, `speed`, `startergive`, `starterjumppower`, `starterremove`, `starterslopeangle`, `starterspeed`, `stun`, `substitute`, `sword`, `team`, `teamrespawn`, `thaw`, `to`, `tp`, `unforcefield`, `unjail`, `unlock`, `unpunish`, `unsit`, `unstun`, `vehiclespeed`, `vehicletorque`, `visible` | `antilag`, `ban`, `bans`, `blind`, `buy`, `crash`, `fov`, `fps`, `has`, `join`, `kick`, `members`, `mute`, `name`, `promptgroup`, `removetools`, `servers`, `setcoregui`, `startertools`, `toolban`, `tools`, `unban`, `unblind`, `unmute`, `untoolban`, `viewtools` |

Mixed-use tools retained deliberately: `name` updates shared display identity as well as a character label; `spectate` offers camera inspection; `toolban`, `removetools`, `tools`, `startertools`, `viewtools` provide moderation/inspection, while give/spawn actions stay disabled. `clean` also clears presentation effects/countdown. Lighting/disco, audio, FOV/CoreGui and performance/settings tools support presentation or have mixed uses. Roblox/platform utilities and dangerous moderation/server tools retain existing restrictions; ban/kick/shutdown/crash were not exercised against accounts. No extra power is granted by retaining a definition.

## New commands and help

| Command | Purpose and restrictions |
| --- | --- |
| `;inspectrealm <player name, UserId or rulerId>` | Read root, member personal holding counts, all realm holdings and conquerable Domination progress. Uses hierarchy/map snapshots and existing Domination evaluator; available after match end. |
| `;checkledgers` | Read all current troop totals/availability/reservations, individual nonnegative whole reservations and territory ownership indexes. Reports concrete failures; no repair/mutation. Before ruler initialization reports unavailable. This snapshot check is not a full gameplay certification. |
| `;seedbattle <integer 0..2147483647 or clear>` | Explicit DEBUG-only setup through MilitaryService.DebugSetSeed for repeatable future battle RNG. Same seed/input reproduces rolls; no rewriting resolved outcomes. Clear restores normal randomness. Runtime only; rejected after match end. |

All three use the existing addon → AdminBridge.Execute → authoritative APIs and central GameTester rule (allowlisted UserId OR trusted effective SuperAdmin+). No client mutation remote, hidden ordinary-player data, rank change or freeze override was added. Seed errors are validated before calling Military. Invalid inspectterritory IDs now fail cleanly instead of appearing unclaimed.

Admin help identifies setowner as a conquest-bypassing test override that can trigger Victory, resolvewar as a pre-mechanical-resolution combat override, and checkvictory as normal evaluation that can end/freeze the match. Inspections remain post-match; competitive mutations and seed changes remain blocked. Existing creator-only GAME UI/GAME AUDIO editing is unchanged; SuperAdmins/GameTesters view those settings without acquiring creator configuration access.

## Verification and remaining work

Final Studio Solo: **ADMIN_POLICY_SERVER_PASS 1080 155**, **ADMIN_POLICY_CLIENT_PASS 155**, **ADMIN_POLICY_REMOTE_PASS 4 0**, **ADMIN_PIPELINE_PASS 0**, at approximately 07:10 local time. Server ranks and owner allowlist were temporarily mocked only for denied-request tests and restored. Four actual owner-client Kohl requests, treated server-side as unauthorized and carrying spoofed client attributes/rank/UserId arguments, never reached AdminBridge. This is one real client plus server mocks, not multi-account/multiplayer acceptance.

Checks cover creator/SuperAdmin/ordinary disabled admission and aliases, harmless fallback handlers, new-command permission/Bridge denial, invalid ruler/territory/seed, accurate realm counts, real ledger success, injected troop/negative-reservation/ownership-index failures, deterministic combat utility results, actual seed set/clear API, and synthetic ended-match mutation denial with inspection allowed. Normal server-script Kohl pipelines passed for adminhelp, new commands, version, mute/unmute and FOV; fly/kill/nograv were rejected. Settings API retained owner-only admission. Native GAME UI/GAME AUDIO mount was observed. Four production modules and two fixture files compile using official Luau 0.740; whitespace/diff reviewed. Compiler success is syntax/bytecode compilation, not a full static type analysis.

**Known retained-vendor limitation:** mute/unmute changes TextSource.CanSend, but its existing client notification assumes default RBXSystem and emits a nil DisplaySystemMessage error in this custom-channel game. No default channel was reintroduced and no generated vendor source patched. Notification integration needs a supported upstream/addon fix; it is not a clean end-to-end moderation pass. Persistent ban/kick/server tools and every mixed-use command were not executed. Existing Studio DataStore-disabled and unrelated plugin Output errors do not prove published service behavior.

Replay [server checks](../docs/verification/admin-command-policy-checks.luau.txt) as a temporary normal server Script after bootstrap and [client checks](../docs/verification/admin-command-client-checks.luau.txt) as a temporary LocalScript in the same Solo run; both expect the owner client and must not ship active. Command-bar require uses a different cache/shared context and cannot substitute for these scripts. Early attempts had fixture-only inconsistent freeze mocks and a prematurely restored asynchronous permission mock; corrected final fixtures passed. No exhaustive historical gameplay suite was rerun.

**NOT TESTABLE IN CURRENT ENVIRONMENT:** published real accounts/persistence and future auto-update behavior. **DIRECTOR VERIFICATION REQUIRED:** command UX and the retained mute notice limitation. Next step: try adminhelp/inspectrealm/checkledgers/seedbattle and verify live-account moderation during the authorized playtest. Existing acceptance stamps below remain historical and unchanged.

# GameTester permission update — 2026-10-10

The Director explicitly authorized this admin/testing policy change, its commit, and a normal push to main. No gameplay mechanics, permanent Kohl ranks, or Roblox publication changed. Agent verification does not add Director acceptance to other systems.

## Authorization

`AdminConfig.IsGameTester` is the authoritative server decision: explicit GameTester UserId OR effective trusted Kohl rank at least the configured `Data.roles.superadmin._rank`. The lookup uses the existing server `shared._K_INTERFACE.Auth.getRank`, with server-context, type and threshold validation; missing/failing Kohl lookup denies the rank alternative. The allowlist remains usable without Kohl. Creator's effective highest rank qualifies.

| UserId | Account | Change |
| --- | --- | --- |
| 106676397 | Existing Director/owner | Retained |
| 2646795710 | ffrjfss | Added |
| 701857 | coolguy2323 | Added |
| 470733 | iceboy10 | Added |
| 555636491 | nooblyklll | Added |

Lower ranks and ordinary players remain denied unless explicitly allowlisted. Studio-only synthetic negative UserIds remain a testing convenience, never production allowlist entries. The existing server-only `AdminDebug.Invoke` nil-actor fallback is preserved.

Kohl gates commands on both client and server, so changing AdminBridge alone would leave its old Creator-only UI gate in place. `AdminKohlAddon` adapts `Auth.hasCommand` only for the 21 registered GameTester command definitions and their aliases. Its server path uses AdminConfig; unrelated commands delegate to Kohl's original function. Command registration uses the SuperAdmin group. This grants no additional unrelated Kohl powers. The existing war debug command is `resolvewar`; no new `setwar` command was added.

AdminService replicates `_GameTesterAuthorized` for client command admission and refreshes it on player arrival and Kohl role addition/removal. That attribute is presentation only: both server command admission and AdminBridge execution independently recheck the server rule. No client-provided rank, GUI state, attribute, or remote argument is server authority. Existing Communications GameTester observer authorization inherits the same central decision, without changing channel rules or transport.

Help now reads `GameTester commands (authorized UserIds or Kohl SuperAdmin+).` Existing Studio fallback instructions remain.

The integration was cross-checked against installed Kohl in Studio and the official [Auth implementation](https://raw.githubusercontent.com/kohls-admin/kohls-admin/master/src/Shared/Auth.luau), [command registration](https://raw.githubusercontent.com/kohls-admin/kohls-admin/master/src/Shared/Registry.luau), and [command processing](https://raw.githubusercontent.com/kohls-admin/kohls-admin/master/src/Shared/Process/init.luau).

## Targeted verification

| Case | Agent result |
| --- | --- |
| Creator, effective SuperAdmin, all five allowlisted IDs | PASS |
| Lower rank and ordinary nonallowlisted positive IDs | PASS |
| All 21 commands and alias admission; unrelated Kohl gate preserved | PASS |
| Immediate rank revocation, unavailable/failed rank lookup | PASS |
| Malformed actor IDs, operation and mutation arguments | PASS |
| Authorized InspectVictory and Help through AdminBridge | PASS |
| Unauthorized direct Bridge mutation / rank-argument spoof | PASS |
| Two actual unauthorized client Kohl remote requests | PASS: received on server; zero calls to mutation bridge |
| Spoofed UI authorization and rank attributes / extra rank and UserId arguments | PASS: cannot grant server access |
| AdminFeedbackEvent client-to-server mutation attempt | PASS: no mutation; existing event has no server mutation handler |
| Authorized normal Kohl adminhelp pipeline and visible help panel | PASS |
| Four changed sources and three fixtures compile with Luau 0.740 | PASS |
| Edit-mode source equality and runtime fixture cleanup | PASS |
| Diff scope and whitespace | Reviewed; git diff --check PASS |

Final server matrix: `ADMIN_PERMISSIONS_SERVER_PASS 117` at 19:03:53 local time. Remote test: `ADMIN_PERMISSIONS_REMOTE_PASS 2 0` at 19:01:23. Runtime-only rank/allowlist mocks were restored; stopping Play removed fixtures and client attribute spoofing. Early fixture attempts encountered Studio Source-write capability restrictions and an incorrectly measured multiplexed remote envelope; the corrected fixtures passed. Kohl also emitted its existing Studio DataStore API-access-disabled error; no settings were changed to enable published data access.

Reproducible fixtures: `docs/verification/admin-permissions-server-checks.luau.txt`, `admin-permissions-remote-checks.luau.txt`, and `admin-permissions-client-checks.luau.txt`. Run the server matrix as a temporary Script after bootstrap. For the remote fixture, run its server Script, then its client LocalScript in the actual client within 30 seconds; this fixture expects owner UserId 106676397 in Solo. Prepare Source through Studio's command bar, not from ordinary runtime scripts. Never ship these fixtures in the place.

Evidence: `docs/verification/admin-permissions-server-2026-10-10.jpg` and `admin-permissions-help-2026-10-10.jpg`.

Limitations: the four added accounts were checked by UserId, not logged in individually. Nonallowlisted effective ranks were representative trusted server mocks, not permanent account-rank changes. No published-server or full gameplay regression suite was run for this narrowly scoped permission change. Future Kohl API changes should be rechecked against this scoped adapter.
