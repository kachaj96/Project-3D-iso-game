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

## D-006 Art direction and pipeline (direction and character pipeline decided, environment method pending)

- **Context:** you do not paint and rely on AI tools; characters must work in 8 directions; budget up to about $20 per month.
- **Decided 2026-10-25:** visual direction A, "dark fairytale": Dofus shapes and readability, gothic mood carried by light and palette. Chosen from three directions (A dark fairytale, B painterly gothic, C dark pixel art) after a generated sample. Style rules are in `ART_PIPELINE.md`.
- **Dropped:** the cutout rig painted in Krita, because it needs painting skill and multiplies work per direction.
- **Decided 2026-10-25 after the bake-off:** characters and monsters are rendered from 3D into 2D sprites, see D-016 and D-017. The environment method (one painted backdrop per map, or modular assets) is decided after the test map described in `MAP_FORMAT.md`.

## D-007 Landscape orientation (2026-10-24)

- **Decision:** landscape only. Isometric maps are wider than tall and combat UI needs horizontal space.

## D-007b Tool and project naming: game is called Overthune (2026-10-24, number shared with D-007 by mistake)

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

## D-016 The game is 2D; characters are rendered from 3D (bake-off result, 2026-10-25)

- **Context:** you do not paint, characters need 8 directions and several animations, budget about $20 a month. Bake-off on free plans of Meshy, Tripo and Mixamo, details in `ART_PIPELINE.md`.
- **Decision:** everything in the game is 2D: sprites, map pictures, Godot 2D lights. Characters and monsters are made like this:
  1. concept image from an AI image tool, following the style rules, checked at 120 px next to the reference (`tools/art/compare_with_reference.gd`),
  2. image to 3D model (Tripo or Meshy; no PBR, lighting removed, about 20k triangles),
  3. rig and clips in Mixamo (free, your Adobe account),
  4. Blender toon render into sprites (`tools/blender/render_sprites.py`), checked on contact sheets.
- **Measured:** concept 36 to 40 credits for four images; model 15 to 25 credits and about 60 s; Mixamo about 10 minutes of your time; render of one clip in 8 directions and 8 frames about 70 s.
- **Rejected:** AI drawing frame by frame (the character changes between frames and directions); Tripo's rig on the free plan (the GLB skeleton is damaged, the FBX has none); a painted cutout rig (needs painting skill).
- **Shipping rule:** nothing made on a free plan goes into the released game. Before an asset is final, it is made again on a paid plan whose terms give you the rights (both vendors state this for paid plans; re-check then).
- **Revisit if:** on the phone the characters still read as 3D figurines after the M2 slice, or the animation library lacks a needed move.

## D-017 Character sprite standard (2026-10-25)

- **Size:** the hero is 120 project px tall at zoom 1, rendered at scale 2 (240 px body) in **320 x 320** frames. Feet anchor at **(160, 262)**. Light from the top-left, fixed for every direction.
- **Directions:** 8 (S, SW, W, NW, N, NE, E, SE, clockwise from facing the camera). No mirroring for the hero and important characters: mirroring would light them from the wrong side and swap one-sided gear. Symmetric NPCs and monsters with flat shading may be mirrored to save memory.
- **Clips:** idle 6 frames at 7 fps, walk 8 at 14, attack 8 at 15, hit 4 at 14, death 10 at 11, interact 6 at 11 (ranges in `ART_PIPELINE.md`, "Clip timing"). Unique frames, FPS and duration are designed separately: duration first, from game feel.
- **Files:** frames `<entity>_<clip>_<dir>_<nn>.png`; sheet per clip with one row per direction; a manifest per sheet with frame size, FPS, loop, hit frame and anchor; Godot `SpriteFrames` generated from it. 2 px empty border per frame, straight alpha, no baked ground shadow, in-place clips only.
- **Look parameters:** saturation 1.2, value 1.08, shadow 0.58, outline 0.03 in a dark blue-brown tint.
- **Memory:** about 0.39 MB per raw frame, about 130 MB raw for 336 hero frames. Trimming and texture compression are mandatory; the compression quality on outlines is checked on the phone in M2.

## D-018 Movement timing and zoom (2026-10-25)

- **Decision:** every step from one cell to the next takes the same time, **0.28 s**, whatever the direction (a step is 64 to 128 px long on screen depending on the direction). One walk cycle is two steps, 0.56 s, 8 frames at about 14 fps. Maximum zoom becomes **1.6** instead of 2.0, because sprites are rendered at scale 2.
- **Status:** agreed, not yet in the code (comes with the render upgrade).

## D-019 Map ids and world coordinates (2026-10-25)

- **Decision:** surface maps are `map.<region>.<cc>_<rr>`: `cc` is the column (grows to the east, the right of the screen), `rr` the row (grows to the south, the bottom of the screen), both counted inside the region from 00 at its north-west corner. Interiors `.in01`, floors above `.up01`, below ground `.dn01`, for example `map.hollow.04_07.dn01`. Neighbours follow from the coordinates.
- **Consequences:** the two M1 maps get coordinate ids when the new map format lands. There are no saves yet, so this needs no migration.
- **Open:** the shape of a map and the map file format are a proposal in `MAP_FORMAT.md`, waiting for your answers.

## D-020 Map shape, map files and levels (2026-10-25)

- **Context:** review of the M1 map format in `MAP_FORMAT.md` (findings F1 to F8).
- **Decision:**
  - A map is a **screen-shaped rectangle** of the same 128 x 64 isometric cells, by default **10 x 20** (190 cells, 1280 x 672 px, one landscape screen at zoom 1). Bigger maps are allowed when needed and the camera follows the hero there. Exits sit on the left, right, top and bottom screen edges.
  - **One text file per map** is the only source. A generator writes the game data, a map catalog, a Godot scene stub (written once, then yours to edit), a blockout picture and a prompt for the image AI, and checks the map (reachability, matching exits with neighbours, stairs and ladders, translation keys).
  - **Levels 0 to 7**, 32 px each. Stairs climb one level per cell; a ladder climbs up to 4 levels (one storey). Galleries, lofts and platforms stay on the same map; separate rooms are separate maps. A door or exit can sit on any level.
  - The pathfinder becomes an `AStar2D` graph that knows these rules; its public method stays the same.
- **Alternatives:** diamond maps (what M1 has: wasted picture corners, diagonal exits); a separate map for every upper level (simpler code, but you want to climb inside one map).
- **Consequences:** the two M1 maps are rewritten as text files with coordinate ids. `MapDef`, the pathfinder and `GridMath` change, so an Opus review comes before merging.
- **Revisit if:** the 10 x 20 cell size is too small to tap on the phone, or high platforms hide too much of the map.

## D-021 How levels are implemented (2026-10-25)

- **Context:** first implementation of D-020 (map format step 2).
- **Decision:**
  - The level rules live in one class, `LevelRules`, used by both map validation and the pathfinder. A stairs or ladder cell has the level of its lower end and leads up from there; the step back down is allowed because every step is symmetric.
  - `heights` and `cell_kinds` are sparse dictionaries (only cells that differ from level 0 and from a plain cell are stored), so flat maps cost nothing.
  - `MapDef.shape` keeps the two M1 diamond maps working next to screen-shaped maps until they are rewritten as text files; then `DIAMOND` is deleted.
  - Ladders weigh 3 in the path search, so a route prefers stairs unless a ladder is much shorter or the only way.
  - The character node stays on the ground position and only its picture is raised, so Y-sorting is unchanged. Taps try the highest level first.
  - Using an object (a sign) needs a level difference of at most 1.
  - A diagonal step may not cut the corner of an obstacle or of a higher cell; a lower cell beside it is fine (Opus review).
  - Stairs and ladders climb only along the isometric axes (toward the row above or below on screen), because a diagonal step never changes level.
- **Alternatives:** raise the whole character node (breaks the drawing order behind obstacles); a height number on every cell in `MapDef` (large files, no benefit).
- **Consequences:** nothing visual changes on the two M1 maps. New behaviour appears only on maps that use heights.
- **Revisit if:** tall platforms hide walkable cells (the generator will warn), or ladders need a different cost.
