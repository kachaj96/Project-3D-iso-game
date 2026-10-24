# Art pipeline

Status: **proposal, to be validated in Milestone 2.** Replace this document with the real pipeline once the style spike is done.

## Why art is the main risk

An illustrated isometric game needs a lot of art per map screen, and a solo developer is the only artist. The plan is to make art production repeatable before making lots of it.

## Technical constants (decide once, never change)

| Item | Proposal | Why |
|---|---|---|
| Projection | 2:1 isometric (dimetric), like Dofus | Standard, tiles line up cleanly |
| Base cell | 128 x 64 px ground diamond | Readable at phone zoom, scales down well |
| Character height | about 1.6-2 cells (roughly 110-130 px tall at 1x) | Big enough to read gear and expression on a phone |
| Directions | 4 diagonals, 2 drawn (front-3/4 and back-3/4) and mirrored | Halves character work. Dofus-style games mostly move diagonally anyway |
| Light direction | Top-left in all art | Consistency between assets |
| Texture filtering | Linear, with mipmaps for zoomed-out views | Painted art, not pixel art |
| Outline | Dark colored outline (not pure black) on characters and interactables | Separates gameplay objects from scenery in dark scenes |

## Asset types and proposed method

**Ground tiles and terrain.** AI-generated textures in the region's style, cut and corrected into tiles in Krita, plus hand-painted transition tiles. Use Godot's terrain autotiling for transitions.

**Props (trees, houses, rocks, ruins).** Generate several variations with your custom style model, pick one, paint over in Krita to fix perspective, light direction and outline, then split tall props where the player must walk behind them.

**Characters and monsters.** Cutout rigs:
1. Concept: AI-assisted sketches, front-3/4 and back-3/4, consistent proportions.
2. Paint the final character in Krita on separate layers: head, torso, upper and lower arms, hands, legs, feet, plus accessory layers (hat, cloak, weapon).
3. Export parts as PNGs. Assemble in Godot with Skeleton2D and Bone2D, or simple parented Sprite2Ds.
4. Animate idle, walk, cast, attack, hit, death with AnimationPlayer. Reuse animations across characters with the same skeleton.
5. Equipment swaps replace part textures.
If this feels too stiff after the spike, compare with the Blender pre-render path (3D model, toon shader, orthographic iso camera, render sprite sheets).

**Effects (spells, hits, ambient).** Godot GPUParticles2D/CPUParticles2D and shaders, with a small library of hand-painted or generated effect textures. CPU particles are safer on low-end phones.

**UI.** One coherent UI kit: frames, buttons, icons. Icons are a good fit for AI generation with paint-over, since they are small and numerous.

**Lighting and mood.** CanvasModulate for region ambience, PointLight2D for torches and spells, optional normal maps for key props later. Mood comes from lighting and palette, so base art can stay readable.

## Style guide (fill in during Milestone 2)

- Region palette swatches (8-12 colors each)
- Line weight and outline color rules
- Proportions sheet for humanoids
- Do and don't examples with screenshots
- The prompt template and model or LoRA used per asset type

## Rules for AI-generated art

1. Never ship raw AI output. Always correct perspective, light, outline and palette.
2. Keep the source file (`.kra`) for every shipped asset in `art_source/` (Git LFS). It is your proof of human authorship and makes later changes possible.
3. Save the prompt and settings next to the source file.
4. Do not prompt with the names of existing games or artists for final assets. Use your own reference sheets.
5. Generate in small batches against a reference sheet, judge, adjust. Never generate a whole region in one go.

## Tracking asset cost

Record actual time per asset in Milestone 2 and keep updating it:

| Asset type | Target time | Measured |
|---|---|---|
| Ground tile set for a region | 4-6 h | - |
| Prop | 30-60 min | - |
| Character (painted parts + rig) | 6-10 h | - |
| Animation set per skeleton | 4-8 h | - |
| Monster | 4-8 h | - |
| Icon | 10-20 min | - |
