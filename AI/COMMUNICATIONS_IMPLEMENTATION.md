# Communications V0.x replacement

Implementation authorized by Director on 2026-10-09; frozen product rules remain authoritative. Agent verification is not Director acceptance.

## Salvage map

| Action | Recovered piece | Boundary |
| --- | --- | --- |
| Reuse directly | RealmGraph stateless root-land aggregation, adjacency, BFS | Reads current Hierarchy/Territory; no political cache. |
| Adapt | Identity formatter, contextual help | Server labels joined by native MessageId; exact canonical help wording. |
| Adapt | Alliance instance IDs | Owned by Diplomacy; new ID on each accepted Alliance, cleared on break; StateChanged notification added. |
| Rewrite | Communications service/controller, membership lifecycle, GUI transcript | Native-only message delivery, fresh non-yielding political checks, event-driven synchronization, scrolling history. |
| Discard from active code | Message/TcsEcho remotes, TextService chat filtering, raw fallbacks, announcements | Bypass native delivery or expand deferred scope. Preserved audit copies remain inactive. |
| Discard | Polling/rebuild loop, stale retained TextSources, old global canSend, server DisplaySystemMessage | Replace with source removal, per-view eligibility, client system help, authority events. |

## Native API audit and presentation

TextChannel SendAsync and MessageReceived provide the sole user-text path; only Success receipts are rendered. ShouldDeliverCallback must not yield and reads current authoritative political state for sender and recipient on every call, including sender self-delivery. TextSource CanSend and membership are additional gates, never political authority. Direct channels are marked with SetDirectChatRequester; no Studio or production raw-text/permission fallback.

Official references: [TextChannel](https://create.roblox.com/docs/reference/engine/classes/TextChannel), [chat guidelines](https://create.roblox.com/docs/chat/guidelines), [message status](https://create.roblox.com/docs/reference/engine/enums/TextChatMessageStatus).

Native channel tabs/input support ordinary custom channels. Native single-window history does not provide the existing prototype's separate neutral observer transcript with local mute and simultaneous viewer-specific context labels/history. Retain a bounded Communications panel for those presentation requirements, backed entirely by native receipts. No player text travels through custom remotes. Authoritative label envelopes contain only developer/game-state metadata keyed to native MessageId; they cannot create a transcript entry without a native Success receipt.

Authorized observers use read-only native TextSources and native delivery/privacy rules, including Direct requester eligibility. They never become ordinary Council/Allies/Direct participants. If Roblox denies an observer delivery, do not bypass it. Full observer visibility under real account restrictions requires published/Team Test verification.

The recovered panel is modified in Studio only; GUI instances remain out of filesystem source. Preserve the accepted UI shell; use measured wrapping content inside a scrolling Communications panel rather than reorganizing unrelated panels.

## Verification

Replacement implemented and staged in Studio. Agent verification is partial; NOT Director-accepted. Three synthetic Local Server clients were used, followed by a final Play Solo verification of the last presentation fixes.

| Scenario | Agent result | Evidence / limit |
| --- | --- | --- |
| COM-POL-01 Diplomatic reach | PASS political authority | Distance 1 and 2 allowed; distance 3 denied; sender-dependent audiences preserved; territory changes rejected before synchronization. |
| COM-POL-02 Council | PASS political authority and cleanup | New upward/downward Councils after fealty; direct subjects allowed; grand-subject denied; ruler removal denies immediately, then no ordinary members or writable sources remain. Final cleanup fixture was rerun after diagnostic fixture errors; immediate post-removal assertions in the final artifact are settled-state confirmations, not a fresh transition. |
| COM-POL-03 Allies | PASS political authority | Distinct IDs for two Alliances; outsider rejected; break immediately rejects sender and self-delivery before sync; reaccept generates new ID, old ID remains invalid; NAP creates no Allies context. |
| COM-POL-04 Direct | PASS personal-border and same-root authority cases | Adjacent pair opens; too-far/malformed rejected; only two ordinary members; outsider rejected; lost border immediately rejects; ruler removal rejects. Same-root interpretation resolved by Director ruling; targeted 26-check rerun below. |
| COM-NATIVE-01 delivery | PARTIAL | Native Success sender receipts displayed in Diplomatic and Council. No remote user text; Identity metadata alone creates no entry. Synthetic users' CanUsersChatAsync(-2,-1) returned false; CanUsersDirectChatAsync returned no allowed recipient. Peer receipt was absent and correctly not rendered. This is NOT a peer filtering/privacy pass. |
| COM-NATIVE-02 stale blocked send | PASS | Native Council receipt InvalidTextChannelPermissions; displayed=false despite SendAsync returning Sending. See blocked-native-result.txt. |
| COM-UI-01 identity/help/layout | PASS observed cases | Lord/Duke live titles, Ally/Liege/Subject prefixes, neutral observer/title-only Council labels; exact help; wrapped long message; scrolling previous help; no map selection from Communications controls. 1280x924 Local Server and 1150x936 Play Solo windows. Final measured body/canvas 274px vs 126px viewport, input empty after Success. |
| COM-REG-01 accepted services | PASS targeted smoke checks | Fealty chain/ruler cleanup; territory reassignment/unclaim; Alliance/NAP lifecycle; war adjacency/duplicate rejection, commit/cancel; recruitment price/rejection and unaffordable spend; settled Military total=available=1003, committed=0, ledgerOk=true. This does not re-run all prior Director acceptance or deferred Military cases. |
| COM-INTEGRITY-01 integration | PASS | All 11 changed/new live source checks match disk (normalized line endings); one active server and one active client Bootstrap. Original archive modules inactive and both archived bootstraps disabled. |

Evidence resides in docs/verification: communications-replacement-phase1/2/3-results.json, communications-blocked-native-result.txt, communications-native-receipt-clean.txt, communications-final-startup-output.txt, communications-final-integrity.json and screenshots. Temporary diagnostic scripts/remotes existed only in the disposable server/clients and were removed by ending the session. Some failed diagnostic fixture attempts are preserved in logs; they were not production script failures or counted as passes. Final Play shutdown exposed an unrelated installed Model To Pixel plugin MainTextShadow error; project Communications startup/run had no observed errors.

## Remaining Director decisions and verification

Director ruling (2026-10-09): Direct adjacency is between two different rulers’ directly/personally owned territories, independent of political relationship. No greater-realm/root graph distance, no inherited subject holdings, no shared-root entitlement. Council and Direct can coexist. Implemented in CommunicationsPolicy.Direct; all existing consumers (OpenDirect, contacts, native delivery membership checks and synchronization) inherit the rule. Exact frozen help wording retained; the border rule is now explicitly defined in GAME_DESIGN.

Targeted three-client rerun: **26/26 checks PASS** in communications-direct-clarification-results.json. Live hierarchy/territory/service cases verify same-root adjacent liege/subject both directions, same-root non-adjacent rejection with Council retained, Council/Direct coexistence, border loss and restoration before sync, third-player rejection, self/malformed rejection, landless rejection, and exclusion of inherited subject holdings even when greater-realm roots are adjacent. Additional injected-snapshot policy checks cover fellow subjects, Allies, enemies, NAP and unrelated labels with identical personal-border eligibility; these are not full live relationship/end-to-end native delivery scenarios. Diplomatic same-root reach remains unchanged. No new native peer filtering/privacy claim; existing synthetic-user limitation remains.

Director testing remains: real-account peer receipts/filtering/privacy for all paths and mixed account permissions; authorized native observer visibility and local mute without affecting ordinary receivers; ordinary non-admin source destruction on membership loss; actual network disconnect/reconnect and liege/root changes; readability with long names and chosen supported smaller viewport; sustained channel growth/load. The current native channel/context registry is match-scoped and retains ended context metadata; stress/retention limits require future verification. No production chat safety or Director acceptance claim.

## Files and retirement

Created: ReplicatedStorage/Shared/Util/RealmGraph.luau; ReplicatedStorage/Shared/Config/CommunicationsConfig.luau; ServerScriptService/Services/CommunicationsPolicy.luau; ServerScriptService/Services/CommunicationsService.luau; StarterPlayerScripts/Controllers/CommunicationsController.luau.

Changed: both existing Bootstrap files, DiplomacyService (Alliance IDs and StateChanged), AdminBridge/AdminKohlAddon (inspectcomms only), TerritoryMapController (Communications pointer bounds). Studio-only Communications GUI and TextChatService edit configuration (CreateDefaultTextChannels/CreateDefaultCommands=false). Accepted PrototypeGuiTheme was restored in Studio without a disk change. Documentation updated in Progress, Changelog, Decisions, Roadmap, Architecture and Playtest Backlog.

Recovered active sources have been replaced with one implementation; archived copies must remain inactive and should be retained for salvage/provenance. Original recovery JSON snapshots were not overwritten. ServerStorage.CommunicationsRecoveryArchive includes original modules, disabled bootstrap copies and old panel. Local ignored place snapshot: docs/verification/communications-replacement-2026-10-09.rbxl (718208 bytes), includes replacement GUI and archive. No commit, push or publish. Physical deletion of the archive is unnecessary and should wait until remaining verification is resolved.


Follow-up GUI/lifecycle check: Player2 Direct contacts offered adjacent liege Player1 and excluded non-adjacent subject Player3; opening Player1 showed Direct and both Councils. Moving Player2’s personal land away made Direct unavailable, no ordinary Direct members and all native sources CanSend=false, while Council memberships remained valid. Screenshots/output: communications-direct-same-root-gui.jpg, communications-direct-border-loss-gui.jpg and communications-direct-border-loss-output.txt. One isolated CommandBar require used a separate uninitialized module context and failed; rerun in a disposable server Script used the live gameplay authority and passed.

Latest local ignored place snapshot after the Direct ruling: docs/verification/communications-direct-clarified-2026-10-09.rbxl. Earlier snapshots retained unchanged. Edit-mode Policy source compared to disk: DIRECT_POLICY_DISK_MATCH=true. Disposable targeted server/clients ended; no diagnostic scripts integrated into the main place.
