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

## D-007 Tool and project naming: game is called Overthune (2026-10-24)

- **Decision:** project name `Overthune`, Android package `com.example.overthune` (placeholder prefix).
- **Consequences:** change `package/unique_name` to a real domain-based ID before publishing, since it cannot change after release.
- **Revisit if:** before Milestone 9.

## D-008 Isometric grid: 2:1 diamond, 128x64 px cell, four-direction movement (2026-10-24)

- **Context:** Milestone 1 grid and pathfinding.
- **Decision:** same convention as Godot's isometric "diamond down" TileMapLayer (verified by a test): the top vertex of cell (0,0) is at pixel (0,0), so its centre is at (64,32). x grows down-right, y grows down-left. Tile size is a parameter of `GridMath` with 128x64 as default. Movement and pathfinding use the four grid directions only (no diagonal steps), like Dofus, so one step is one movement point in combat later.
- **Alternatives:** eight-direction movement (smoother paths, but breaks the MP-per-step model).
- **Consequences:** Kenney "Isometric Blocks" tiles are 111x128 px, so they must be scaled or the grid tile size set to match when the TileSet is built.
- **Revisit if:** movement feels stiff on the phone.

## D-009 Input: one tap walks in exploration, two taps in combat (2026-10-24)

- **Decision:** in exploration a single tap on a cell immediately sends a `MoveCommand`. In combat the first tap previews the path or spell area and the second tap confirms.
- **Revisit if:** accidental taps while exploring turn out to be a problem on the phone.

## D-010 Exploration commands and map changes (2026-10-24)

- **Context:** Milestone 1 needs movement and map transitions without breaking rule 1 of `ARCHITECTURE.md`.
- **Decision:** only `MoveCommand` exists. Arriving on an exit cell changes the map as a consequence of the move (`MapChangedEvent`), so a client can never ask to teleport. A separate `ChangeMapCommand` is not needed. `Authority` is minimal: characters, move handling, one seeded RNG. `CharacterState` holds only map id and cell, `WorldState` only flags.
- **Consequences:** only the arrival cell of a path triggers an exit, not cells crossed on the way.
- **Revisit if:** a design needs map changes that are not caused by walking (teleport spell, quest warp). Then add a command for it.

## D-011 Placeholder art: Kenney "Isometric Blocks", CC0 (2026-10-24)

- **Decision:** `assets/art/placeholder/kenney_isometric_blocks/` (kenney.nl, license CC0, 2.7 MB of PNGs) is used for Milestone 1 only.
- **Consequences:** replaced by final art after Milestone 2. No attribution required, license file kept next to the files.
