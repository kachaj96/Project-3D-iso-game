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
## the tall objects are painted as separate pictures. Objects come on a flat magenta background
## that is removed afterwards, so they need no cutting and can be reused on other maps.
## `style_reference` is the name of the picture you attach for the look.
static func build_layered(spec: MapSpec) -> String:
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * MapBlockout.SCALE
	var canvas: String = "%d x %d px" % [int(size.x), int(size.y)]
	var lines: Array[String] = []
	lines.append("# Layered prompts: %s" % spec.id)
	lines.append("")
	lines.append("Four pictures, one prompt each. Attach the blockout named in the heading and also the style reference (the first concept picture, `backdrop_source.png`) so the look stays the same. Paint every picture at the exact size given. Suggested test order: 1, 2 and 4. Picture 3 is the hardest for the image AI (a dense wall of trees); try it last.")
	lines.append("")
	lines.append("Rules for all four: strict 2:1 isometric projection exactly like the blockout (a cell is a 2:1 diamond, 256 x 128 px), key light from the top left, thin dark outlines tinted with the object's colour, cel shading in 2 to 3 tones, no text, no hero, no monsters.")
	lines.append("")
	lines.append("## 1. Ground (`ground_blockout.png`, %s)" % canvas)
	lines.append("")
	lines.append("*Paint only the ground of this map, filling the whole canvas, following the blockout. Light green cells are grass you walk on, tan cells are the path, the dark green cells are forest floor (moss, roots, fallen needles, shadow). No trees, rocks, buildings, signs or any object standing on the ground: those are painted separately. Calm, readable walkable ground. Raised cells (if any) must look raised.*")
	lines.append("")
	lines.append("## 2. Buildings in place (`objects_B_blockout.png`, %s)" % canvas)
	lines.append("")
	lines.append("*Paint the building shown by the brown blocks, exactly where and as large as the blocks are, on a flat pure magenta background (#FF00FF) that fills everything else. The building stands on the ground, so the bottom edge must follow the base of the blocks. Do not paint ground, grass, shadows on the ground or anything outside the building.*")
	lines.append("")
	lines.append("## 3. Trees in place (`objects_T_blockout.png`, %s)" % canvas)
	lines.append("")
	lines.append("*Paint conifer trees, one tree on each dark green block, exactly where the blocks are, on a flat pure magenta background (#FF00FF). Trees overlap like a dense forest edge but each trunk stands on its block's base. Vary the trees. No ground, no grass, no ground shadows.*")
	lines.append("")
	lines.append("## 4. One tree to reuse (`single_T_blockout.png`, %d x %d px)" % [MapBlockout.render_single("T", MapBlockout.OBSTACLE_HEIGHT["T"]).get_width(), MapBlockout.render_single("T", MapBlockout.OBSTACLE_HEIGHT["T"]).get_height()])
	lines.append("")
	lines.append("*Paint one conifer tree standing on the diamond at the bottom of the blockout, its trunk base at the centre of the diamond, on a flat pure magenta background (#FF00FF). No ground, no shadow on the ground.*")
	lines.append("")
	return "\n".join(lines)
