class_name MapPrompt
extends RefCounted
## Writes prompt.md for one map: everything you paste into the image AI together with
## blockout.png. The style rules come from docs/ART_PIPELINE.md (direction A); the layout and
## the neighbours come from the map file. Never put names of existing games or artists here.

const STYLE: Array[String] = [
	"Strict 2:1 isometric projection, like the blockout (a cell is a 2:1 diamond).",
	"Chunky, exaggerated shapes, thick beams, big roofs, gothic details on top of simple forms.",
	"Thin dark outlines tinted with the object's own colour, never pure black.",
	"Cel shading in 2 to 3 tones with soft edges. No noisy fine texture on large surfaces.",
	"Walkable ground is calm, readable and clearly lighter or warmer than its surroundings. Put detail (mushrooms, roots, stones) on edges and obstacles, not in the middle of the walkable area.",
	"Palette: moss green, ochre and earth, cold teal-grey shadows and fog, warm orange for fire and magic light.",
	"Key light from the top left. Mood from light shafts, fog at the map edges and a soft vignette, not from darkening the whole picture.",
]

const LEGEND: Array[String] = [
	"light green: ground you can walk on",
	"tan: a path",
	"blue with an E: exit to the next map. The path must continue off the edge there",
	"purple with a D: a door (to a room on another map)",
	"yellow with an S: stairs, orange with an L: a ladder",
	"grey block: rock or wall, dark green block: tree or tall plant, brown block: building",
	"dark blue flat cell: water or a pit",
	"pink block: an object the player can use (a sign)",
	"white dot: where the hero starts",
	"taller columns: higher ground (32 px per level at 1x). Everything on a higher level must look raised",
]

const EDGES: Array[String] = ["top", "bottom", "left", "right"]


static func build(spec: MapSpec, specs: Dictionary) -> String:
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * MapBlockout.SCALE
	var lines: Array[String] = []
	lines.append("# Backdrop prompt: %s" % spec.id)
	lines.append("")
	lines.append("Attach `blockout.png` and say: *Paint a game backdrop that follows this blockout exactly. Every coloured cell, block and level in it is a place in the final picture.*")
	lines.append("")
	lines.append("- Canvas: %d x %d px (render scale 2, a cell is 256 x 128 px)." % [int(size.x), int(size.y)])
	lines.append("- Map: %s, %d columns x %d rows, region `%s`." % [spec.id, spec.columns, spec.rows, spec.region])
	lines.append("- Do not move, add or remove cells, obstacles or levels. Do not draw the hero, monsters or text.")
	lines.append("")
	lines.append("## Style")
	lines.append("")
	for rule: String in STYLE:
		lines.append("- " + rule)
	lines.append("")
	lines.append("## How to read the blockout")
	lines.append("")
	for entry: String in LEGEND:
		lines.append("- " + entry)
	lines.append("")
	lines.append("## What is on this map")
	lines.append("")
	lines.append_array(_contents(spec))
	lines.append("")
	lines.append("## Edges")
	lines.append("")
	lines.append_array(_edges(spec, specs))
	lines.append("")
	return "\n".join(lines)


static func _contents(spec: MapSpec) -> Array[String]:
	var lines: Array[String] = []
	var counts: Dictionary = {"#": 0, "T": 0, "B": 0, "~": 0}
	var highest: int = 0
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			var symbol: String = spec.symbol_at(row, col)
			if counts.has(symbol):
				counts[symbol] = int(counts[symbol]) + 1
			highest = maxi(highest, spec.height_at(row, col))
	lines.append("- Rocks or walls: %d cells, trees: %d, buildings: %d, water: %d." % [counts["#"], counts["T"], counts["B"], counts["~"]])
	lines.append("- Highest level: %d (%d px at 1x)." % [highest, highest * GridMath.LEVEL_HEIGHT])
	for prop: Dictionary in spec.props:
		var where: Vector2i = spec.find_symbol(prop["marker"] as String)[0]
		lines.append("- A %s at row %d, column %d." % [prop["kind"], where.x, where.y])
	for link: Dictionary in spec.links:
		var where: Vector2i = spec.find_symbol(link["marker"] as String)[0]
		lines.append("- A %s at row %d, column %d leading to another map." % [link["kind"], where.x, where.y])
	return lines


static func _edges(spec: MapSpec, specs: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var exits: Dictionary = {}
	for where: Vector2i in spec.find_symbol(">"):
		var edge: String = MapLayout.edges_of(spec.columns, spec.rows, where.x, where.y)[0]
		if not exits.has(edge):
			exits[edge] = []
		(exits[edge] as Array).append(where)
	for edge: String in EDGES:
		if not exits.has(edge):
			lines.append("- %s edge: no exit. Close it naturally (trees, cliff, water, fog), without a gap." % edge.capitalize())
			continue
		var neighbour: String = MapBuilder.neighbour_id(spec.id, edge)
		var known: String = "" if specs.has(neighbour) else " (not made yet)"
		var places: Array[String] = []
		for where: Vector2i in exits[edge]:
			places.append("%d%%" % roundi(_along(spec, edge, where) * 100.0))
		lines.append("- %s edge: leads to %s%s. A path crosses it at %s of the edge, measured from the %s. Continue the ground and the path off the edge so the two pictures join." % [edge.capitalize(), neighbour, known, ", ".join(places), "left" if edge == "top" or edge == "bottom" else "top"])
	return lines


## How far along its edge an exit lies, 0 to 1.
static func _along(spec: MapSpec, edge: String, where: Vector2i) -> float:
	if edge == "top" or edge == "bottom":
		return where.y / float(maxi(spec.columns - 1, 1))
	return where.x / float(maxi(spec.rows - 1, 1))


## The layered backdrop: instead of one picture with everything painted in, the ground, the
## tall objects and the mist are painted as separate pictures that the game stacks. The look
## comes from the developer's first concept picture (`backdrop_source.png`), which is attached
## to every prompt. The result is a file of ready-to-paste prompts with the exact pictures to
## attach, in order.
static func build_layered(spec: MapSpec) -> String:
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * MapBlockout.SCALE
	var canvas: String = "%d x %d px" % [int(size.x), int(size.y)]
	var crypt: Image = MapBlockout.render_cluster(spec, "B")
	var crypt_size: String = "%d x %d px" % [crypt.get_width(), crypt.get_height()]
	var style: String = "Art style: exactly the look of the attached concept picture (picture A): a hand-painted, semi-realistic fantasy illustration with soft painterly shading, saturated moss greens and warm ochre, cold teal-grey shadows, thin dark outlines in a darker shade of each object's own colour (never pure black). It is NOT pixel art and has no visible tile grid. Strict isometric view like the concept (the camera looks down at about 30 degrees, a ground cell is a 2:1 diamond). Key light from the top left, a low warm golden sun, shadows fall to the bottom right. No text, no characters."
	var transparent: String = "Deliver a PNG with a real transparent background (an alpha channel): every pixel that is not the object must be fully transparent. Do not paint a checkerboard, white or any colour as background, and no ground, grass, mist, light shafts or shadow on the ground."
	var lines: Array[String] = []
	lines.append("# Layered prompts: %s" % spec.id)
	lines.append("")
	lines.append("Eight pictures (five main ones and three small sheets that join objects to the ground), one prompt each. Every prompt says which pictures to attach and in which order. Picture A is always the concept picture `backdrop_source.png`: it carries the look. Use one chat or project for all of them if the tool allows it. Save every version you use together with its prompt. If the tool cannot make exactly the size asked, choose the nearest ratio and tell Claude the real size: pictures are scaled afterwards.")
	lines.append("")
	lines.append("| # | Picture | Attach, in this order | Size |")
	lines.append("|---|---|---|---|")
	lines.append("| 1 | Ground | B `ground_blockout.png` (layout), A `backdrop_source.png` (look) | %s |" % canvas)
	lines.append("| 2 | Crypt | B `objects_B_blockout.png` (where the walls stand), A `backdrop_source.png` (the building's design) | %s |" % crypt_size)
	lines.append("| 3 | Trees (3 in a row) | A `backdrop_source.png` only | about 2048 x 1024 px |")
	lines.append("| 4 | Mist | A `backdrop_source.png` only | %s |" % canvas)
	lines.append("| 5 | Light shafts (optional) | A `backdrop_source.png` only | %s |" % canvas)
	lines.append("")
	lines.append("The mist and the light shafts are separate layers on purpose: the game draws them above the trees and the hero, can move them slowly, and can change them per map. Mist painted into the trees would show as hard patches when the hero walks behind a tree.")
	lines.append("")
	lines.append("## 1. Ground, size %s" % canvas)
	lines.append("")
	lines.append("**Attach, in this order:** B `ground_blockout.png`, then A `backdrop_source.png`.")
	lines.append("")
	lines.append("```")
	lines.append("Paint only the ground of a forest clearing for an isometric game, size %s, filling the whole canvas to every edge." % canvas)
	lines.append("Picture B is the layout. Light green means grass, tan means a dirt path, dark green means forest floor. The colours only show where each ground type goes: do not copy the flat colours, the diamond shapes or the straight zigzag borders. Paint soft, natural, organic transitions, so that nobody can see a grid. The dark green continues to every edge of the canvas: there are no empty corners.")
	lines.append("Ground in the look of the clearing in picture A: short grass with lighter sunlit patches and softer darker patches, a few tiny white flowers, a dirt path with small pebbles along its edges and a worn centre, and toward the dark areas moss, roots, fallen needles and deep teal shadow.")
	lines.append(_path_sentence(spec))
	lines.append("Do not paint trees, rocks, stumps, logs, bushes, mushrooms, buildings or any other object standing on the ground, and no mist or light shafts: they are separate layers.")
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 2. Crypt, size %s" % crypt_size)
	lines.append("")
	lines.append("**Attach, in this order:** B `objects_B_blockout.png`, then A `backdrop_source.png`.")
	lines.append("")
	lines.append("```")
	lines.append("Paint the crypt building from picture A as a separate game object, size %s." % crypt_size)
	lines.append("Keep exactly its design: dark weathered timber-plank walls on a grey stone plinth, a steep terracotta-red tile roof with several gables and dormers, tall carved wooden corner posts with pointed finials, tall pointed-arch windows glowing warm orange, a red banner with a gold fleur-de-lis on the left wall, an open timber-framed arched gate at the front with a hanging lit lantern, and two big mossy grey stone blocks standing in front of the walls on both sides of the gate.")
	lines.append("Picture B shows only where the walls stand on the ground (the brown footprint blocks). The bottom edges of the walls and of the two stone blocks follow the bottom edges of those blocks. The roof, finials and lantern may rise above the blocks. The whole building stays inside the canvas with at least 40 px of margin on every side. The gate faces the viewer.")
	lines.append("In picture B the dark blue-grey is empty space and must become fully transparent. Copy only the building from picture A, not its ground, trees, mist or light shafts.")
	lines.append(transparent)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 3. Trees, three in a row, about 2048 x 1024 px")
	lines.append("")
	lines.append("**Attach:** A `backdrop_source.png` only.")
	lines.append("")
	lines.append("```")
	lines.append("Paint three different tall conifer trees (firs) side by side as separate game objects, in the style of the fir trees in the attached picture A: layered drooping boughs, dark teal-green needles with warm yellow-green sunlit tops on the left side, a visible trunk with roots at the bottom. One tree is tall, one medium, one small and young. Leave at least 100 px of empty space between the trees. All trunk bases stand on the same horizontal line, near the bottom of the picture. Each tree is complete and nothing is cut off at the edges. Size about 2048 x 1024 px.")
	lines.append(transparent)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 4. Mist, size %s" % canvas)
	lines.append("")
	lines.append("**Attach:** A `backdrop_source.png` only.")
	lines.append("")
	lines.append("```")
	lines.append("Paint only a layer of low drifting mist for an isometric forest game, size %s. The look of the mist at the edges of the attached picture A: soft, cool blue-grey with a faint teal tint, thick and bright along the left edge, the right edge and the bottom edge and in all four corners, almost clear in the middle of the picture, with wispy tendrils curling inward." % canvas)
	lines.append("Deliver the mist as WHITE mist on a pure BLACK background (#000000), grayscale only: the brighter the pixel, the thicker the mist. Nothing else in the picture: no ground, no trees, no buildings, no light shafts, no border, no vignette frame.")
	lines.append("```")
	lines.append("")
	lines.append("## 5. Light shafts (optional), size %s" % canvas)
	lines.append("")
	lines.append("**Attach:** A `backdrop_source.png` only.")
	lines.append("")
	lines.append("```")
	lines.append("Paint only soft diagonal shafts of warm sunlight for an isometric forest game, size %s: a few broad golden-white beams that start at the top left corner and fall toward the bottom right, strongest near the top left and fading out before the middle of the picture, like the light shaft in the top left of the attached picture A." % canvas)
	lines.append("Deliver the beams as WARM WHITE on a pure BLACK background (#000000): the brighter the pixel, the stronger the light. Nothing else in the picture: no ground, no trees, no buildings, no mist.")
	lines.append("```")
	lines.append("")
	lines.append("## The joining layer: small nature that ties objects to the ground")
	lines.append("")
	lines.append("In the concept picture the crypt, the stone blocks, the trees and the rocks do not just stand on the ground: small bushes, ferns, grass tufts, mushrooms, flowers, stones and patches of moss and soil sit around their bases and hide the seam. The game scatters these pieces around the foot of every object (the tool places them, you do not). Contact shadows are made by the tool from the objects themselves, so they need no picture. Three sheets, all made in the same chat. For each: attach A `backdrop_source.png` only. Items are separate, complete and well spaced.")
	lines.append("")
	lines.append("### 6. Plants sheet, about 2048 x 1024 px")
	lines.append("")
	lines.append("```")
	lines.append("Paint a sheet of 16 small separate vegetation pieces for an isometric forest game, in a grid of 4 columns and 4 rows with at least 80 px of empty space between the pieces, in the style of the small plants around the crypt, the stones and the trees in the attached picture A. Pieces: 3 small green bushes, 2 larger leafy bushes, 3 ferns, 3 tufts of tall grass (2 of them with tiny white flowers), 2 clusters of mushrooms (red-brown caps), 2 pieces of climbing ivy or moss that can lie against a wall, 1 cluster of small ferns with a few pebbles. Each piece is seen from the same isometric camera as the picture, stands on its own flat base, and is complete: nothing is cut off at its edge. Relative sizes: tufts and mushrooms small, ferns and small bushes medium, large bushes about twice as large as small bushes.")
	lines.append(transparent)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("### 7. Rocks and wood sheet, about 2048 x 1024 px")
	lines.append("")
	lines.append("```")
	lines.append("Paint a sheet of 10 separate rocks and wood pieces for an isometric forest game, in a grid with at least 80 px of empty space between the pieces, in the style of the mossy stones, the tree stump and the fallen log in the attached picture A. Pieces: 2 big mossy boulders, 2 medium grey stones with moss on top, 3 small stones (some with a few blades of grass at their base), 1 old tree stump with moss and roots, 1 fallen log with moss and a few mushrooms, 1 pile of two or three stones. Each piece is seen from the same isometric camera, stands on its own flat base and is complete: nothing is cut off at its edge. Relative sizes: boulders about as wide as one map cell, the log about two cells wide, small stones a quarter of a cell.")
	lines.append(transparent)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("### 8. Ground patches sheet, about 2048 x 1024 px")
	lines.append("")
	lines.append("```")
	lines.append("Paint a sheet of 12 separate flat ground patches for an isometric forest game, seen from the same isometric camera as the attached picture A, lying flat on the ground, in a grid with at least 80 px of empty space between the patches. Each patch has soft, irregular, feathered edges that fade into transparency, so that it blends into any grass. Patches: 4 of dark soil and fallen pine needles with roots, 3 of deep green moss, 2 of dry brown leaf litter, 3 of darker grass with small plants and a few white flowers. They go under the trees and around the crypt walls. Sizes vary from about half a map cell to about two cells wide. No objects standing on them, no shadows from objects.")
	lines.append(transparent)
	lines.append(style)
	lines.append("```")
	lines.append("")
	return "\n".join(lines)


## One sentence that pins the dirt path to the tan cells of the layout: where it starts, where it
## ends (at the gate of a building, if the map has one) and that it must not wander. Empty when the
## map has no path.
static func _path_sentence(spec: MapSpec) -> String:
	var top: Vector2i = Vector2i(-1, -1)
	var bottom: Vector2i = Vector2i(-1, -1)
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			if spec.symbol_at(row, col) == "=":
				if top.x < 0:
					top = Vector2i(row, col)
				bottom = Vector2i(row, col)
	if top.x < 0:
		return "The ground has no dirt path."
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows)
	var top_at: Vector2 = MapLayout.pixel_center(top.x, top.y) / size
	var bottom_at: Vector2 = MapLayout.pixel_center(bottom.x, bottom.y) / size
	return "The dirt path follows the tan cells of picture B exactly: it starts at the bottom of the clearing (about %d%% from the left and %d%% from the top) and runs almost straight up and ends at its top end (about %d%% from the left and %d%% from the top), where it stops at the edge of the dark forest floor. It must end there, because that is where a building with a gate will stand, and it must not bend away to the left or to the right, not turn into a second path and not continue into the dark area. It is about two cells wide. The light green clearing exists only where picture B shows it, around the path in the lower part of the picture. Everything above it, and the whole upper half of the picture, is dark forest floor under dense trees (the trees are added later) with no clearing and no path." % [roundi(bottom_at.x * 100.0), roundi(bottom_at.y * 100.0), roundi(top_at.x * 100.0), roundi(top_at.y * 100.0)]
