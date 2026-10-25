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

## The layered experiment: instead of one backdrop with everything painted in, the ground and
## the tall objects are painted as separate pictures. Objects come as PNGs with a real alpha
## channel (the image AI of the developer can do that), so they need no cutting and can be
## reused on other maps. In the object layouts the dark blue-grey is empty space.
## The result is a file of ready-to-paste prompts, each with the exact pictures to attach.
static func build_layered(spec: MapSpec) -> String:
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * MapBlockout.SCALE
	var canvas: String = "%d x %d px" % [int(size.x), int(size.y)]
	var tree: Image = MapBlockout.render_single("T", MapBlockout.OBSTACLE_HEIGHT["T"])
	var tree_size: String = "%d x %d px" % [tree.get_width(), tree.get_height()]
	var style: String = "Style: dark fairytale, strict 2:1 isometric projection exactly like the layout picture (a map cell is a 2:1 diamond, 256 x 128 px), key light from the top left, thin dark outlines tinted with each object's own colour (never pure black), cel shading in 2 to 3 tones with soft edges, chunky exaggerated shapes. No text, no characters."
	var only_use: String = "In the first attached picture the dark blue-grey is empty space: it must become fully transparent. Use the first attached picture only for exact position and size. Use the second attached picture only for style, colours and light. Do not paint any ground and do not copy the ground from the second picture."
	var lines: Array[String] = []
	lines.append("# Layered prompts: %s" % spec.id)
	lines.append("")
	lines.append("Four pictures, in this order: 1, 2, 4, then 3 (the hardest). For each one: attach the pictures named under **Attach**, in that order, then paste the text in the box. Keep the same chat or project for all of them if the tool allows it. When picture 1 is good, keep it: it is the **style picture** for the rest. Save every version you use together with its prompt.")
	lines.append("")
	lines.append("If the tool cannot make exactly the size asked, choose the nearest ratio and tell Claude the real size: pictures are scaled afterwards.")
	lines.append("")
	lines.append("## 1. Ground, size %s" % canvas)
	lines.append("")
	lines.append("**Attach (in this order):** 1. `ground_blockout.png` (layout)  2. `backdrop_source.png` (style, the first concept picture)")
	lines.append("")
	lines.append("```")
	lines.append("Paint only the ground of a forest clearing for an isometric game, size %s, filling the whole canvas to every edge." % canvas)
	lines.append("The first attached picture is the exact layout (the dark blue-grey around it is only the empty edge of the layout: fill the whole canvas anyway): light green cells are grass you walk on, tan cells are a dirt path, dark green cells are forest floor (moss, roots, fallen needles, deep shadow). Keep the shapes and positions of the cells.")
	lines.append("The second attached picture is only a style reference: use its colours, light and painting style.")
	lines.append("Do not paint trees, rocks, buildings, signs or any other object standing on the ground: they are painted separately. Calm, readable walkable ground, with more detail only at the edges.")
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 2. Crypt (buildings in place), size %s" % canvas)
	lines.append("")
	lines.append("**Attach (in this order):** 1. `objects_B_blockout.png` (layout)  2. the picture 1 you chose (style)")
	lines.append("")
	lines.append("```")
	lines.append("Paint the old stone and timber crypt building shown by the brown blocks in the first attached picture, exactly where and as large as the blocks are, size %s." % canvas)
	lines.append("Deliver a PNG with a real transparent background (an alpha channel): every pixel that is not the building must be fully transparent. Do not paint a checkerboard, white or any colour as background, and no ground, grass or shadow on the ground. The bottom edge of the building follows the bottom edges of the blocks. The whole building, including the roof and every spire, must fit inside the canvas with a margin of at least 40 px at the top. A gate opening in the front wall faces the viewer.")
	lines.append(only_use)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 4. One tree to reuse, size %s" % tree_size)
	lines.append("")
	lines.append("**Attach (in this order):** 1. `single_T_blockout.png` (layout)  2. the picture 1 you chose (style)")
	lines.append("")
	lines.append("```")
	lines.append("Paint one tall conifer tree standing on the diamond at the bottom of the first attached picture, its trunk base at the centre of the diamond, size %s." % tree_size)
	lines.append("Deliver a PNG with a real transparent background (an alpha channel): every pixel that is not the tree must be fully transparent. Do not paint a checkerboard, white or any colour as background, and no ground, grass or shadow on the ground. The whole tree must fit inside the canvas.")
	lines.append(only_use)
	lines.append(style)
	lines.append("```")
	lines.append("")
	lines.append("## 3. Forest edge (trees in place), size %s - try last" % canvas)
	lines.append("")
	lines.append("**Attach (in this order):** 1. `objects_T_blockout.png` (layout)  2. the picture 1 you chose (style)")
	lines.append("")
	lines.append("```")
	lines.append("Paint conifer trees, one tree standing on each dark green block of the first attached picture, exactly where the blocks are, size %s. Trees overlap like a dense forest edge, but each trunk stands on its own block's base. Vary the trees." % canvas)
	lines.append("Deliver a PNG with a real transparent background (an alpha channel): every pixel that is not a tree must be fully transparent. Do not paint a checkerboard, white or any colour as background, and no ground, grass or shadow on the ground.")
	lines.append(only_use)
	lines.append(style)
	lines.append("```")
	lines.append("")
	return "\n".join(lines)
