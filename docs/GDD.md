# Game design document (living)

Working title: **TBD** (see open questions). Update this file whenever a design decision changes. Mark anything untested as *(draft)*.

## 1. One-line pitch

A tactical isometric adventure RPG for Android: explore a hand-crafted world of connected map screens, fight Dofus-style turn-based battles, build your class, craft your gear, and uncover a darker world that still has room for charm and humor. Later, play it with a friend over local Wi-Fi.

## 2. Design pillars

Every feature must support at least one pillar. If it supports none, cut it.

1. **Tactical fights worth thinking about.** Positioning, line of sight and spell order decide fights. Short, readable, decisive.
2. **A world worth exploring.** Every map has something: a secret, a story detail, a resource, a shortcut, a view.
3. **Builds that feel like yours.** Class, spells, stats and gear combine into a personal playstyle.
4. **Progress without grind.** Challenge is welcome. Repetition for its own sake is not.
5. **Dark, but not grim.** Danger and mystery, with warmth and humor in the people you meet.

## 3. Target experience

- Sessions of 10-30 minutes on a phone, landscape. A fight fits in a bus ride.
- Long-term: months of play across releases, like Dofus regions arriving over time.

## 4. Tone and art direction (summary)

Dofus readability and charm, with Dark Souls / Bloodborne / Diablo mood: dramatic lighting, gothic and unsettling details, stronger sense of danger. Regions contrast strongly: a dangerous gothic city, a peaceful sunlit coast, a strange whimsical fungal forest. Full rules in `ART_PIPELINE.md` and the style guide produced in Milestone 2.

## 5. Core loops

- **Moment to moment (seconds):** tap to move, tap to interact, plan and execute a turn in combat.
- **Session (minutes):** pick a goal (quest step, resource, dungeon), travel, fight, loot, return to town to craft or sell.
- **Long term (weeks):** reach new regions, unlock spells, complete gear sets, master professions, beat bosses, fill collections.

## 6. Combat *(draft)*

- Turn-based on the isometric cell grid of the current map. Placement phase with team-colored start cells.
- **AP** (action points) for spells, **MP** (movement points) for moving. Base 6 AP / 3 MP, raised by gear and levels.
- Line of sight, range min/max, area shapes (cross, line, circle, cone), push/pull, collisions that deal damage.
- Elements (for example earth, fire, water, air, plus a "void" element tied to the darker lore) for damage and resistances.
- Status effects: poison, burn, root, weaken, shield, haste, invisibility, marks.
- Turn timer, generous by default, adjustable in settings for solo play.
- Monster groups visible on the map. Tapping one starts the fight. No random encounters.
- Defeat: return to the last save point with no item loss. Harsh penalties do not fit a phone game.

## 7. Classes *(draft, all names are placeholders)*

Each class needs one sentence that explains its tactical identity. If the sentence is fuzzy, the class is not ready.

| Class | Tactical identity |
|---|---|
| Lanternbearer | Controls the battlefield with light: reveals, blinds and creates zones that hurt enemies standing in darkness. |
| Gravewarden | Tank who turns damage taken into power. Pulls enemies in and locks them down. |
| Hexweaver | Places marks on cells and enemies, then detonates them. Rewards planning two turns ahead. |
| Thornshot | Long-range archer. Strong at distance and with line of sight, weak when cornered. Uses pushback to keep range. |
| Bloodbinder | Risky melee. Spends own HP to cast, heals by dealing damage. |
| Tinker | Summons constructs that block cells and line of sight. A positional puzzle class. |

First Playable: one class finished (6 spells), a second class with 6 spells to prove the system. More classes arrive with later regions.

## 8. Progression without grind *(draft rules)*

- Every region has a level band. The main quest plus normal side content takes a player through it without farming.
- XP from monsters far below your level drops to zero. You cannot level by stomping weak monsters, and you do not have to.
- Spell unlocks and gear set bonuses are the main power steps, not tiny stat increments.
- No level where XP requirements jump to absurd values. The curve stays smooth, and the cap rises with content.
- Endgame is optional challenge: harder dungeon modes (like the Echo mode from Natalis), boss variants, collections, rare crafts. Not 200 hours of the same fight.
- Cheap respec so build experiments are encouraged.

## 9. Equipment and loot *(draft)*

- Slots: weapon, hat, cloak, amulet, ring x2, belt, boots, plus a pet or companion slot later.
- Gear sets with bonuses at 2/3/4 pieces, tied to regions and dungeons.
- Visible gear: hat, cloak and weapon change the character's look (cutout rig makes this cheap).
- Crafted and dropped gear both matter. Crafted gear is reliable, drops can roll higher.
- Per-player loot rolls in co-op. A luck-style stat raises your own drop chances only.

## 10. Professions *(draft, Milestone 6)*

- Gathering: lumberjack, herbalist, miner, fisher.
- Crafting: smith (weapons), tailor (hats, cloaks), jeweler (rings, amulets), alchemist (potions, consumables), cook.
- Recipes mix resources from different regions and dungeon drops, so exploring and fighting feed crafting.
- Professions have their own levels with unlocks. No profession requires grinding thousands of identical crafts.

## 11. Quests and story *(draft)*

- Main quest per region, with one meaningful choice per region whose consequence shows up later.
- Side quests built around characters, not "bring 10 pelts". Natalis already had this rule: avoid fetch-quantity quests.
- Environmental storytelling: ruins, notes, statues, changed maps after story events.
- A codex or bestiary that fills in as you discover things (another proven idea from Natalis).

## 12. World *(draft)*

- Connected map screens, grouped into regions. Fast travel unlocks between towns after visiting.
- First region (First Playable): a village and a forest, plus a short dungeon. The village should feel safe and warm. The forest should feel beautiful by day and threatening near the dungeon.
- Later regions are designed one at a time, each with its own palette, architecture, music, monsters and lighting.

## 13. Co-op *(design intent, Milestone 7)*

- Two players, each with their own character, progression and inventory, on two Android devices on the same local network or phone hotspot.
- Both explore the host's world, fight in the same battles and control their own fighter.
- Quest progress per character. Kills and objectives credit both players if both took part.
- Solo play is always complete. No content requires two players.

## 14. Localization

English and Polish from the first string. All text through translation keys. Polish plural forms handled with `tr_n`.

## 15. Open questions

1. **Is this "Natalis 2"?** Your previous game's `CLAUDE.md` planned isometry as a separate project called Natalis 2, and Natalis already has a 7-continent world and lore. Reusing it saves world-building time. A fresh IP gives more freedom and avoids personal elements (the dedication, Natalia as heroine) if you publish. Decide before writing the main quest (Milestone 5). It does not block Milestones 0-3.
2. Title of the game.
3. Final proportions of story vs exploration vs sandbox. Revisit after the First Playable based on what testers enjoy most.
4. Final class list and which class comes first. Recommended first class: one with a simple, strong identity, such as Thornshot or Gravewarden.
5. Death penalty in later, harder content.
