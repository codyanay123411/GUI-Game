# Decisions

Substantial architectural decisions belong in this file. Do not silently reverse them later. If a decision changes, record the new decision and why the previous one was replaced.

## Development workflow

- **Cursor Local Agent on This PC.** Local agent work runs on this machine, not a remote cloud agent, unless a later decision says otherwise.
- **Roblox Studio MCP.** Use Studio MCP for direct Studio interaction and playtesting (hierarchy inspection, running Studio, checking output, and related agent-driven Studio work).
- **Script Sync.** Version-controlled Luau lives on disk and stays in sync with Studio through Script Sync. `.luau` files are the source of truth for scripts.
- **Empty Script Sync folders.** Script Sync does not create Studio folders that contain no `.luau` files. Reserved directories keep a `_Placeholder.luau` ModuleScript that returns `{}` solely so the folder appears in Studio. Delete that placeholder when the folder has real project files. Do not put gameplay in placeholders.
- **Git / GitHub.** Use Git for history and rollback. The project’s **private GitHub** repository (`origin`) is an active part of the development workflow.

## Product direction

- This project is a **GUI-first multiplayer feudal grand-strategy and political RPG** for Roblox. Play is interface-driven (2D political map), not a traditional explorable 3D world, unless directors later change that.
- **Match:** approximately **30 minutes**, approximately **50 players**, one shared political world. History is **fictional and player-created** each match. Not a historical timeline and not a clone of another game’s exact mechanics.
- **Subordination is gameplay, not elimination.** Being conquered or becoming a subject does not automatically remove a player from the match. Powerful subordinate play must remain viable.
- Previous **single-player-oriented** development assumptions are **superseded**. The first meaningful gameplay prototype (when authorized) is **multiplayer political hierarchy**, not a deep autonomous character simulation. Do not implement that prototype until directed.
- Victory conditions are conceptual only. Do not implement victory math until those systems are formally designed.

## Political hierarchy (Design V0.1 — specified, not implemented)

- Foundational system. Nested ruler-to-ruler trees. Server-authoritative. Clients may request and display; the server validates.
- **Ranks:** Lord → Duke → King → Emperor (four primary landed levels). This supersedes earlier Count-tier wording.
- **Normal start:** every participating player is an **Independent Lord** with **one** starting territory. No player Dukes/Kings/Emperors at match start.
- **Independence** is a status, not a rank. Rank and independence are separate.
- Distinguish **direct liege**, **direct vassals**, **indirect subjects**, independent rulers, top ruler, and greater-realm membership.
- **Voluntary vassalage** (both agree): allowed to equal or higher rank; **never** to lower rank. Equal-rank vassalage is allowed so blocs can form at Lord before higher titles exist.
- When a ruler’s liege changes (join or leave a greater realm), **existing subordinate trees stay attached**. Do not flatten internal hierarchy.
- Humans and NPCs may eventually share the same conceptual rules; detailed NPC political AI is unspecified.
- **No cycles.** Reject becoming subordinate to someone already in your subordinate tree.
- Title **establishment** (when designed for play): eligibility from map-configured greater-realm control **plus** a minimum Prestige threshold (Prestige **not** spent); player action; server revalidates. Not automatic. Gold/Influence are not establishment requirements. Established titles are **not** auto-demoted for falling below creation thresholds. Exact numbers and title-loss systems remain unresolved.
- **Unresolved (do not invent):** exact scaling formula and numerical thresholds; title-loss; vassal obligations; independence methods; disconnect/reconnect; join-in-progress. War may later change hierarchy without eliminating players; war outcomes are not designed.

## Maps, title scaling, economy, monetization (checkpoint — specified, not implemented)

- Primary board: large interactive GUI political map. Multiple fictional maps; territory counts may differ; geography is stable per map and separate from political realm names. Map size and title scaling do **not** depend on human player count.
- `TitleRequirements = f(MapConfiguration)` — deterministic, configuration-driven. Greater-realm control counts. Do not hardcode universal X/Y/Z territory counts.
- Match resources reset each match: **Gold** (economic), **Prestige** (legitimacy), **Influence** (political leverage) — conceptually distinct.
- Account-level persist: **Crowns** (premium/cosmetic working name; not competitive match power) and **Lifetime Support** (non-spendable statistic; spending Crowns does not reduce it).
- Prefer procedural/curated naming, not external generative AI. Default realm names on title establishment; custom names optional and must be filterable. Never block establishment for lack of a custom name.
- Simulation performance: store state; calculate on meaningful change; do not poll/recalculate unchanged political info every frame.

## Source layout

- **Server** lives under `ServerScriptService`. `Services/` is reserved for authoritative server-side systems. `Bootstrap.server.luau` is a thin orchestrator only.
- **Client** lives under root-level `StarterPlayerScripts/` on disk, which Script Sync maps to `StarterPlayer.StarterPlayerScripts` in Studio. Do not use a nested `StarterPlayer/StarterPlayerScripts/` disk path. `Controllers/` is reserved for client behavior and GUI control. `Bootstrap.client.luau` is a thin orchestrator only.
- **Shared** lives under `ReplicatedStorage/Shared` (`Config/`, `Types/`, `Util/`). Shared modules must be safe for both sides and must not grant the client authority.
- **Remotes** live under `ReplicatedStorage/Remotes`. That folder is reserved for RemoteEvents and RemoteFunctions. Remote instances are created in Studio, not as Luau files.
- **GUI instances are not source-controlled as files.** They are created and edited through Roblox Studio MCP / Studio. Controllers drive GUI behavior; Services own authoritative state and validation.
- **The client is never trusted** for authoritative game decisions.
- Avoid monolithic scripts. Do not introduce frameworks or external dependencies unless a later decision records that change.

## Project knowledge

- **`AI/GAME_DESIGN.md` is the authoritative product/game vision (design bible v0.1).** Agents must not materially change it unless the user explicitly requests a design change. Unspecified mechanics are not a license to invent systems.
- **`AI/ROADMAP.md` is dependency order.** Do not implement major later-phase gameplay early. **Phase 1 — Foundation & Architecture is complete.** The next intended gameplay work is Political Hierarchy Design V0.1 when directors authorize it — not Phase 2 character simulation by default.
- **Operating rule:** `.cursor/rules/project.mdc` always applies. Before substantial work, read `AI/GAME_DESIGN.md`, `AI/ROADMAP.md`, `AI/PROGRESS.md`, and `AI/DECISIONS.md`.
- Continue using `AI/PROGRESS.md`, `AI/DECISIONS.md`, and `AI/CHANGELOG.md` for state, decisions, and history.
