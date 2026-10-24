# Roadmap

Assumes 2-3 hours a day, about 15-20 hours a week. Estimates are honest ranges for a beginner working with Claude Code. Expect the first two milestones to be slower than the estimates while you learn the editor, and the later ones to be faster.

Every milestone ends with an APK on your phone and a short play session. Nothing moves forward on "it compiles".

| # | Milestone | Estimate | Cumulative |
|---|---|---|---|
| 0 | Setup and hello-phone | 1 week | 1 week |
| 1 | Isometric exploration prototype (placeholder art) | 3-4 weeks | ~1.2 months |
| 2 | Art style spike | 2-3 weeks | ~2 months |
| 3 | Tactical combat core | 6-8 weeks | ~4 months |
| 3.5 | Co-op network spike (throwaway) | 1-2 weeks | ~4.5 months |
| 4 | Core loop slice: village, forest, rewards, save/load, EN/PL | 8-10 weeks | ~6.5 months |
| 5 | **First Playable**: quest chain, dungeon, boss, second class, polish | 8-10 weeks | **~8.5-9 months** |
| 6 | Professions, gathering, crafting, economy v1 | 5-7 weeks | ~10.5 months |
| 7 | Co-op v1 over local Wi-Fi | 6-8 weeks | ~12.5 months |
| 8 | Content cycle: region 2 | 8-12 weeks per region | ongoing |
| 9 | Release preparation (if and when you choose) | 4-6 weeks | when ready |

Changes from the sequence you proposed, and why:

- **Art spike moved early (M2).** Art is the biggest risk. Finding out in month 6 that the pipeline does not work would waste most of the content made by then.
- **A small co-op spike right after combat (M3.5).** It costs 1-2 weeks and proves the command/event architecture works over a network before you build months of content on top of it. Full co-op stays late.
- **Save/load and localization move into M4.** Both get much harder to add once there are many systems and strings.
- **Professions come after the First Playable (M6).** Your proposed first milestone (village, forest, three enemies, quest chain, boss, combat) is the right first target. Professions are a big system and deserve their own milestone.

---

## Milestone 0: Setup and hello-phone

**What you build:** a working toolchain and an empty Godot project that runs on your phone, with CI producing an APK.

**Why it matters:** every later milestone depends on a fast loop of edit, run on PC, run on phone. Fix toolchain problems now, while nothing else is in the way.

**Tools:** Git, GitHub, Godot 4.7.x (standard build, not .NET), Android Studio (only for the SDK and platform tools), JDK 17, Claude Code, Krita.

**What you need to learn:**
- Godot editor basics: the FileSystem, Scene and Inspector docks, running a scene, the Output panel.
- What a node, scene and script are.
- Android: enabling Developer options and USB debugging, installing an APK.
- Git basics you probably already know: commit, push, branch, revert.

**How Claude Code helps:**
- Writes `.gitignore`, `.gitattributes` (Git LFS), the CI workflow and the first `CLAUDE.md` additions.
- Explains any error you paste from the Godot Output panel or Android export.

**What you do manually in the editor:**
- Create the project (Compatibility renderer), set the main scene, set Android export presets, set orientation to landscape, configure the Android SDK path in Editor Settings.
- Generate a debug keystore and do the first one-click deploy.

**Expected result:** a Godot scene with a colored background and a "Hello" label running on your phone. Pushing a commit produces an APK artifact on GitHub.

**How to test:** run on PC (F5), one-click deploy to phone, download the CI APK and install it on the phone.

**Common mistakes:**
- Installing the .NET edition of Godot. Use the standard one.
- JDK version mismatch with Gradle ("Unsupported class file major version"). Use the JDK version the Godot Android export docs name for your version.
- Committing the release keystore. Use GitHub Secrets.

**Done when:** PC run, phone run and CI APK all work, and you can explain what `project.godot` and a `.tscn` file are.

---

## Milestone 1: Isometric exploration prototype

**What you build:** two connected map screens with placeholder art. Tap to move along a path, pinch zoom, camera follow, tap an object to interact (a sign shows a text popup), walk to an edge exit to change map. All UI strings already go through `tr()`.

**Why it matters:** movement and touch feel are the first thing a player judges. It also sets up the cell grid and map format everything else uses.

**Tools:** Godot TileMapLayer (isometric), AStarGrid2D, Camera2D, a free placeholder isometric tileset (Kenney's isometric packs work).

**What you need to learn:**
- TileSets and TileMapLayers, isometric cell coordinates vs pixel positions.
- Y-sort for depth ordering.
- Input events for touch (tap, drag, pinch).
- Signals.

**How Claude Code helps:** writes the grid utilities (cell to pixel conversion, pathfinding wrapper), the player movement controller, the camera controller and the map transition logic. It writes unit tests for coordinate conversion and pathfinding.

**What you do manually in the editor:** set up the TileSet, paint both maps, place props and the exit zones, tune the camera feel (zoom limits, smoothing) by playing.

**Expected result:** a small character walks smoothly where you tap, goes around obstacles, stands behind trees correctly, and walks off the edge into the next map. It feels responsive: no delay between tap and movement, a visible tap marker.

**How to test:** play on the phone for 10 minutes. Tap fast, tap on obstacles, pinch during movement, rotate the phone, lock and unlock the screen.

**Common mistakes:**
- Mixing pixel positions and cell positions in game logic. Logic uses cells only.
- Letting Claude use `TileMap` (deprecated) instead of `TileMapLayer`, or Godot 3 APIs.
- Spending days on art. Placeholder art only.

**Done when:** movement, zoom, interaction and map change work on the phone with no visible bugs, and you can explain how a tap becomes a path.

---

## Milestone 2: Art style spike

**What you build:** one finished-looking slice of the forest edge near a dungeon, in visual direction A ("dark fairytale", see `ART_PIPELINE.md`): ground tiles, 6-10 props, lighting, one character rendered from 3D with idle, walk, attack and hit in 8 directions, one monster, a mock-up of the combat UI. All shown in the M1 prototype on your phone.

**Plan (updated 2026-10-25):**

| # | Step | Who | Model |
|---|---|---|---|
| 1 | Visual direction chosen (A) | you | done |
| 2 | Tool setup: Blender, check prices and terms of the AI tools, style lab scene in Godot (lighting rig, daylight preview), toon shader and outline, 8-direction render script, cleanup scripts for AI images, time log | Claude | Sonnet |
| 3 | Bake-off: the same character and the same prop made as (A) 3D toon render and (B) AI 2D images; measure time, judge on the phone; pipeline recommendation | you + Claude | Sonnet, recommendation on Opus |
| 4 | Slice production: tiles, props, light, character with 4 animations, monster | you choose and judge, Claude runs scripts | Sonnet |
| 5 | Combat UI mock-up | Claude | Sonnet |
| 6 | Phone test indoors and in daylight, shown to 2 people | you | - |
| 7 | Style guide, measured times, decision D-006, tag m2-done | Claude | Opus |

**Why it matters:** this decides whether the game's look is achievable for you, how long one asset takes, and what it costs. Every later content estimate depends on these numbers.

**Tools:** an AI image tool, an AI image-to-3D tool, an automatic rigging and animation library (your accounts), Blender, Godot. Budget up to about $20 per month, only when needed. No local model training: the PC has no suitable graphics card.

**What you need to learn:** see `ART_PIPELINE.md`. The style rules of direction A, judging an asset against them, writing prompts from the rules, basic Blender navigation to look at a render.

**How Claude Code helps:** Blender render scripts, toon shader and outline, cleanup scripts for AI images (background, grid snap, palette, outline), Godot import, lighting setup, the style lab scene, the combat UI mock-up. It cannot judge your art. You are the art director.

**What you do manually:** generate and choose images and models, create the tool accounts, judge every asset on the phone, approve the palette and the style guide.

**Expected result:** a screenshot you would be happy to show as "this is my game". The character is readable on a phone at default zoom. The darker mood works without hiding gameplay.

**How to test:** phone screenshots indoors and outdoors in daylight. Can you tell walkable ground from obstacles, enemies from scenery, the character's facing? Show it to two people without explaining anything.

**Common mistakes:**
- Generating 200 assets before locking the style. Make 10, judge, adjust.
- Using raw AI output. It drifts in perspective, light direction and line weight.
- Too dark. Phone screens in daylight crush dark palettes. Keep gameplay-critical elements high contrast.

**Done when:** style guide written, pipeline chosen and recorded in `DECISIONS.md`, time per asset type measured (tile, prop, character, monster, animation).

---

## Milestone 3: Tactical combat core

**What you build:** a fight on a map: aggro a monster group, placement phase, initiative order, turns with AP and MP, movement, line of sight, 6 spells for class 1 (damage, area, push, buff, a heal or shield, a mobility spell), 2 monster types with simple AI, win and lose screens, a turn timer. Damage numbers, hit flashes, death animation.

**Why it matters:** combat is the heart of the game. If fights are not fun with two monster types, more content will not fix it.

**Tools:** Godot, gdUnit4, the rules/state architecture from `ARCHITECTURE.md`.

**What you need to learn:** the command/event pattern (read `ARCHITECTURE.md` sections 1, 2 and 5 until you can explain them), how to read a unit test, how to use the debugger and breakpoints.

**How Claude Code helps:** most of the code. Combat state, spell effects, line of sight, AI scoring, turn flow, plus thorough unit tests. A headless balance simulator that runs 1,000 fights.

**What you do manually:** design the 6 spells and 2 monsters (numbers and identity), build the combat UI layout in the editor, tune the feel (animation timing, camera shake, sounds), play many fights.

**Expected result:** a fight takes 2-4 minutes. You make real decisions about positioning and spell order. Monsters threaten you. Every action is readable: you always know what will happen before you confirm it.

**How to test:** unit tests for every rule (AP costs, range, LoS edge cases, death mid-turn, push into walls). Play 20 fights on the phone. Run the simulator and check win rates.

**Common mistakes:**
- Hard-coding "the player" into combat. Fighters with controllers, from day one.
- Writing spells as code. Spells are data made of effects.
- Tuning numbers before the flow is fun. Fix clarity and pacing first.

**Done when:** all rule tests pass, 20 phone fights without bugs, and you prefer playing a fight to watching the timer.

---

## Milestone 3.5: Co-op network spike (throwaway)

**What you build:** two instances of the game (two PC windows first, then two phones) connect over local Wi-Fi. Host-client. Both see the same fight and each controls one fighter. No discovery polish, no save handling.

**Why it matters:** proves the architecture works over the network while changing it is still cheap.

**Tools:** ENetMultiplayerPeer, PacketPeerUDP broadcast, two phones (borrow one if needed).

**What you need to learn:** host vs client, what an RPC is, why the host decides.

**How Claude Code helps:** writes the transport layer that forwards commands to the host and events to the client.

**What you do manually:** test on real Wi-Fi and on a phone hotspot.

**Expected result:** a 2-player fight that works and stays in sync for 10 minutes.

**How to test:** both players act, compare HP and positions on both screens after every turn. Turn Wi-Fi off mid-fight and check nothing crashes.

**Common mistakes:** polishing the spike. It is a test, keep the code in a branch and record what you learned.

**Done when:** sync works and any architecture changes it revealed are recorded in `DECISIONS.md` and applied to the main branch.

---

## Milestone 4: Core loop slice

**What you build:** the village (4-6 maps) and the forest (6-8 maps) in final style. 3 NPCs with dialogue, a merchant, 3 monster types in the forest, XP and levels, loot, inventory, equipment with visible stats, save/load, settings, full English and Polish.

**Why it matters:** the loop "explore, fight, loot, get stronger, go further" has to be satisfying on its own.

**Tools:** Dialogue Manager, gettext `.po` files, Godot Resources for items and monsters.

**What you need to learn:** custom Resources, the `.po` translation workflow, how saves are structured.

**How Claude Code helps:** inventory, equipment, loot tables, XP, save/load with migrations, translation extraction, UI screens. It drafts dialogue and translations for you to edit.

**What you do manually:** build all maps, write and edit dialogue, review every Polish string, design items and the XP curve, place monsters.

**Expected result:** a 45-60 minute session where you reach about level 5, upgrade gear twice and feel stronger.

**How to test:** testing checklist in `TESTING.md`. Save, kill the app, reload. Switch language mid-game.

**Common mistakes:** too many items with tiny differences, text built by string concatenation, maps with nothing to find.

**Done when:** someone else plays 30 minutes without help and wants to continue.

---

## Milestone 5: First Playable

**What you build:** a main quest chain (5-8 steps, one meaningful choice), 2-3 side quests, a short dungeon (4-5 rooms) with a boss with phases, a second class, sound effects and music, a title screen, onboarding for new players, performance pass on the low-end phone.

**Why it matters:** this is your first real game. Everything after this is expanding something that already works.

**Tools:** everything so far, plus Godot's profiler and remote debugging.

**What you need to learn:** quest design, boss design (telegraphed attacks, phases), basic audio mixing, profiling.

**How Claude Code helps:** quest system, boss scripting, audio manager, performance fixes, a test pass over everything.

**What you do manually:** the story, the boss fight design, the second class's spells, all tuning, all playtesting.

**Expected result:** 2-3 hours of content that starts, has a climax and ends, on your phone, in English or Polish.

**How to test:** full checklist in `TESTING.md` on both phones. Two outside testers.

**Common mistakes:** adding features instead of finishing. Use the "Not in First Playable" list in `BACKLOG.md`.

**Done when:** the First Playable checklist in `BACKLOG.md` is complete.

---

## Milestone 6: Professions and economy v1

**What you build:** 2 gathering professions (for example lumberjack and herbalist) and 2 crafting professions (for example smith and alchemist), resource nodes with respawn, recipes that use forest and dungeon resources, item sinks (consumables, repairs or upgrades), merchant prices.

**Why it matters:** this is the sandbox side of the game, and it gives a reason to revisit maps.

**What you do manually:** design recipes so crafted gear competes with dropped gear, place nodes, tune respawn.

**Done when:** a player can choose to gear up mostly through crafting and it feels as good as fighting for drops.

---

## Milestone 7: Co-op v1

**What you build:** host and join from the main menu, discovery with manual IP fallback, both players exploring the host's world, joining each other's fights, per-player loot, character files saved on each device, disconnect handling.

**Done when:** two people complete the First Playable content together without a desync or crash, and solo play is unchanged.

---

## Milestone 8 and beyond: content cycles

Each region is one cycle: style variations (palette, tiles, props, lighting), 8-15 maps, 4-6 monsters, a dungeon and boss, quests, new resources and recipes, a level band. Plus one new class every second region. Use the measured asset times from M2 to plan each cycle.

## Milestone 9: Release preparation

Only when you decide to publish. Play Console account, AAB signing, privacy policy, store listing in both languages, device compatibility testing, crash reporting, closed testing track. Monetization is not discussed before the game is fun for strangers.
