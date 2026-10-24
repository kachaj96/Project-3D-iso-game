# Risks and known bugs

## Risks

Ranked by impact times likelihood. Review at the end of every milestone.

| # | Risk | Why it is real | Mitigation | Owner milestone |
|---|---|---|---|---|
| R1 | **Art production does not scale** | Illustrated iso art is the most expensive 2D style and needs many assets per map screen | Style spike in M2 with measured time per asset. Cutout rigs reuse animations. Region palettes reuse tiles. Fallback to pre-rendered 3D or simpler style | M2 |
| R2 | **Scope creep** | The vision is Dofus-sized and you love all of it | First Playable definition in `BACKLOG.md`, "not in" list, one milestone at a time | all |
| R3 | **AI-generated code you cannot debug** | Large systems written fast, you read code at 0-1/3 | Small tasks, tests for rules, you explain each system back before moving on (see `WORKFLOW.md`) | all |
| R4 | **Godot 3 vs 4 API confusion in AI output** | Models are trained on lots of Godot 3 code | Pinned version in `CLAUDE.md`, headless parse check in CI | M0 |
| R5 | **Combat not fun on a touchscreen** | Small cells, fat fingers, dark scenes | Preview-then-confirm input, zoom, high contrast overlays, many phone playtests in M3 | M3 |
| R6 | **Dark art hurts readability** | Phone screens in daylight crush dark palettes | Mood through lighting and accents, gameplay elements outlined and high contrast, daylight test in M2 | M2 |
| R7 | **Co-op discovery fails on some networks or hotspots** | Some routers and hotspots block broadcast | Manual IP fallback, early spike on real phones in M3.5 | M3.5 |
| R8 | **Grind creeps back in** | Easiest way to stretch content | Progression rules in `GDD.md`, simulator checks XP per hour | M4+ |
| R9 | **Losing motivation before anything is playable** | Long projects die in the middle | Every milestone ends with a phone build you play | all |
| R10 | **AI art legal and licensing issues at release** | Copyright on pure AI output is weak in the US, tool terms vary | Paint-over on everything, keep sources and prompts, check terms before paid release | M9 |
| R11 | **Save corruption** | Phones kill apps at any moment | Write temp file then rename, versioned saves with migration tests | M4 |
| R12 | **Low-end performance** | Many large painted sprites, lights and particles | Compatibility renderer, texture atlases, CPU particles, test on low-end phone from M5 | M5 |

## Known bugs

Format: `B-001 [open/fixed] short title, steps to reproduce, device, milestone found`.

- **B-001 [open] Godot reports some scripts "still in use at exit".** Found in M1 (2026-10-24) on PC and in CI.
  - Steps: fresh clone, then `godot --headless --path . --import --quit`, or run the game and quit.
  - Engine output: `ERROR: N resources still in use at exit` (N was 4 at first and is 6 after step 8; in the editor also gdUnit4 scripts), always our own command, event and content scripts.
  - What leaks: only GDScript script objects at shutdown. No game object leaks, and tests report 0 orphan nodes. It appeared when `world.gd` started reaching the Authority through `LocalSession`.
  - What was ruled out by bisecting each change: the signal types, the base class, the Crypto id, the pathfinder enum, the event loop, and the session member types. It looks like a GDScript shutdown issue with script dependency order, not a bug in game logic.
  - Impact: none during play, because the system frees the memory when the app closes.
  - CI ignores exactly these two shutdown lines and still fails on any other error.
  - Revisit at the next Godot 4.7.x update, or if the count grows, or if anything leaks while the game runs.
