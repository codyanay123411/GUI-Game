# Repository Guidelines

## Project Structure & Module Organization

This GUI-first Roblox strategy game stores Luau source on disk and syncs it into Studio with Script Sync.

- `ServerScriptService/Services/`: authoritative gameplay and admin services; `Bootstrap.server.luau` starts them in dependency order.
- `StarterPlayerScripts/Controllers/`: client presentation and input; `Bootstrap.local.luau` is the LocalScript entry point. This directory maps to Studio’s `StarterPlayer.StarterPlayerScripts`.
- `ReplicatedStorage/Shared/`: reusable `Config/`, `Types/`, and `Util/` modules.
- `ReplicatedStorage/Remotes/`: folder placeholder; actual remotes are Studio instances.
- `docs/ARCHITECTURE.md` and `AI/`: architecture, design, roadmap, progress, decisions, and verification backlog.

GUI instances and place assets live in Studio, not filesystem source. Local `.rbxl`/`.rbxlx` files and generated Kohl admin modules are ignored.

## Build, Test, and Development Commands

No command-line build scripts, automated test runner, or formatter/linter configuration are checked in.

- Sync `.luau` files through Script Sync before running the place.
- Use Studio **Play** for local behavior and **Local Server** with multiple clients for multiplayer verification. Inspect server and client Output for errors.
- Run `git diff --check` to catch whitespace errors and `git diff` to review changes before handoff.

Keep `Bootstrap.local.luau`; replacing it with `Bootstrap.client.luau` can cause duplicate execution in this location.

## Coding Style & Naming Conventions

Follow existing Luau style: `--!strict`, tab indentation, double-quoted strings, explicit types where practical, and early validation returns. Use PascalCase module names with descriptive suffixes, such as `EconomyService`, `EconomyController`, and `EconomyConfig`; use camelCase locals. Keep bootstraps thin and systems modular.

Validate client requests on the server. Filter ordinary UI to player-relevant information. Route admin mutations through `AdminBridge` and existing service APIs.

## Testing Guidelines

There is no dedicated test directory, framework, or coverage threshold. Verify changed behavior before requesting Director testing; include rejected requests, cleanup, and multiplayer state consistency where relevant. Record evidence and limitations. Use scenario IDs such as `MIL-MP-01` in `AI/PLAYTEST_BACKLOG.md`. Deferred tests are not passes; agent verification is not Director acceptance.

## Commit & Pull Request Guidelines

History uses imperative, descriptive subjects, such as `Implement Economy V0.1 Gold foundation`. Follow that style. PRs should describe scope, affected systems, verification, outstanding cases, and linked issues when applicable; include screenshots for GUI changes. Do not commit or push unless requested.

## Design & Documentation

Before substantial work, read `.cursor/rules/project.mdc` and the design, roadmap, progress, and decision files in `AI/`. Preserve approved scope. After substantial verified work, update progress, append meaningful changes to the changelog, and record significant architectural decisions.
