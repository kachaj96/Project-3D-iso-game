# Art pipeline

Status: **visual direction chosen (A, "dark fairytale"), production pipeline to be chosen in the Milestone 2 bake-off.** Update this document with measured results at the end of M2.

## Why art is the main risk

An illustrated isometric game needs a lot of art per map screen. You do not paint, so every asset comes from AI tools and scripts, and your work is choosing, composing, lighting and judging. The plan is to make that repeatable before making lots of it.

## Visual direction A: dark fairytale (chosen 2026-10-25)

Dofus shapes, proportions and readability, with a gothic, threatening mood carried mainly by light and palette. References stay on your disk (`Iso game inspirations`), never in the repo.

**Style rules** (every prompt and every review checks these):

1. **Shapes:** chunky and exaggerated, like Dofus: thick beams, big roofs, buildings 2-4 cells tall. Gothic details (pointed arches, iron fences, spires) on top of those shapes, not realistic gothic proportions.
2. **Outline:** thin and dark, tinted with the object's own color, never pure black. Characters, monsters and interactable objects get a slightly stronger outline than scenery.
3. **Shading:** cel shading in 2-3 tones with soft edges. No fine noisy texture on large surfaces.
4. **Ground:** calm and readable. Walkable cells are clearly lighter or warmer than their surroundings. Detail (mushrooms, roots, stones) belongs on edges and obstacles, not in the middle of fighting space.
5. **Palette:** moss green, ochre and earth for the world, cold teal-grey for shadows and fog, warm orange for fire and magic light. Each region gets its own 8-12 color swatch, written into this file.
6. **Light:** key light from the top-left. Mood comes from light shafts, fog at the map edges, torch pools and vignette, never from making the whole screen dark.
7. **Characters:** big head, readable silhouette, 2-3 main colors. The player must find their character instantly on a phone in daylight; the M2 phone test checks this. If it fails, the first fix is one saturated accent (cloak, scarf, hat) that contrasts with the region palette.
8. **Projection:** strict 2:1 isometric for every asset that sits on the grid (128 x 64 cell). A full scene image from an AI tool is a mood target only, never a game asset.

Lessons from the first sample of direction A: the scene was not strict isometric, ground detail was busier than Dofus, and outlines were close to black. Rules 2, 4 and 8 exist because of that. You judged the character readable in that sample; the phone test in daylight confirms it.

## Technical constants (decide once, never change)

| Item | Value | Why |
|---|---|---|
| Projection | 2:1 isometric (dimetric) | Tiles line up cleanly. Already used by the code (`GridMath`) |
| Base cell | 128 x 64 px ground diamond | Already used by the code and the TileSet |
| Character height | about 1.6-2 cells (110-130 px at zoom 1) | Readable on a phone |
| Directions | **8** (the character walks in 8 directions since M1) | Characters are rendered from 3D, so extra directions cost render time, not drawing |
| Light direction | Top-left in all art | Consistency between assets |
| Texture filtering | Linear, with mipmaps for zoomed-out views | Illustrated art, not pixel art |
| Outline | Dark, tinted, never pure black | Rule 2 |

## Proposed pipeline (to be confirmed by the M2 bake-off)

**Characters and monsters: 3D rendered to 2D ("toon" render).**
1. Concept image from an AI image tool, following the style rules, front view and side view.
2. Turn the concept into a 3D model with an AI image-to-3D tool.
3. Rig and animate humanoids with an automatic rigging and animation library (idle, walk, attack, hit, death). Your account, your login.
4. In Blender: toon shader (2-3 tone cel shading), tinted outline, fixed isometric camera, top-left key light.
5. A script renders every animation in 8 directions into sprite sheets.
6. Godot plays the sprite sheets. Equipment swaps are separate meshes rendered the same way.

**Ground tiles and props: AI images, cleaned by scripts.**
1. Generate single assets (one tile, one prop), never full scenes, against a fixed style reference sheet.
2. Scripts remove the background, snap the asset to the 128 x 64 grid, map colors to the region palette and normalize the outline.
3. Tall props are split where the character must walk behind them.

**Effects and lighting:** Godot particles and shaders (CPU particles for low-end phones), `CanvasModulate` per region, `PointLight2D` for torches and spells.

**UI:** one coherent kit (frames, buttons, icons). Icons are a good fit for AI generation.

**Alternative in the bake-off:** characters as AI-generated 2D images per direction. Expected to drift between directions and frames, which is why 3D is the favourite.

## Rules for AI-generated art

1. Never ship a raw full-scene AI image. Every game asset is a single asset that passed the style rules and the cleanup scripts.
2. Keep the source of every shipped asset in `art_source/` (Git LFS): the prompt, the tool and its settings, the AI output, the 3D file and the cleaned result. This is your record of authorship: selection, composition, lighting, palette.
3. Do not put the names of existing games or artists into prompts for final assets. Use your own style rules and reference sheet.
4. Generate in small batches, judge, adjust. Never a whole region in one go.
5. Before paying for any tool, check its price and its terms for commercial use. Budget during M2: up to about $20 per month, only when needed.

## Tracking asset cost

Record actual time per asset in Milestone 2:

| Asset type | Target time | Measured |
|---|---|---|
| Ground tile set for a region | 3-5 h | - |
| Prop | 20-40 min | - |
| Character (model, rig, renders) | 4-8 h | - |
| Animation set, 8 directions | 2-4 h | - |
| Monster | 3-6 h | - |
| Icon | 5-15 min | - |

## Tools and their terms (checked 2026-10-25)

Prices and terms change. Re-check on the vendor's own page before paying. Nothing is bought yet.

| Tool | What for | Price seen on its own page | Commercial use |
|---|---|---|---|
| **Tripo** (tripo3d.ai) | Image to 3D, texture, auto rig, also image generation inside the plan | Free: 200 credits a month. **Pro: $20 a month**, 3000 credits (about 200 models) | Free: models are public and non-commercial, and Tripo keeps the rights. Paid: terms say paid users have all rights to their inputs and outputs, and Tripo does not train on them. Outputs are not exclusive: other users can receive similar ones |
| **Meshy** (meshy.ai) | Same, as an alternative | Free 100 credits; Starter about zł 36, **Pro about zł 73 (roughly $20)** a month | Free: CC BY 4.0, commercial use with credit to Meshy. Paid: assets are "private and customer owned" |
| **Mixamo** (Adobe) | Free auto rig and animation library for humanoids | Free with an Adobe account | An Adobe employee states on the official forum that characters and animations are royalty-free for commercial games, but the raw files may not be redistributed. The official FAQ page did not load for me, so read Adobe's current terms before release |
| **Blender** | Rendering the 8 directions | Free (installed: 4.5.10 LTS) | Free software, output is yours |

Notes:
- Third-party image generators used inside a plan (for example the ones listed in Tripo's image generation) are governed by their own terms, according to Tripo's terms. Check them before shipping any asset made that way.
- For the bake-off the free plans are enough to judge quality. Do not put free-plan output into the shipped game: it is public and the vendor keeps the rights.
- Budget: one paid plan at a time, about $20 a month, only after the bake-off shows the tool is worth it.

## Developer tools in the repo

| Tool | What it does |
|---|---|
| `tools/blender/render_sprites.py` | Renders a 3D model into isometric sprite frames: orthographic camera at 30 degrees, light fixed top-left, 3-tone cel shading, outline, 4 or 8 facings, optional animation frames. Run with Blender in background mode. Tested on a built-in demo figure |
| `tools/art/make_contact_sheet.gd` | Puts all frames of a folder on one sheet with a 128 x 64 diamond under each anchor point |
| `tools/art/cleanup_image.gd` | Removes the plain background of an AI image, trims, scales to a target width. Tested |
| `scenes/lab/style_lab.tscn` | Map and character with a "Daylight" switch that imitates a phone screen in sunlight |

## Bake-off log: character from an AI image to 8 render directions (2026-10-25)

Same concept (hooded ranger, A-pose) tried in two tools on free plans. Measured by you and by Claude.

| Step | Meshy (free) | Tripo (free) |
|---|---|---|
| Concept image, 4 variants | 36 credits, fast | 40 credits |
| 3D model from the chosen image | 15 credits | 25 credits with texture, about 60 s (20k triangles, 2K texture, no PBR, lighting removed) |
| Texture | 10 credits, about 60 s | included above |
| Mesh reduction | only to 10k, free | set before generating |
| Export | **blocked on the free plan** | blocked for the first model; **worked after regenerating on engine version H2.5** |
| Look | chunky, toy-like, bigger gloves and boots | slimmer, flatter colors, closer to an illustration |
| Rig and animation | not tried (needs a paid plan to download) | Auto Rig, humanoid, Mixamo bone names: 20 credits, about 180 s. **The exported GLB has a damaged skeleton**: bones sit on one spot and the mesh blows up when the skeleton is applied, in Blender with either import setting. Animations exist in the tool, their cost was not visible |

Render step (Blender, this PC): 8 directions of a 20k triangle model in about 12 seconds including startup, no cost.

Findings:
- Free plans can be used to judge quality but not to get usable files without tricks. For production a paid plan is needed.
- Tripo's texture has projection flaws: the face is painted a little onto the hood sides and the edges of gloves and boots show light speckles. At sprite size they are barely visible; check on the phone.
- At a 120 px sprite height the face is about 10 px wide, so eyes are lost. If faces should read, the model needs bigger eyes than this concept has.
- The model has no skeleton yet. A rig is the next step.

Rig results (2026-10-25):
- Tripo's auto-rigged GLB (free plan, H2.5 export) cannot be used: every bone has the same position, so skinning explodes the mesh. `render_sprites.py` now detects this and stops with a clear message instead of rendering empty frames.
- Possible fixes, cheapest first: export the same rig as FBX from Tripo (one more of the 15 free exports); rig the static model in Mixamo (free, Adobe account); a paid plan only if neither works.
- `tools/blender/export_static_fbx.py` turns the static GLB into an FBX for Mixamo: scaled to 1.8 m, feet on the ground, texture embedded.
- `render_sprites.py --procedural walk|idle` plays a simple test animation on any skeleton with Mixamo bone names, to check how the mesh bends before real animations are used.

Tripo FBX exports (2026-10-25): both the "Blender" and the "Mixamo" export modes (zip with FBX and texture) contain only the mesh: no skeleton, no skin weights, no animation (checked in Blender and by searching the raw FBX for skeleton data). The Mixamo mode file is the model in centimetres, Y up, with a PNG texture, meant for uploading to Mixamo. So on the free plan Tripo's rig could only be exported as the damaged GLB. Rigging goes through Mixamo instead.
