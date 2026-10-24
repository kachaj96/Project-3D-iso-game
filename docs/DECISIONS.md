# Decision log

One entry per decision that would be costly to reverse. Newest at the bottom. Format: context, decision, alternatives, consequences, revisit trigger.

## D-001 Engine: Godot 4.7 with typed GDScript (2026-10-24)

- **Context:** 2D isometric tactical RPG for Android, solo beginner using Claude Code, local Wi-Fi co-op later. Full comparison in `RESEARCH.md`.
- **Decision:** Godot 4.7.x stable, standard (non-.NET) build, typed GDScript, Compatibility renderer.
- **Alternatives:** Unity 6 (heavier, scene files not AI-editable), JavaScript web stack (no editor, no lighting, plugin-based networking), Unreal (wrong fit).
- **Consequences:** you learn the Godot editor. Claude must be kept on Godot 4 APIs.
- **Revisit if:** the editor is still a blocker at the end of Milestone 2, or a hard technical limit appears on Android.

## D-002 Rules separated from presentation, command/event architecture (2026-10-24)

- **Context:** co-op later, testability, save/load.
- **Decision:** see `ARCHITECTURE.md` sections 1-2.
- **Consequences:** a little more structure in Milestone 1 and 3, much cheaper co-op and tests.
- **Revisit if:** never without a written reason.

## D-003 Per-player loot rolls (2026-10-24)

- **Context:** co-op loot fairness, avoiding abuse of a shared pool weighted by a stat.
- **Decision:** each player rolls their own loot. A luck-type stat affects only your own rolls.
- **Revisit if:** playtests show co-op loot feels unrewarding.

## D-004 Fights happen on the current map's cell grid (2026-10-24)

- **Context:** content cost. Separate arena scenes double map work.
- **Decision:** every map defines placement cells and is its own battlefield, like Dofus.
- **Revisit if:** some maps are unplayable as battlefields, then those maps get a dedicated arena.

## D-005 Localization via gettext PO, English source, Polish from day one (2026-10-24)

- **Decision:** all text via keys, `tr_n` for plurals, `.po` files.

## D-006 Art pipeline (pending, Milestone 2)

- **Proposal:** cutout rigs for characters, AI-assisted painting plus manual cleanup for environments. See `ART_PIPELINE.md`.
- **To decide after the spike, with measured time per asset.**

## D-007 Landscape orientation (2026-10-24)

- **Decision:** landscape only. Isometric maps are wider than tall and combat UI needs horizontal space.
