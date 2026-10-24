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

- Echo mode for dungeons (harder replays with better loot), from Natalis
- Codex/bestiary with discovery layers, from Natalis
- Abilities that open old areas (climbing, diving, light), from Natalis
- Region-specific weather and festivals
- Companions as AI-controlled fighters
- Housing
- Mounts
