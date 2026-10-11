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
