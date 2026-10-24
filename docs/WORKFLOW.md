# Working with Claude Code

Claude Code is a fast, capable coding assistant that is sometimes confidently wrong. Your job is to define what you want, keep each change small, and verify it on the real game. Generated code is not working code until you have seen it work.

## What you must understand vs what you can delegate

**You must understand (explain it back in your own words before moving on):**
- How a tap becomes a command, a rule change and an animation (the architecture loop)
- Where game data lives (Resources in `content/`, state classes in `src/state/`)
- What each scene in `scenes/` is for and how scenes connect
- How to read an error in the Output panel and find the file and line
- How to undo a bad change with Git
- All design numbers: spell costs, damage, XP curve, prices. AI can suggest, you decide

**You can delegate:**
- Writing rule code, UI code, save/load, shaders, CI, tools and tests
- Boilerplate for new Resources and scenes
- Drafting dialogue and Polish translations (you review every line)
- Explaining Godot concepts and error messages

**Do not delegate:** art direction, game feel tuning, and the final call on whether something is fun.

## The task loop

For every task, small enough to finish in one or two sessions:

1. **Write the task** using the template below. Acceptance criteria are things you can see or test.
2. **Branch:** `git switch -c feature/short-name`.
3. **Prompt Claude** with the template. It must inspect the existing project first and propose a plan before writing code.
4. **Read the plan.** If it touches more files than you expected or rewrites existing systems, stop and ask why.
5. **Let it implement**, including tests where rules are involved.
6. **Verify yourself:** tests pass, run on PC, run on phone, walk through `TESTING.md`.
7. **Ask Claude to explain** any part you do not understand. Ask it what could break.
8. **Commit and merge** to `main` only when verified. If it went wrong, throw the branch away: `git switch main && git branch -D feature/short-name`.

## Prompt template

```
Task: <one sentence>

Context: read CLAUDE.md and docs/ARCHITECTURE.md first. Current milestone: M<n>.

Desired behavior:
- <what the player sees or does>

Acceptance criteria:
- <testable statement>
- <testable statement>

Scope: only touch <files/folders or systems>. Do not change <x>.

Process:
1. Inspect the relevant existing files and tell me what you found.
2. Propose a short plan (files to add or change, and why). Wait for my OK.
3. Implement in small steps. Add or update gdUnit4 tests for any rule logic.
4. Run the headless parse check and the tests, and show me the output.
5. Tell me exactly what to do in the editor (if anything) and how to test on PC and on the phone.
6. List anything you are unsure about or could not verify.
```

## When something breaks

- **Script or parse error:** copy the full error from the Output panel (file, line, message) and paste it to Claude with "this appeared after <change>". Ask for the cause before the fix.
- **Broken reference (missing resource, node not found):** usually a moved or renamed file. Ask Claude to search for the old path. In the editor, prefer moving files inside Godot's FileSystem dock, which updates references.
- **It runs but behaves wrong:** describe expected vs actual, with steps to reproduce. Ask Claude to add a test that reproduces it first, then fix.
- **Works on PC, not on the phone:** check the Android logcat through Godot's remote debugger output. Common causes: missing export permission, file paths (`res://` is read-only on Android, save to `user://`), screen size and touch differences.
- **Three failed fix attempts:** stop. Revert the branch, rethink the task, make it smaller.

## Reviewing bigger changes

Before accepting anything that adds a new system or changes `src/core`, `src/state` or the save format, ask Claude:
- "What other systems does this affect?"
- "Does this follow the rules in ARCHITECTURE.md section 2? Which ones are relevant?"
- "What happens to existing save files?"
- "How would this work in co-op?"

Record the answer in `DECISIONS.md` if it is a real decision.

## Git habits

- `main` always runs. Work on branches.
- Commit small. A message says what changed and why.
- Tag every milestone build: `git tag m1-done`.
- Never commit keystores, passwords or API keys.

---

## Your first prompts (Milestone 0)

Do the manual setup steps from `README.md` first. Then, in this repo:

**Prompt 1: project hygiene**
```
Task: prepare the repository for a Godot 4.7 project.

Context: read CLAUDE.md and docs/ARCHITECTURE.md (section 3). Milestone M0. I have just created
project.godot in the repo root from the Godot editor.

Acceptance criteria:
- .gitignore covers Godot 4 (.godot/, export output, *.apk, *.aab, keystores) and keeps project.godot.
- .gitattributes sends art_source/** and large binary source formats (.kra, .psd, .blend) to Git LFS
  and keeps exported PNGs in normal git.
- The folder skeleton from ARCHITECTURE.md section 3 exists (with .gitkeep where empty).
- project.godot uses the Compatibility renderer, landscape orientation, and has static typing warnings
  enabled (untyped declarations as warnings).

Process: inspect first, propose the plan, wait for my OK, then implement. Do not create gameplay code.
```

**Prompt 2: CI**
```
Task: add a GitHub Actions workflow that checks the project and builds a debug APK.

Context: read CLAUDE.md. Milestone M0. My previous project kachaj96/Game has a similar workflow in
.github/workflows/android.yml for reference (Capacitor, not Godot).

Acceptance criteria:
- Runs on push and manual dispatch.
- Downloads Godot 4.7.x headless and matching export templates (pin exact version in one variable).
- Imports the project headless and fails the job on any script error.
- Exports a debug APK using a debug keystore generated in the job (no secrets needed for debug).
- Uploads the APK as an artifact.

Process: inspect first, propose the plan, wait for my OK. Explain each step of the workflow to me
in plain language after implementing.
```

**Prompt 3: test framework**
```
Task: add gdUnit4 and one example test, and run tests in CI.

Acceptance criteria:
- gdUnit4 installed under addons/ (version compatible with Godot 4.7).
- tests/example_test.gd with one passing test of a tiny pure function in src/core/.
- CI runs the tests headless before exporting the APK and fails if a test fails.
- Explain how I run the tests locally, both in the editor and from the command line.
```
