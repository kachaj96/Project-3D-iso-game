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
- **Decision:** same convention as Godot's isometric "diamond down" TileMapLayer (verified by a test): the top vertex of cell (0,0) is at pixel (0,0), so its centre is at (64,32). x grows down-right, y grows down-left. Tile size is a parameter of `GridMath` with 128x64 as default. Exploration movement uses eight directions (grid steps and diagonals), like Dofus outside fights, and a diagonal step is never allowed across the corner of an obstacle (amended 2026-10-24 at your request). The pathfinder keeps a four-direction mode for combat, where one step should be one movement point; how combat movement works is decided in M3.
- **Alternatives:** four directions everywhere (simplest, but stiff when exploring); diagonals in combat too (shorter routes, but harder to read ranges and MP costs).
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

## D-012 Touch input: tap registers on release, pinch zooms, camera stays inside the map (2026-10-24)

- **Context:** M1 step 7. A press that becomes a pinch must not send the character walking.
- **Decision:** the project turns off "emulate mouse from touch" and turns on "emulate touch from mouse", so phone touches and PC clicks arrive as the same touch events and one code path serves both. A tap is a press that is released within 350 ms and moves at most 24 px, with no second finger involved. Two fingers zoom (factor = new finger distance / old distance). The mouse wheel zooms in steps of 10 percent on PC. D-009 stays true: a tap walks at once, with no confirm, but it is registered on release, not on press.
- **Camera:** follows the character with a short glide, stays inside the map rectangle plus a 64 px margin for block height. Zoom is limited to max 2.0 and to a minimum that always fills the screen with map.
- **Revisit if:** taps feel late on the phone (shorten or drop the release rule), or a long press is wanted for something.

## D-013 Two ids per character: character_id and player_id (2026-10-24)

- **Context:** Opus review of M1. Every device called its player "player:1", which collides as soon as a guest joins or saves exist.
- **Decision:** `character_id` (format `char.` + 16 hex characters, from the system's secure random source, not the game RNG) is created once with the character, never changes and names the save file `characters/<character_id>.json`. `player_id` (`player:1`, `player:2`) is the seat in the current session, assigned by the host each game; commands and combat controllers use it. The Authority refuses a taken seat, a character that is already present and an unknown map.
- **Consequences:** the save format in M4 stores `character_id`, not `player_id`. Until saves exist, each start creates a new character.

## D-014 The screen talks to a GameSession, never to the Authority (2026-10-24)

- **Context:** Opus review of M1. On a co-op guest there is no local Authority, and events arrive later over the network.
- **Decision:** `GameSession` (`src/core`) has `send(command)` and one signal `events_emitted(events)`. `LocalSession` runs the Authority on this device (solo, later the co-op host); a future `NetworkSession` will forward commands to the host and emit the events it receives. The Authority's `submit(sender_id, command)` takes the sender from the session or transport and rejects a command whose `player_id` differs (`wrong_player`). Scenes place and move characters only from events (`CharacterSpawnedEvent`, `MovedEvent`, `MapChangedEvent`) and never read `CharacterState`.
- **Consequences:** until M3.5 the exploration scene ignores events of other players; from M3.5 it routes them to those players' characters.
- **Revisit if:** the network spike in M3.5 shows events need ordering numbers or acknowledgements.

## D-015 Objects on maps and using them (2026-10-24)

- **Context:** M1 step 8, a sign that shows text.
- **Decision:** a map lists its objects as `MapProp` resources (stable id like `prop.start.welcome_sign`, kind, cell, `text_key`). A prop's cell is always also in `blocked_cells`, so nobody walks through it. Using a prop is an `InteractCommand`; the Authority walks the character to the nearest free cell beside it (never an exit cell) and then answers with an `InteractedEvent`. If the character already stands beside it, nothing moves. The scene shows the text only after the walk ends and only through `tr(text_key)`; a test requires every key to exist in `en.po` and `pl.po`.
- **Consequences:** `tools/paint_props.gd` paints props onto existing map scenes without touching hand-painted tiles. The sign picture is a placeholder block. The wording of the sign is placeholder text for you to rewrite.
- **Revisit if:** props need states (a chest that opens), then they move into `WorldState`.
