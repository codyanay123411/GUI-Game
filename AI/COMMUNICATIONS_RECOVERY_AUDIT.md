# Communications recovery audit — 2026-10-09

Historical investigation report. Subsequent authorized replacement, GUI/Overview and conquest/victory work supersedes its baseline/status findings; current state is tracked in `AI/PROGRESS.md` and the implementation reports. Recovery provenance findings remain historical evidence.

**Recommendation: B — salvage selected parts and rebuild the rest.** The candidate contains useful graph, identity, help-copy, and diplomacy-instance work. It cannot continue largely as-is because its displayed messages bypass the native TextChatService delivery result, an ended Alliance briefly remains writable, Council removal leaves stale active state, and the transcript clips ordinary use. Rejecting everything would discard reusable work unnecessarily.

This is an evaluation of recovered work, not implementation acceptance. The frozen design recorded by commit `322b0723a03a998d87a945e44bec3acb0dab9bd9` remains authoritative. No candidate was integrated, rewritten, synced, committed, pushed, or published. Local-server fixtures and temporary diagnostic scripts were confined to disposable test sessions, which have ended.

## Preservation and coverage

The original [five-script snapshot](../docs/verification/2026-10-09-studio-communications-snapshot.json) remains unchanged. A fresh edit-mode export after testing matched all five Source strings exactly; [integrity evidence](../docs/verification/2026-10-09-communications-integrity.json) records their UTF-8 hashes and absence of temporary RecoveryAudit scripts in edit mode. This is a source snapshot, not a full binary place backup.

Inspected the complete CommunicationsService, CommunicationsController, CommunicationsConfig, both bootstraps, RealmGraph, relevant DiplomacyService changes, AdminBridge, AdminService, AdminConfig, AdminKohlAddon, PrototypeGuiTheme, and TerritoryMapController. Supplemental sources are preserved in [dependency JSON](../docs/verification/2026-10-09-studio-communications-dependencies.json), with readable `.txt` copies in [recovered-communications](../docs/verification/recovered-communications/). GUI instances, remotes, script metadata, and native chat configuration are recorded in [metadata](../docs/verification/2026-10-09-studio-communications-metadata.json). These copies are outside Script Sync source directories.

Compared against `AI/GAME_DESIGN.md` Communications section, `AI/DECISIONS.md` Communications freeze, Communications milestones in `AI/ROADMAP.md`, the unimplemented status in `AI/PROGRESS.md`, and `docs/ARCHITECTURE.md` Communications section. Those documents agree on intended behavior and explicitly leave several UI/command choices unresolved. Their frozen rules have not been changed by this audit.

## What the candidate implements

The server creates native TextChannels and tracks Diplomatic, Council, per-Alliance, and unordered two-player Direct contexts. RealmGraph combines subjects' territories under their independent root, derives adjacency from the authored map, and computes graph distance by breadth-first search. The service derives sender identity from the Player, validates message shape and a 200-byte limit, computes recipients, filters through TextService, and sends custom RemoteEvent message payloads. It then asks the client to echo the original text through TextChannel:SendAsync.

The client renders its transcript from those custom payloads, not native MessageReceived. It stores up to 80 entries per context for that client session, tracks unread counts, shows a one-time notification for an unread context, and supports a Direct contact picker, Help, and an admin observer view. Observer history retains 40 entries; muting drops observer updates locally without muting ordinary conversations. There is no persistent message store, history search, or reconnect backfill.

The service polls and pushes all conversation state every 0.35 seconds. It repeatedly reconstructs graph/hierarchy information and checks Direct permissions, rather than updating membership primarily on political events. The controller rebuilds conversation/contact buttons on state pushes. Native default chat UI and bubbles are disabled at runtime; the custom panel is added to theme styling and map input exclusion. Existing service startup order remains thin and dependency-aware.

DiplomacyService adds a distinct Alliance instance ID on acceptance and clears it on break. AdminBridge exposes inspection and announcements through existing admin authorization; Kohl adds inspectcomms and announce. A native `/commshelp` command and a Help button provide context help. Debug bindables expose inspection, forced synchronization, distance/recipient queries, and test sends/opens. They do not themselves establish acceptance or provenance.

## Design comparison

“Matches” below applies to the specific rule, not an endorsement of the entire channel or transport. Runtime observations and static findings are distinguished in the next section.

| Frozen requirement | Classification | Candidate behavior |
| --- | --- | --- |
| Diplomatic audience uses independent-root map distance at most two; sender-specific audiences need not be symmetrical | Matches the rule | Root aggregation and BFS implement this; fixture recipient sets matched. Messages already delivered are not subsequently removed. |
| Council includes presiding ruler and direct subjects only, with separate upward/downward contexts and no geography gate | Matches initial membership; incomplete lifecycle | Separate councils and rejection of a grand-subject were reproduced. Removed presiding rulers leave stale active councils. |
| Allies includes only actual parties to a specific Alliance, no subject inheritance or NAP entitlement, no geography gate | Matches initial entitlement; contradicts immediate revocation | Distinct Alliance IDs and nonparty rejection work. A send immediately after break succeeded before the next synchronization. |
| Direct is exactly two players, current graph distance one, immediate loss of eligibility, possible restoration, retained match history | Partially matches | Unordered pair IDs, no open-to-nonneighbor, immediate border-loss rejection, restoration, and inactive-history flags worked. Platform permission is not authoritative for the displayed custom transport. |
| Direct works regardless of liege/subject/ally/enemy relationship when eligible | Partial; design interpretation needs resolution | Root aggregation gives a liege and subject distance zero, and the distance-one check rejects them. This conflicts with the explicit liege/subject example unless its spatial eligibility is clarified. Do not silently change the frozen rule. |
| Current title on future messages; one relationship marker for Diplomatic/Direct; title only in Council/Allies; no territory count | Matches formatting policy | Formatters derive current identity and prioritize Liege/Subject over Ally. Council runtime preserved the old Duke prefix and used King after promotion. Full relationship permutations were not all exercised live. |
| Neutral authorized admin observer, explicit context, view-only mute | Partially matches | Context and identity metadata plus local mute exist; authorization follows existing admin integration. Observer filtering is unsafe on failure and is not per observer. |
| Context SYSTEM introduction on first open and harmless current-context repeat help | Partially matches | Frozen help copy and Help path exist. Direct Opened selects a context without the same first-open introduction path as a row click; help/transcript clipping makes it unusable beyond a few lines. |
| Prefer native TextChatService; audit APIs before deciding native UI cannot meet the design; platform filtering/permissions remain underlying | Contradicts architecture | The displayed RemoteEvent stream precedes native SendAsync and ignores its outcome. No recorded native UI/API insufficiency audit justifies the custom replacement. |
| Match-session history, no advanced history/search or strategic-word censorship | Matches limited scope, with incomplete availability | Client-only bounded logs; no persistent history/search; no strategic-number/word censor found. No server replay for reconnects. Some inactive-history state is advertised incorrectly. |
| Announcement direction is ADMIN, but announcement UX/commands are explicitly not authorized yet | Unauthorized implementation | Working raw-text ADMIN broadcast, AdminBridge operation, and Kohl announce command already exist. Authorization of the actor does not authorize this frozen-out product scope. |
| Selectors, visual layout, command details, observer UX, history loading, and acceptance matrix remain unresolved | Unapproved prototype choices | Fixed panel, contacts picker, `/commshelp`, caps of 80/40, unread/toast behavior, and polling are implementation choices without approval evidence. They are candidates for evaluation, not newly frozen requirements. Player Kohl-help integration remains unresolved. |

No new gameplay/economy/Military effects, espionage system, keyword censorship, or territory-count identity display were found in the Communications paths.

## Reproduced tests and failures

Used three real Studio Local Server clients. Rulers were assigned controlled territories through existing authoritative debug APIs. A fourth server-side mock ruler extended the graph fixture; it was not a fourth receiving client. Temporary tests used existing service APIs and did not rewrite candidate Source. Machine-readable evidence: [phase 1](../docs/verification/communications-phase1-results.json), [phase 2](../docs/verification/communications-phase2-results.json), [phase 3](../docs/verification/communications-phase3-results.json). Diagnostic scripts and raw server observations are preserved alongside the recovered sources.

| Scenario | Observation | Result/limit |
| --- | --- | --- |
| COM-REC-01 Diplomatic graph | Distances from player 1 to players 2/3/mock 4 were 1/2/3. Recipient sets excluded distance three. Player 3 sent `AUDIT DIP 123 troops` using the actual GUI and saw the transcript and observer context. | Local graph and GUI send exercised; mock exclusion is recipient computation evidence only. |
| COM-REC-02 Direct | Distance-two open rejected; neighboring open/send accepted. Moving the peer away caused immediate `No border.` rejection before synchronization. Restoring the territory restored sending. Old context/history flags remained. | Political border behavior exercised; real account privacy not verified. |
| COM-REC-03 malformed requests | Table conversation ID rejected as `Invalid message.`; 201 ASCII characters rejected as `Rejected length.` | Rejection paths exercised. Unicode length behavior was not tested; static limit is bytes. |
| COM-REC-04 Allies | Two actual Alliance acceptances yielded distinct IDs. Nonparty send rejected. NAP acceptance created no additional Alliance entitlement. | Initial party isolation exercised. |
| COM-REC-05 Alliance break | Immediately after successful break, sending to that Alliance still returned `true, sent`. After forced sync it returned `Cannot send.` | **Reproduced revocation defect.** The polling interval creates a writable ended-Alliance window. |
| COM-REC-06 Council/identity | Emperor→King→Duke produced separate councils 1+2 and 2+3. Grand-subject rejected from Emperor council. Duke promoted to King; subsequent displayed prefix changed while the earlier Duke entry remained. | Initial membership, separate contexts, and future-message title behavior exercised. |
| COM-REC-07 Council cleanup | Removing presiding ruler 2 through hierarchy cleanup made subject 3 independent. Council 2 nevertheless remained active/canSend with both native TextSources still send-enabled. A send by player 3 was rejected `Not in Council.` | **Reproduced state/source cleanup defect.** This exercised ruler-removal cleanup, not an actual network disconnect. |
| COM-REC-08 same-root Direct | King and direct subject had graph distance zero; Direct open rejected as `Not neighboring.` | Reproduced interpretation mismatch described above. |
| COM-REC-09 layout | Help plus a few messages overflowed the fixed 86-pixel top-aligned transcript, with no scrolling. Observer text overflowed its 46-pixel area; contact/observer positions overlap. | **Reproduced usability defect.** |

Screenshots: [Diplomatic](../docs/verification/communications-diplomatic-local.png), [Council and title change](../docs/verification/communications-council-local.png).

These are agent observations, not Director acceptance. The candidate deliberately permits Studio raw-text/filter and Direct-permission fallbacks for synthetic users. Consequently these tests do not establish production filtering, account age/privacy/block permissions, native rate limits, or published-server behavior. No unsafe text was used to probe those paths. Large-player performance, all relationship prefixes, mobile layout, actual disconnect/rejoin history, native team/whisper paths, and exhaustive rejected admin operations remain unverified. Existing deferred Military scenarios remain deferred.

## Additional defects found by inspection

1. **Native moderation result is not the displayed result.** Custom Message delivery occurs before the client TcsEcho/SendAsync attempt. The controller never consumes native MessageReceived. A native rejection, filtering change, rate limit, or permission result cannot retract the custom display. Custom sends lack general platform chat-permission admission equivalent to the native pipeline.
2. **Observer failure can disclose raw text in production.** Observer preview starts as raw input. If every recipient filter fails, no successful filtered string replaces it, yet observers receive it. When filtering succeeds, one recipient's filtered string is reused for all observers rather than filtering for each observer. Announcements are also broadcast raw. These are static findings, not reproduced production leaks.
3. **Native source retention can violate membership privacy.** Removed Council members' TextSources are retained for history and may only lose CanSend. Council native delivery checks active context rather than current political membership. Thus retained sources can remain potential recipients after entitlement ends. The stale active council was reproduced; an actual native message leak to a former member was not tested.
4. **Yielding work has no final political revalidation.** Recipient computation precedes asynchronous filtering/permission calls. Political changes during those yields can leave stale delivery decisions. This is a separate static race risk from the reproduced Alliance-break polling defect.
5. **UI authority/status is inconsistent.** `canSend` is context-global rather than viewer-specific in some retained-member cases; input editability is refreshed on selection rather than consistently on state changes. Direct Opened skips part of the regular introduction/status setup. First send arms a Direct recipient before filtering succeeds, permitting an empty retained context.
6. **Incomplete diagnostics and error handling.** LastSnapshot is created but never populated; service helpShown state is unused; several pcall failures are swallowed. Server-side DisplaySystemMessage calls fail because that API is client-only, with the custom SYSTEM remote masking the error. Repeated graph scans, asynchronous permission checks, state pushes, and client button reconstruction every 0.35 seconds need redesign or measurement before scaling.

Roblox documents the native SendAsync/filter/delivery flow and support for custom presentation in [in-experience text chat](https://create.roblox.com/docs/chat/in-experience-text-chat). The candidate's use of GetChatForUserAsync is [deprecated](https://create.roblox.com/docs/reference/engine/classes/TextFilterResult). [TextChannel](https://create.roblox.com/docs/reference/engine/classes/TextChannel) documents native Direct requester handling; [DisplaySystemMessage](https://create.roblox.com/docs/reference/engine/classes/TextChannel/DisplaySystemMessage) is a client call. These API findings reinforce the code-path audit; they do not establish production test success.

## Provenance

The recovered place reports place ID `77421850892463`, version `89`. That identifies a place version, not the date or author of these scripts. Script attributes were empty and readable LinkedSource values were empty. No readable creation-author/time metadata, dated implementation comments, approval references, or design exception record was found. Some identity/asset properties were inaccessible; absence of readable evidence is not proof those identifiers never existed.

Headers say “V0.x — first implementation pass” / “V0.x player UI”; internal markers include `__CommunicationsV01`. Frozen help text and the added Alliance instance IDs suggest a coordinated design-informed prototype, but that is inference. Neither naming nor copied design text establishes approval or age.

The Studio candidate also includes matching bootstrap, diplomacy, admin, theme, and map-input changes absent from the design-only checkout. This supports treating it as a coherent recovered candidate rather than a single stray script. It does not make Studio canonical.

Targeted local place/autosave searches found no older `.rbxl`/`.rbxlx` artifact establishing origin. Available Roblox logs were created during this current takeover; their earliest observed Communications startup was October 9 at about 21:05 local time. That proves execution during this investigation, not original creation. Checkout filesystem dates likewise do not date the Studio implementation. Its original creation date, session, author, and approval status remain unresolved.

## Recommended salvage boundary

Preserve everything as evidence. Reuse the stateless root-graph/BFS approach, current-title and relationship formatting rules, frozen context-help copy, distinct Alliance instance IDs, and existing authoritative service/admin integration patterns after isolated review. Keep initial Council/Alliance entitlement logic as useful reference with fresh lifecycle tests.

Rebuild delivery around one authoritative native TextChatService filtering/permission result, then implement political membership and immediate revocation without stale retained native recipients. Handle observer filtering explicitly. Resolve the same-root Direct interpretation and still-unapproved UI choices with the Director; perform the native API/UI suitability audit before selecting presentation. Replace the clipped prototype with usable history/context presentation. Exclude the premature announcement command from the approved implementation scope.

**Stop point reached:** no integration into source-controlled gameplay directories. Communications remains design-frozen and unaccepted; the audit recommends a future salvage plan, not permission to implement it now.
