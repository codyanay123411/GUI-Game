# Repository Guidelines

## Architecture and boundaries

This GUI-first Roblox strategy game uses Script Sync for disk Luau. `ServerScriptService/Services` owns authoritative state and validates client requests; `StarterPlayerScripts/Controllers` owns presentation/input; `ReplicatedStorage/Shared` contains safe shared config, types and utilities. Preserve accepted service ownership in [Architecture](docs/ARCHITECTURE.md). Keep bootstraps thin.

Disk `StarterPlayerScripts` maps to Studio `StarterPlayer.StarterPlayerScripts`. Keep `Bootstrap.local.luau`: replacing it with `Bootstrap.client.luau` can cause duplicate execution. Reserved empty sync folders use `_Placeholder.luau`; remove it when real modules occupy the folder, except Remotes, whose instances are Studio-managed.

Admin mutations go through `AdminBridge` and existing service APIs; Kohl is command UI, not gameplay authority. Do not add client admin-mutation remotes. Ordinary UI exposes player-relevant/public information, not private global state. GUI integration and visibility rules are in Architecture.

Follow existing Luau style: `--!strict`, tabs, double quotes, explicit types where practical, early validation returns, PascalCase modules and camelCase locals.

## Locate context by task

Start with this file, the requested outcome, and `git status`. Read the latest relevant entry in [Progress](AI/PROGRESS.md); search document headings/keywords before reading whole files. Read only relevant sections and linked evidence. Historical entries retain their dates and scope.

| Task | Context to read |
| --- | --- |
| Gameplay or scope | Relevant `AI/GAME_DESIGN.md` sections (design authority), `AI/DECISIONS.md` rulings, `AI/ROADMAP.md` dependencies and system report |
| Architecture/integration | `docs/ARCHITECTURE.md` ownership/contracts and relevant decisions |
| UI/input/audio | Architecture GUI/input sections; `AI/GUI_UX_SPRINT.md`, `AI/CONTEXTUAL_MAP_INTERACTION.md` or `AI/GUI_REDUNDANCY_CLEANUP.md` as relevant; `AI/GAME_PRESENTATION_SETTINGS.md` for settings/audio |
| Communications | Design Communications section and `AI/COMMUNICATIONS_IMPLEMENTATION.md`; recovery audit only for recovered code/provenance |
| Multiplayer/verification | System report and matching `AI/PLAYTEST_BACKLOG.md` scenarios; acceptance evidence in Progress |
| Release/Git finalization | `AI/FINALIZATION.md`, latest Progress/Changelog, actual status/diff/remote state |
| Documentation only | Relevant workflow/configuration and document sections; no full gameplay review |
| Continue interrupted work | Latest relevant Progress entry, linked report's remaining work, current diff; Changelog/Decisions only where needed |

The [coverage map and command reference](docs/ARCHITECTURE.md#repository--studio-coverage) distinguish Git, Studio and snapshots. Repository inspection is sufficient for disk-only edits/static claims. GUI bindings, Explorer objects, place settings or recovered Studio work require live inspection or a sufficiently current saved export. Compare versions before syncing; never overwrite recovered work on assumption. Obtain a current export when needed within the task's authorization, rather than treating an old snapshot as current. If unavailable, document the gap and complete independent work. “Not represented in Git” does not mean “not implemented.” Input/visual behavior requires runtime verification; multiplayer authority/delivery needs appropriate multi-client or real-account checks.

## Mandatory GUI contract

Before GUI work, inspect the current live interface and relevant shared theme/component patterns. Use `PrototypeGuiTheme` tokens/helpers and existing presentation/settings infrastructure; document purposeful semantic exceptions. Verify changed UI beside existing screens in runtime, including generated/reopened content and supported font, density and opacity settings. Static checks do not establish visual consistency. The authoritative component/style reference is [Game presentation guidance](AI/GAME_PRESENTATION_SETTINGS.md#gui-component-contract).

## Development loop

1. Establish the requested outcome, completion criteria and authorized scope. Preserve approved design; roadmap concepts do not authorize implementation. Ask about material unspecified mechanics rather than inventing them.
2. Read relevant context, inspect the affected disk/Studio coverage, and implement the authorized scope.
3. Run checks appropriate to the change using the Architecture command reference. Documentation changes normally need link/claim checks and `git diff --check`, not gameplay sessions.
4. Review the actual diff for requirement violations and concrete defects. Fix supported findings and rerun affected checks. Repeat reviews/testing only for new changes, failures or unresolved concerns.
5. Update relevant state/evidence records and stop. Never claim completion solely because code was written; state verification limitations explicitly.

## Verification and acceptance

Verify as far as the environment reasonably allows before asking the Director to test. Use static checks, pure fixtures, Studio Play, Local Server, existing server/admin hooks and Output as appropriate. Check rejected requests, invariants, cleanup and multiplayer consistency where relevant. Hidden state remains testable through server/admin/debug observability; temporary diagnostics must be removable/disableable, non-authoritative and server-only where needed. Never expose private state to ordinary UI/remotes for testing. Do not defer agent-testable cases merely for convenience.

Record separately: **implemented**, **automatically tested** (which checks), **Studio tested**, **multiplayer tested** (clients/accounts), and **Director-verified/accepted** (explicit evidence). Historical, synthetic, deferred or assumed checks are not current passes. Studio development sessions are not the first real published playtest defined in Game Design. Director testing focuses on player-facing flows, UX/feel and final acceptance.

Classify remaining checks as **DIRECTOR VERIFICATION REQUIRED**, **NOT TESTABLE IN CURRENT ENVIRONMENT** (reason), or **DEFERRED — NON-BLOCKING — V0.5 PLAYTEST VERIFICATION BACKLOG**. Cumbersome multiplayer/emergent cases may be non-blocking only after reasonable agent verification, verified core authority/invariants, a working ordinary loop and no known critical defect. Deferred never means PASS. Security/exploit risk, duplication/loss/corruption, broken ordinary gameplay, a concrete defect or Director promotion makes a case blocking. Record scenario IDs and evidence in the existing Playtest Backlog.

## Work records

Use the existing system report for detailed evidence; Progress for current state, Changelog for meaningful completed changes, Decisions for significant decisions and superseded rulings, and Playtest Backlog for remaining scenarios. Keep entries concise:

- Outcome and relevant changed files.
- Significant decisions and reasons.
- Checks actually run, method/environment and results, with evidence links.
- Failed, unavailable, deferred or unverified checks.
- Remaining work and a concrete next step.

Reference logs/reports instead of duplicating diffs or lengthy Output. Preserve dated acceptance records. Do not edit Game Design to justify implementation; product/design changes require explicit user direction (workflow cross-references are not mechanics changes).

## Permission and handoff

Do not commit or push unless requested. Do not infer publication or unrelated feature authorization from a development task. Preserve recovery assets and unrelated work; unresolved evidence conflicts belong in the record, not an invented resolution.

Use imperative commit subjects. PRs describe scope, affected systems, verification and outstanding cases; include GUI screenshots where relevant. Report results and limitations without turning agent verification into Director acceptance.
