# Technical architecture

Godot 4.7, typed GDScript, Compatibility renderer, Android landscape.

This document describes the minimum architecture plus the few rules that are expensive to change later. Systems are added only when their milestone starts. If a section says "later", do not build it yet.

## 1. The core idea: rules separate from presentation

```
 Touch input / UI                 Godot scenes (nodes, sprites, animations, sounds)
        |                                         ^
        v                                         |
   Command  ------>  Authority  ------>  Events  -+
 (what a player     (validates, applies   (what happened:
  wants to do)       rules to GameState)   "unit 3 moved", "12 damage")
                           |
                           v
                      GameState (plain data: characters, world, combat)
```

- **GameState** is plain data: typed GDScript classes extending `RefCounted`, plus Resources for static content. No nodes, no sprites, no timers.
- **Rules** (combat, inventory, crafting, quests) are functions that take state and a command, change the state, and return a list of events.
- **Presentation** (scenes, nodes) never changes game state directly. It sends commands and plays events back as animations, numbers and sounds.

Why this matters:

1. **Testable.** Combat rules can be unit-tested headless, and a headless balance simulator can run thousands of fights.
2. **Co-op becomes a transport problem.** In single-player the Authority runs locally. In co-op the host runs it, the client sends commands over the network and receives events. The rules code does not change.
3. **Save/load is trivial.** Saving means serializing GameState, not walking a scene tree.

Do not overdo it: menus, camera, settings and pure visual effects do not need commands.

Scenes never call the Authority directly. They talk to a `GameSession` (`send(command)`, signal `events_emitted`). `LocalSession` runs the Authority on the same device; a network session will do the same over Wi-Fi. The Authority receives the sender id from the session or transport, never from the command. See D-013 and D-014.

## 2. Rules that are expensive to change later

These are the decisions that would force a rewrite if skipped. Each one is cheap now.

1. **Every gameplay change goes through a command.** `MoveCommand`, `CastSpellCommand`, `UseItemCommand`, `TalkCommand`, `HarvestCommand`, `CraftCommand`. Each carries `player_id`.
2. **One authority owns the RNG.** All gameplay randomness uses a seeded `RandomNumberGenerator` held by the Authority. Presentation may use `randf()` only for cosmetic effects (particle jitter).
3. **Stable string IDs everywhere.** Items, spells, monsters, maps, NPCs and quests are referenced by IDs like `"item.iron_sword"` or `"map.hollow_wood.04"`. Never by node path, array index or display name. Saves and network messages only contain IDs.
4. **Player data is separate from world data.**
   - `CharacterState`: class, level, stats, spells, equipment, inventory, professions, quest progress, currency. Owned by one player and saved in that player's character file.
   - `WorldState`: map flags, gathered nodes and respawn timers, opened chests, world events, NPC state. Owned by whoever hosts.
   In co-op the guest brings their character file, and the world belongs to the host.
5. **Combat supports many controlled units from day one.** A fight has teams and fighters, and each fighter has a `controller` (`player:<id>`, `ai`, later `summon`). Single-player simply has one player-controlled fighter. Hard-coding "the hero" into combat is the single most expensive mistake to undo.
6. **Content is data, versioned.** Items, spells, monsters, recipes and quests are Resources with IDs. In co-op, both devices compare a content version hash during the handshake.
7. **All visible text is a translation key.** `tr("ui.inventory.title")`, never `"Inventory"` in code. Never build sentences by concatenation. Use placeholders: `tr("combat.damage_taken").format({"amount": 12})`. Plurals go through `tr_n`.
8. **The clock is gameplay data, not frame time.** Respawn timers and world events use the in-game clock held in WorldState, so a host and a client agree.

## 3. Project layout

```
project.godot
addons/                    third-party addons (Dialogue Manager, gdUnit4)
assets/
  art/                     exported PNGs used by the game (small, regular git)
  audio/
  fonts/                   must contain Polish glyphs (ą ć ę ł ń ó ś ź ż)
art_source/                .kra/.psd/.blend source files (Git LFS)
content/                   game data as .tres resources, grouped by type
  classes/  spells/  items/  monsters/  maps/  npcs/  quests/  recipes/  loot/
dialogue/                  .dialogue files (Dialogue Manager)
localization/              en.po, pl.po (+ .pot template)
src/
  core/                    Authority, command and event base classes, ids, rng, clock
  state/                   CharacterState, WorldState, CombatState, Inventory
  rules/                   combat/, inventory/, crafting/, quests/, progression/
  content/                 Resource class definitions (ItemDef, SpellDef, MonsterDef...)
  save/                    save/load, migrations
  net/                     later: transport, discovery, session
scenes/
  boot/  world/  combat/  ui/  common/
tests/                     gdUnit4 tests, mostly against src/rules and src/state
tools/                     editor scripts, balance simulator
docs/
```

Naming: `snake_case` for files and folders, `PascalCase` for classes (`class_name SpellDef`), `snake_case` for functions and variables. Every script uses static types (`var hp: int`, `func cast(spell: SpellDef) -> Array[GameEvent]`).

## 4. World and exploration

- **Map screens like Dofus.** Each map is one scene: an isometric `TileMapLayer` for ground, one or more layers for decoration, Y-sorted props, and exit zones on the edges. A `MapDef` resource lists the map's ID, region, neighbours (N/E/S/W exit to map ID + entry cell), music, ambient light and spawn groups.
- **One cell grid for everything.** Exploration and combat use the same isometric cell coordinates. Fights happen on the map you are standing on, with combat placement cells defined per map, like Dofus. No separate arena scene per fight, which saves a lot of content work.
- **Movement:** tap a cell, A* pathfinding on the cell grid (`AStarGrid2D`), the character walks the path. Tapping an NPC, resource node or monster group walks to it and interacts.
- **Regions** are groups of maps with their own palette, music, monsters and lighting profile.
- **Camera:** fixed isometric, pinch zoom with clamped min/max, follows the player, clamped to map bounds.
- **Dungeons** are linear chains of maps with a fight in each room and a boss at the end. Built from the same map scenes.

## 5. Combat

Data:
- `CombatState`: grid (walkable cells, line-of-sight blockers), fighters, turn order, round number, active fighter, pending effects.
- `Fighter`: id, team, controller, cell, stats (HP, AP, MP, resistances, initiative), active effects, spell cooldowns.
- `SpellDef`: AP cost, range min/max, needs line of sight, area shape, cooldown, casts per turn, and a list of `EffectDef` (damage, heal, push, pull, teleport, apply status, summon...).

Rules:
- Placement phase, initiative order, turns with AP/MP, a turn timer (configurable, generous on mobile).
- Line of sight via Bresenham-style cell tracing.
- Effects are small composable pieces. A new spell should usually be new data, not new code.
- Monster AI is a simple scored decision: for each reachable cell and each castable spell, score the result (damage dealt, danger, distance to preferred range) and pick the best. Bosses get scripted phases on top.

Touch UI:
- Tap a cell once to preview the path or spell area, tap again to confirm. No accidental casts.
- Spell bar at the bottom, end-turn button with a clear state, timeline of turn order at the top.
- Minimum cell size on screen must stay finger-friendly at default zoom. Test on the real phone, not only the PC.

## 6. Characters and progression

- `ClassDef`: name key, art set, base stats, stat growth, a spell list with unlock levels.
- 4-6 classes eventually, each with a clear tactical identity (see `GDD.md`). The first playable has one fully done class plus a second one to prove the class system.
- Level cap rises with content releases. XP curve tuned so the main path plus side content covers each region's level band, with no grind wall (see GDD).
- Characteristic points and spell upgrades as build choices. Respec is cheap so experimenting is encouraged.

## 7. Items, inventory, loot

- `ItemDef`: id, type (equipment, resource, consumable, quest, key), slot, level, stats (fixed or ranges), set ID, icon, value, stack size.
- Inventory is a list of stacks `{item_id, count, instance_data}`. `instance_data` holds rolled stats for equipment.
- Loot tables are data: entries with chance, count range and conditions.
- **Co-op rule decided now:** each player gets their own loot roll per fight. A personal "luck" style stat raises your own chances only. No shared pool to fight over. This avoids the abuse problem you mentioned and means the loot code does not change for co-op.

## 8. Gathering, crafting, professions

- `ResourceNodeDef`: id, profession, level required, yields (loot table), respawn time.
- Node instances live in WorldState with their respawn timer.
- `ProfessionDef`: gather or craft, XP curve, unlocks.
- `RecipeDef`: profession, level, ingredients, result, XP.
- Economy sinks come later: repair or upgrade costs, consumables, crafting with resources from several regions, merchants that buy at lower prices than they sell.

## 9. Quests and dialogue

- `QuestDef`: id, steps. Each step has objectives (talk to, kill N of, gather, deliver, reach map, win fight) and rewards. Branches are steps with alternative next steps.
- Quest progress lives in CharacterState. A quest event system listens to game events ("monster killed", "item gained", "map entered") and advances objectives.
- Dialogue is written in Dialogue Manager `.dialogue` files. Dialogue can read and set quest state through a small set of functions (`quest.is_on_step("q.main.01", 2)`), not by poking at arbitrary game objects.
- World flags in WorldState drive environmental changes (a bridge repaired, a fog lifted).

## 10. Save and load

- Two files: `characters/<character_id>.json` and `worlds/<world_id>.json` in `user://`.
- JSON with a `version` field and a migration function per version bump. Every migration gets a test.
- Autosave on map change and after fights, plus a manual save. Write to a temp file and rename, so a crash mid-save cannot corrupt the save.
- Settings (language, volume, zoom, turn timer) live in a separate `settings.cfg`.

## 11. Localization

- Source language English. Polish translated by you (with AI help) and reviewed by you.
- `localization/en.po`, `localization/pl.po`, template `.pot` generated from code and dialogue files.
- Fonts with Polish characters from day one. Layouts must survive text that is about 30% longer, since Polish strings are often longer than English.
- Language switch in settings, applied live.

## 12. Co-op (later, Milestone 9)

Only for reference now, so earlier code does not block it.

- Host-client. The host runs the Authority for world and combat. Each player's character file stays on their own device. The guest sends their CharacterState to the host when joining and receives updates back to save locally.
- Clients send commands. The host validates them (is it your turn, do you have the AP) and broadcasts events.
- Exploration: both players on the same map, or on different maps of the host's world. Fights started by either player can be joined by the other if on the same map.
- Quest progress stays per character. Shared kills credit both players if both took part.
- Disconnect handling: the client falls back to the main menu with its character saved. The host continues alone.

## 13. What is deliberately not in the architecture

- No entity-component framework, no dependency injection framework, no event bus library. Godot signals plus the command/event pattern are enough.
- No server, no accounts, no online services.
- No procedural generation of maps. Hand-made maps are the identity of this genre.
- No generic "modding" layer.

If a future change seems to need one of these, write it up in `DECISIONS.md` first.
