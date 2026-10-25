# Map format: review and proposal

Status: **proposal for your decision** (review done 2026-10-25, Opus). Nothing here is implemented yet. Decisions that are already agreed are in `DECISIONS.md` (D-016 to D-019).

## 1. What the M1 format is today

- `MapDef` (`src/content/map_def.gd`): id, region, `size` (a W x H diamond of cells starting at 0,0), spawn cell, blocked cells, exits (cells, target map, entry cell), props.
- `Pathfinder` (`src/rules/pathfinder.gd`): `AStarGrid2D` over the rectangle `0..size`, solid cells for obstacles, 4 or 8 directions.
- Map scenes are painted TileMapLayers, made by `tools/build_map_scenes.gd`; `world.gd` and several tests list map ids and file paths by hand.

It works for M1. The review found these problems for the art direction we agreed on (a painted illustration per map, phone in landscape):

| # | Finding | Why it matters |
|---|---|---|
| F1 | **Maps are diamonds.** A 12 x 12 map is a diamond 1536 x 768 px; its exits sit on diagonal edges | A landscape phone screen and a 16:9 AI illustration are rectangles. A diamond wastes the four corners of every picture and every screen, and "east exit" means "down-right" on screen. Dofus maps are screen-shaped rectangles with exits on the four screen edges |
| F2 | `size` assumes a full diamond everywhere | Cannot describe a map whose walkable area is not a full diamond, so every map would be a diamond |
| F3 | `AStarGrid2D` only knows "solid or not" and a weight per cell | It cannot express heights, stairs or ladders: a step between two walkable cells cannot be forbidden or allowed in one direction only |
| F4 | Map ids and file paths are listed by hand in `world.gd`, `style_lab.gd` and tests | Every new map means edits in several places; easy to forget one |
| F5 | Exits are written by hand: cells, target id and entry cell | The pair "east exit of A" and "west exit of B" can disagree, and nothing checks it |
| F6 | Ids like `map.start.01` carry no position | Cannot derive neighbours, cannot prompt the AI with "the map to the east" |
| F7 | `MapDef` is shared and mutable at runtime (open item 5 of the M1 review) | Dynamic changes (a bridge repaired) must live in `WorldState`, never in the map resource |
| F8 | With a painted backdrop, the picture and the cell data can disagree | The player walks into a painted rock, or cannot step on painted grass |

## 2. Proposal

### 2.1 One map = one screen, like Dofus (decision needed)

A map is a **screen-aligned rectangle of the same isometric cells**. The cells stay 128 x 64 diamonds and all game logic stays on the diamond grid we already have. Only the *outline* of a map changes.

- Rows are horizontal screen rows, 32 px apart. Even rows hold **W** cells, odd rows hold **W - 1** cells shifted half a cell to the right, so the map is exactly **W x 128 px** wide.
- Height of the map: **R x 32 + 32 px** for R rows.
- **Recommended default: W = 10, R = 20.** That is 190 cells, 1280 x 672 px, which fills a 1280 x 720 screen at zoom 1 and leaves 48 px for the bottom bar. The backdrop picture at render scale 2 is 2560 x 1344 px (about 3 MB in VRAM after ASTC compression, 14 MB uncompressed).
- Larger maps (towns, dungeon halls) are allowed: the camera then follows the hero as it does now. One-screen maps need no scrolling, and the whole map is visible at minimum zoom.
- Exits sit on the **left, right, top and bottom screen edges**, exactly as the world map coordinates suggest.

Conversion between a row/column of the text file and our diamond cell (x, y):

```
x = (r + 2c + (r mod 2)) / 2
y = (r - 2c - (r mod 2)) / 2
```

Row 0 column 0 is cell (0, 0). Some cells get negative y, which `GridMath`, `TileMapLayer` and the new pathfinder all handle.

**If you prefer to keep diamond maps**, everything else in this document still applies, only exits stay on the diagonal edges and pictures keep their empty corners.

### 2.2 One text file per map is the only source

`content/map_specs/<region>/<cc>_<rr>.txt`, excluded from the Android export. Example (shortened):

```
id: map.hollow.04_07
region: hollow
title_key: map.hollow.04_07.title
size: 10x20
grid:
TT..===..T
T.....=..
..##..=...
......=..
>.....=...
...
heights:
0000000000
000000000
0011100000
...
props:
P1 sign prop.hollow.04_07.sign sign.hollow.04_07.sign
links:
D1 door map.hollow.04_07.in01 entry E1
```

**Grid symbols** (one character per cell; every row has W or W - 1 characters):

| Symbol | Meaning | Walkable |
|---|---|---|
| `.` | ground | yes |
| `,` | ground with low decoration (tall grass, flowers) | yes |
| `=` | path or road | yes |
| `@` | spawn point (also ground) | yes |
| `>` | map exit on a screen edge | yes |
| `#` | rock, wall, any solid obstacle | no |
| `T` | tree or tall object the hero can pass behind | no |
| `B` | building | no |
| `~` | water or pit | no |
| `S` | stairs between two height levels | yes |
| `L` | ladder | yes, with the climb rule |
| `D` | door or entrance to another map (crypt, house) | yes |
| `P` | prop that can be used (sign, chest), listed under `props` | no |

**Heights** are optional (missing means 0). One level is 32 px on screen, the height of one row. Allowed levels 0 to 3.

### 2.3 Movement rules with heights

1. A step between two walkable neighbours is allowed when both have the same height.
2. A stairs cell connects its own level with the level above in the one direction where the neighbour is exactly one level higher. The generator finds that direction and rejects stairs that touch zero or more than one higher neighbour.
3. A ladder cell connects to a neighbour up to 3 levels higher. Moving over it plays a climb animation and costs more time.
4. Diagonal steps never change height, and never cut the corner of an obstacle (as today).
5. Combat keeps the four-direction mode (D-008); the same height rules apply.

**Pathfinder change:** `AStarGrid2D` becomes `AStar2D`, a graph with one point per cell and an explicit connection per allowed step. The public method `find_path(start, goal)` stays the same, so the Authority does not change. Points use the cell coordinates as position, so diagonal steps cost 1.41 and straight steps 1, as today. Ladders get a higher weight.

### 2.4 Exits and links between maps

- **Edge exits:** `>` cells on a screen edge. The neighbour map comes from the coordinates (left edge goes to column - 1, top edge to row - 1, and so on). The entry cell is the matching `>` cell on the opposite edge of the neighbour, one step inward. The generator **checks both maps** and fails if the pins do not line up.
- **Doors, stairs and ladders to another map:** a `links:` line names the symbol (`D1`), the target map id and the entry marker in the target map. Interiors and floors are separate maps (`.in01`, `.up01`, `.dn01`, see D-019).

### 2.5 What the generator produces (one command per map, or all maps at once)

| Output | Path | Committed |
|---|---|---|
| Map data for the game | `content/maps/<region>/<cc>_<rr>.tres` (always regenerated, never edited by hand) | yes |
| Map catalog: every id with its data and scene path | `content/maps/catalog.tres` | yes |
| Godot scene stub: backdrop slot, occluder layer, effects layer, lights layer, switchable cell overlay (walkable, blocked, heights, exits) | `scenes/world/maps/<region>/<cc>_<rr>.tscn` (created once; **never overwritten** unless asked, because you edit it) | yes |
| Blockout picture for the image AI: exact 2560 x 1344 canvas, cells as coloured blocks raised by height, labels for exits, doors, stairs and ladders | `art_source/maps/<id>/blockout.png` | yes (LFS) |
| Prompt text: region style, map id, what lies on each neighbouring edge, where paths cross the edges | `art_source/maps/<id>/prompt.md` | yes |

The AI image is saved by you as `art_source/maps/<id>/backdrop_source.png`. A cleanup step writes the game copy to `assets/art/maps/<id>/backdrop.png`.

### 2.6 Checks the generator runs (and the tests repeat)

- every row has the right length, every symbol is known,
- the spawn exists, every walkable cell can be reached from the spawn,
- every prop symbol has a `props` line and a translation key in `en.po` and `pl.po`,
- stairs and ladders connect exactly what rule 2.3 allows,
- edge exits match the neighbour map, links point to existing maps and entry markers,
- the generated `.tres` files match the text files (no hand edits).

### 2.7 Changes in the code (for the implementation plan)

| Area | Change |
|---|---|
| `src/content/map_def.gd` | `coords`, `cells` (list of all cells), `heights`, `walkable` per cell, `links`; `size` becomes `columns` and `rows`; `is_in_bounds` checks the cell list. Marked read-only at runtime (F7) |
| `src/content/map_exit.gd` | gains a kind (edge, door, stairs, ladder) and an entry marker |
| `src/rules/pathfinder.gd` | `AStar2D` graph with the height rules. Same public method |
| `src/core/grid_math.gd` | row/column conversion from 2.1, height offset in pixels, tap picking that tries the highest level first |
| `src/core/authority.gd` | unchanged logic; reads map ids from the catalog |
| `scenes/world/world.gd` | loads maps through the catalog, draws the character raised by its cell height, keeps sorting by the cell's ground position |
| `scenes/world/camera_rig.gd` | bounds from the map rectangle |
| `tools/maps/` | parser, generator, blockout renderer, prompt writer |
| tests | parser, conversion, height rules, exits pairing, reachability, catalog, generated files up to date |

The two M1 maps are rewritten as text files and get coordinate ids (`map.start.00_00`, `map.start.01_00`). No saves exist yet, so renaming costs nothing now; it would need a migration later.

### 2.8 Order of work

| # | Step | Model |
|---|---|---|
| 1 | Your decisions on the questions below | you |
| 2 | Parser and conversion with tests (no game change yet) | Sonnet |
| 3 | `MapDef` and pathfinder changes with tests | Sonnet, Opus review before merge |
| 4 | Generator outputs: data, catalog, scene stub, blockout, prompt | Sonnet |
| 5 | Rewrite the two start maps as text files, game runs on them | Sonnet |
| 6 | Test map through your image AI, alignment check with the cell overlay | you and Sonnet |

## 3. Questions for you

1. **Screen-shaped maps (2.1) instead of diamonds?** Recommended: yes.
2. **Default size 10 x 20** (fits one screen)? Bigger maps allowed when needed?
3. **One height level = 32 px**, levels 0 to 3?
4. **Interiors and floors as separate maps** (`.in01`, `.up01`, `.dn01`)?
