# Backlog and scope

Priorities: **P1** needed for the current milestone, **P2** next milestone, **P3** later. Move items, do not let this list grow without cutting something.

## First Playable (end of Milestone 5): definition

Included:
- [ ] Village (4-6 maps) and forest (6-8 maps) in final art style
- [ ] Short dungeon (4-5 rooms) with a boss with at least 2 phases
- [ ] 3 regular monster types + 1 boss
- [ ] Tactical combat: placement, initiative, AP/MP, LoS, areas, push, statuses, turn timer
- [ ] Class 1 complete (6 spells), class 2 playable (6 spells)
- [ ] Levels 1-10 with spell unlocks and stat points
- [ ] Inventory, equipment (at least 5 slots), loot, a merchant
- [ ] Main quest chain (5-8 steps, one choice) + 2-3 side quests
- [ ] Dialogue with portraits
- [ ] Save/load with autosave, settings (language, volume, timer, zoom)
- [ ] English and Polish complete
- [ ] Music for village, forest, dungeon, combat. SFX for all actions
- [ ] Title screen, new game, continue, short onboarding
- [ ] Stable 30+ fps on the low-end test phone, no crashes in a 2-hour session

Explicitly **not** in First Playable:
- Professions, gathering, crafting (Milestone 6)
- Co-op (Milestone 3.5 spike only, full in Milestone 7)
- More than 2 classes
- Pets, mounts, companions
- Fast travel, world map beyond a simple region map
- Achievements, collections, codex (simple codex may come with M6)
- Gear sets
- Any monetization, ads, accounts, online features
- Day/night cycle and weather (unless cheap lighting variants in M5 polish)

## Current milestone: M0

| Pri | Item |
|---|---|
| P1 | Install toolchain (Git, Godot 4.7.x, Android SDK, JDK 17, Krita) |
| P1 | Create Godot project in repo root, Compatibility renderer, landscape |
| P1 | First one-click deploy to phone |
| P1 | CI: headless import + parse check + debug APK artifact |
| P2 | Add gdUnit4 and one passing test |
| P2 | Pick a placeholder isometric tileset for M1 |

## Later ideas (P3, parked)

- Harder replay modes for cleared dungeons, with better loot
- Codex/bestiary with discovery layers
- Abilities that open old areas (climbing, diving, light)
- Region-specific weather and festivals
- Companions as AI-controlled fighters
- Housing
- Mounts

## M1 review follow-ups (Opus review of src/core, 2026-10-24)

Findings in `src/core` and `src/state`. Items 1 to 4 were applied with your approval on 2026-10-24; the open ones wait for the milestone named.

| # | Finding | Where | Status |
|---|---|---|---|
| 1 | Authority trusts the `player_id` inside a command (add `sender_id` to `submit`) | `authority.gd` | fixed: `submit(sender_id, command)`, `wrong_player` |
| 2 | `submit(null)` crashes | `authority.gd` | fixed: `invalid_command` |
| 3 | No stable `character_id`; `PLAYER_ID` is hard-coded | `character_state.gd`, `world.gd` | fixed: D-013 |
| 4 | Presentation reads live state and treats every `MovedEvent` as the local player's | `world.gd` | fixed: D-014, GameSession |
| 5 | `MapDef` is shared by reference; pathfinder caches forever (make MapDef read-only at runtime, document in ARCHITECTURE) | `authority.gd` | open |
| 6 | Input could lock if a walk is cut short | `player_actor.gd`, `world.gd` | fixed in step 7, with a test |
| 7 | A loaded save with a blocked cell or missing map leaves the character stuck | save loader (later) | open, for M4 |
| 8 | No `to_dict`/`from_dict`; RNG state is not saved | state classes (later) | open, for M4 |
| 9 | `assert` for map validation is removed in exported builds | `world.gd` | fixed in step 7 |
| 10 | Some untyped dictionaries, state handed out mutable | `authority.gd` | open |

## Step 8 review notes (Opus, 2026-10-25)

Verdict: fine to merge. Fixed right away: a prop's `kind` is now validated. Left for later:

- Text box keeps its language if the language is switched while it is open. Handle with the live language switch in M4.
- Android Back button while a text box is open should close the box, not leave the game. M4, with menus.
- The way to a sign is chosen by fewest steps, not by exact distance, so a diagonal detour can win a tie. Not noticeable now; revisit only if it looks odd.

## Map generator review notes (Opus, 2026-10-25)

Verdict: fine to merge after one fix. Fixed right away: plants in front of trees beside a building were not checked against the building strips and could be cut by a strip edge (now checked like the plants at the building, with a test). Left for later:

| # | Finding | When | Status |
|---|---|---|---|
| 1 | **Memory and quality on the phone.** One map is about 42 MB of uncompressed textures: ground, building, mist and light are full-screen pictures of about 6 MB each, kit pieces keep the full AI resolution although they are drawn at 25 to 45 % of it, and there are no mipmaps, so foliage can shimmer when the camera moves. Fix in `prepare_map_assets.gd`: scale kit pieces down to what zoom 1.6 needs, mist and light to half resolution, VRAM compression (ETC2/ASTC) for Android. Measure before and after. | M2 phone test | open |
| 2 | **Big pictures in plain git.** `assets/` is in normal git (by the rule in `.gitattributes`). Every new version of a ground or building picture adds megabytes to the history for good. Decide whether `assets/art/**` moves to Git LFS before maps 2 and 3 (your decision; it changes the repository rule). | before maps 2 and 3 | open, your decision |
| 3 | `generate.gd` dresses only the building symbol `B` (written in the code). | when a second building type appears | open |
| 4 | The game stops without a readable message if the catalog lacks a map or a scene path (a test keeps the real catalog valid). | M4, with error screens | open |
| 5 | `MapSpec` prints untyped-Variant warnings. | any time | open |
| 6 | The dressing seed is the built-in hash of the map id; another Godot version could change it. It only affects dressing again, not the game. | if it ever happens | open |
| 7 | The script parse check sometimes fails on a random test file right after new pictures were added, before they were imported. Probably a race with the import; CI imports first and is not affected. Not confirmed. | watch | open |
