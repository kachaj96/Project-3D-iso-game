# Project rules for Claude Code

Isometric tactical RPG for Android, inspired by Dofus, darker tone. Solo developer who is a beginner programmer: explain what you do in plain language and keep changes small.

Read before any non-trivial task: `docs/ARCHITECTURE.md`. Current plan and milestone: `docs/ROADMAP.md` and `docs/BACKLOG.md`.

## Engine and language

- **Godot 4.7.x, typed GDScript, Compatibility renderer.** Never use Godot 3 APIs. Examples of forbidden Godot 3 names: `KinematicBody2D`, `yield`, `export var`, `onready var`, `TileMap` (use `TileMapLayer`), `instance()` (use `instantiate()`), `connect("signal", obj, "method")` (use `signal.connect(callable)`).
- Static types on every variable, parameter and return value.
- No C#, no GDExtension, no new addons without asking.

## Architecture rules (do not break without asking)

1. Gameplay state changes only through commands handled by the Authority. Presentation never mutates game state.
2. Rules live in `src/rules` and `src/state` as `RefCounted` classes with no node dependencies, so they can be unit tested headless.
3. All gameplay randomness uses the Authority's seeded RNG.
4. Content is referenced by stable string IDs, never node paths or indices.
5. `CharacterState` (per player) and `WorldState` (per world) stay separate.
6. Combat fighters have a `controller`. Never assume a single hero.
7. Every player-visible string uses `tr()` / `tr_n()` with a key. Add the key to `localization/` in both English and Polish. Never concatenate translated fragments.
8. Saves are versioned. Changing a saved structure requires a migration and a test.

## Workflow

- Inspect relevant files and propose a plan before writing code. Wait for approval on anything touching `src/core`, `src/state`, save format or more than ~5 files.
- Prefer small, focused changes. Do not refactor unrelated code.
- Add or update gdUnit4 tests for every rule change.
- Verify before reporting done: run the headless import/parse check and the tests, and show the result. If you cannot verify something (feel, visuals, phone behavior), say so and tell the developer exactly how to check it.
- Tell the developer which steps must be done manually in the editor.
- Never commit keystores, passwords or API keys.

## Communication style

Direct, no filler, no em dashes. Mentor mode when reviewing ideas: point out failure points before agreeing.
