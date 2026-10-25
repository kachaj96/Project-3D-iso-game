# Project 3D Iso Game (working title)

An isometric tactical adventure RPG for Android, inspired by the feel of Dofus with a darker atmosphere. 2D illustrated art despite the repo name. Built in Godot 4.7 with Claude Code.

Status: **Milestone 0, setup.** No game code yet.

## Documents

| File | What it is |
|---|---|
| [docs/RESEARCH.md](docs/RESEARCH.md) | Tool research, chosen stack, hardware, sources |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical architecture and the rules that keep co-op cheap later |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Milestones with goals, learning, testing and exit criteria |
| [docs/GDD.md](docs/GDD.md) | Living game design document |
| [docs/ART_PIPELINE.md](docs/ART_PIPELINE.md) | Art pipeline proposal, validated in Milestone 2 |
| [docs/MAP_FORMAT.md](docs/MAP_FORMAT.md) | Map format review and proposal: screen-shaped maps, text map files, generator |
| [docs/BACKLOG.md](docs/BACKLOG.md) | Prioritized backlog and First Playable scope |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Record of technical and design decisions |
| [docs/RISKS.md](docs/RISKS.md) | Risks and known bugs |
| [docs/TESTING.md](docs/TESTING.md) | Repeatable testing checklist |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | How to work with Claude Code, plus the first prompts |
| [CLAUDE.md](CLAUDE.md) | Rules Claude Code follows in this repo |

## First steps (Milestone 0)

1. **Install on your PC:** Git, [Godot 4.7.x standard build](https://godotengine.org/download) (not .NET), Android Studio (used only for the Android SDK), JDK 17, Krita, Claude Code.
2. **Phone:** enable Developer options and USB debugging. Connect it by USB and accept the debugging prompt.
3. **Godot Android setup:** in Godot, Editor > Editor Settings > Export > Android, set the Android SDK path and the Java SDK path. Follow the [Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) page for your exact Godot version.
4. **Create the project:** clone this repo, open Godot, create a new project **in the repo root folder** with the **Compatibility** renderer.
5. **Hello phone:** add a scene with a `ColorRect` and a `Label`, set it as main scene, add an Android export preset (Project > Export), then use the one-click deploy button (Android icon top right) to run it on the phone.
6. **Commit** `project.godot` and the scene.
7. **Run the three prompts** at the end of [docs/WORKFLOW.md](docs/WORKFLOW.md) in Claude Code, one at a time, verifying each.

Milestone 0 is done when the game runs on PC, runs on the phone, and CI produces an installable APK.

## Running checks locally

Set `GODOT_BIN` to the console build, for example `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.

```bash
# Parse-check every GDScript file (fails on any error)
GODOT_BIN="$GODOT_BIN" tools/check_scripts.sh

# Run all gdUnit4 tests headless (exit code 0 = all passed)
"$GODOT_BIN" --headless --path . -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

In the editor: open the gdUnit4 panel (bottom dock), select `tests/`, press the run button.

CI (`.github/workflows/build.yml`) runs the same checks on every push, then exports a debug APK and uploads it as an artifact. The Godot version is pinned in one variable (`GODOT_VERSION`) at the top of that file.
