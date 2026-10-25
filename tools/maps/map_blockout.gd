class_name MapBlockout
extends RefCounted
## Draws the blockout picture of a map: the exact canvas of the final backdrop (render scale 2,
## so 10 x 20 cells make 2560 x 1344 px) with every cell as a coloured block raised by its
## level, obstacles as taller blocks and small letters on exits (E), doors (D), stairs (S) and
## ladders (L). It is given to the image AI as the layout to follow and, later, laid under the
## finished picture to check that the two line up.
##
## Colours (also written into prompt.md): light green ground, tan path, blue exit, yellow
## stairs, orange ladder, purple door, grey rock, dark green tree, brown building, dark blue
## water, pink prop.

const SCALE: int = 2
const BACKGROUND: Color = Color(0.13, 0.15, 0.2, 1.0)
const GROUND: Color = Color(0.62, 0.78, 0.5, 1.0)
const GROUND_DECORATED: Color = Color(0.5, 0.68, 0.4, 1.0)
const PATH: Color = Color(0.82, 0.7, 0.5, 1.0)
const EXIT: Color = Color(0.3, 0.55, 0.95, 1.0)
const STAIRS: Color = Color(1.0, 0.9, 0.3, 1.0)
const LADDER: Color = Color(1.0, 0.55, 0.1, 1.0)
const DOOR: Color = Color(0.7, 0.4, 0.9, 1.0)
const ROCK: Color = Color(0.5, 0.5, 0.55, 1.0)
const TREE: Color = Color(0.15, 0.4, 0.2, 1.0)
const BUILDING: Color = Color(0.6, 0.38, 0.25, 1.0)
const WATER: Color = Color(0.15, 0.3, 0.5, 1.0)
const PROP: Color = Color(0.95, 0.4, 0.7, 1.0)
const SPAWN_DOT: Color = Color(1.0, 1.0, 1.0, 1.0)
const LABEL_COLOR: Color = Color(0.05, 0.05, 0.08, 1.0)

## Heights in project pixels (before SCALE) of obstacle blocks standing on a cell.
const OBSTACLE_HEIGHT: Dictionary = {"#": 64, "T": 128, "B": 160}
const PROP_HEIGHT: int = 64

## Layered experiment: the ground picture shows this where obstacles stand.
const FOREST_FLOOR: Color = Color(0.28, 0.4, 0.25, 1.0)
const LABEL_PIXEL: int = 8

## 3 x 5 pixel letters, one string of 15 characters per glyph (row by row, "#" is ink).
const GLYPHS: Dictionary = {
	"E": "###" + "#.." + "##." + "#.." + "###",
	"D": "##." + "#.#" + "#.#" + "#.#" + "##.",
	"S": ".##" + "#.." + ".#." + "..#" + "##.",
	"L": "#.." + "#.." + "#.." + "#.." + "###",
}


## The picture of one map.
static func render(spec: MapSpec) -> Image:
	var image: Image = _canvas(spec, BACKGROUND)
	for entry: Vector3i in _back_to_front(spec):
		_draw_cell(image, spec, entry.x, entry.y)
	return image


## Layered experiment, picture 1: the ground only. Cells where something tall stands (rocks,
## trees, buildings, props) show forest floor, because the objects come as separate pictures.
## Levels still raise their cells.
static func render_ground(spec: MapSpec) -> Image:
	# The edge of the canvas outside the cells is forest floor too, so the picture has no empty corners.
	var image: Image = _canvas(spec, FOREST_FLOOR)
	for entry: Vector3i in _back_to_front(spec):
		var symbol: String = spec.symbol_at(entry.x, entry.y)
		var solid: bool = OBSTACLE_HEIGHT.has(symbol) or _is_prop(spec, symbol)
		var colour: Color = FOREST_FLOOR if solid else _floor_colour(spec, symbol)
		var level: float = spec.height_at(entry.x, entry.y) * GridMath.LEVEL_HEIGHT * SCALE
		_draw_block(image, MapLayout.pixel_center(entry.x, entry.y) * SCALE, level, colour.lightened(0.07 * spec.height_at(entry.x, entry.y)))
	return image


## Layered experiment, picture 2: the objects of one kind in place, on the empty background colour
## (the image AI turns it into transparency).
## `symbols` are the grid symbols to draw, for example "B" for buildings. The picture has the
## same size as the ground picture, so what the image AI paints lines up with the map.
static func render_in_place(spec: MapSpec, symbols: String) -> Image:
	var image: Image = _canvas(spec, BACKGROUND)
	for entry: Vector3i in _back_to_front(spec):
		var symbol: String = spec.symbol_at(entry.x, entry.y)
		if symbols.contains(symbol):
			var level: float = spec.height_at(entry.x, entry.y) * GridMath.LEVEL_HEIGHT * SCALE
			var top: Vector2 = MapLayout.pixel_center(entry.x, entry.y) * SCALE - Vector2(0.0, level)
			_draw_block(image, top, _obstacle_height(spec, symbol) * SCALE, _obstacle_colour(spec, symbol))
	return image


## Layered experiment, picture 3: one object alone on the empty background colour, standing on one cell,
## for a tree or a rock that is placed many times. `height` is in project pixels.
static func render_single(symbol: String, height: int) -> Image:
	var tile_width: int = GridMath.DEFAULT_TILE_WIDTH * SCALE
	var tile_height: int = GridMath.DEFAULT_TILE_HEIGHT * SCALE
	var margin: int = 64
	var image: Image = Image.create(tile_width + 2 * margin, height * SCALE + tile_height + 2 * margin, false, Image.FORMAT_RGBA8)
	image.fill(BACKGROUND)
	var base: Vector2 = Vector2(image.get_width() / 2.0, image.get_height() - margin - tile_height / 2.0)
	var colour: Color = TREE if symbol == "T" else (BUILDING if symbol == "B" else ROCK)
	_draw_block(image, base, height * SCALE, colour)
	return image


static func _canvas(spec: MapSpec, colour: Color) -> Image:
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * SCALE
	var image: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(colour)
	return image


## Every cell as Vector3i(row, column, depth), back to front: the cells lowest on the screen
## are drawn last.
static func _back_to_front(spec: MapSpec) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			var cell: Vector2i = MapLayout.cell_from_row_col(row, col)
			cells.append(Vector3i(row, col, cell.x + cell.y))
	cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.z < b.z or (a.z == b.z and a.y < b.y))
	return cells


static func _draw_cell(image: Image, spec: MapSpec, row: int, col: int) -> void:
	var symbol: String = spec.symbol_at(row, col)
	var centre: Vector2 = MapLayout.pixel_center(row, col) * SCALE
	var level: float = spec.height_at(row, col) * GridMath.LEVEL_HEIGHT * SCALE
	var colour: Color = _floor_colour(spec, symbol).lightened(0.07 * spec.height_at(row, col))
	_draw_block(image, centre, level, colour)
	var top: Vector2 = centre - Vector2(0.0, level)
	var obstacle: float = _obstacle_height(spec, symbol) * SCALE
	if obstacle > 0.0:
		_draw_block(image, top, obstacle, _obstacle_colour(spec, symbol))
		top.y -= obstacle
	var label: String = _label(spec, symbol)
	if not label.is_empty():
		_draw_glyph(image, label, top)
	if symbol == "@":
		_fill_polygon(image, _diamond(top, 40.0, 20.0), SPAWN_DOT)


## A block standing on the ground diamond at `base`: the top face and two side walls up to `height`.
static func _draw_block(image: Image, base: Vector2, height: float, colour: Color) -> void:
	var half_width: float = GridMath.DEFAULT_TILE_WIDTH / 2.0 * SCALE
	var half_height: float = GridMath.DEFAULT_TILE_HEIGHT / 2.0 * SCALE
	if height > 0.0:
		var top: Vector2 = base - Vector2(0.0, height)
		var bottom: Vector2 = base
		_fill_polygon(image, PackedVector2Array([
			top + Vector2(-half_width, 0.0), top + Vector2(0.0, half_height),
			bottom + Vector2(0.0, half_height), bottom + Vector2(-half_width, 0.0),
		]), colour.darkened(0.3))
		_fill_polygon(image, PackedVector2Array([
			top + Vector2(0.0, half_height), top + Vector2(half_width, 0.0),
			bottom + Vector2(half_width, 0.0), bottom + Vector2(0.0, half_height),
		]), colour.darkened(0.15))
		_fill_polygon(image, _diamond(top, half_width, half_height), colour)
	else:
		_fill_polygon(image, _diamond(base, half_width, half_height), colour)


static func _diamond(centre: Vector2, half_width: float, half_height: float) -> PackedVector2Array:
	return PackedVector2Array([
		centre + Vector2(0.0, -half_height), centre + Vector2(half_width, 0.0),
		centre + Vector2(0.0, half_height), centre + Vector2(-half_width, 0.0),
	])


static func _floor_colour(spec: MapSpec, symbol: String) -> Color:
	match symbol:
		",":
			return GROUND_DECORATED
		"=":
			return PATH
		">":
			return EXIT
		"S":
			return STAIRS
		"L":
			return LADDER
		"~":
			return WATER
	if _link_kind(spec, symbol) != "":
		return DOOR
	return GROUND


static func _obstacle_height(spec: MapSpec, symbol: String) -> int:
	if OBSTACLE_HEIGHT.has(symbol):
		return OBSTACLE_HEIGHT[symbol]
	return PROP_HEIGHT if _is_prop(spec, symbol) else 0


static func _obstacle_colour(spec: MapSpec, symbol: String) -> Color:
	match symbol:
		"#":
			return ROCK
		"T":
			return TREE
		"B":
			return BUILDING
	return PROP


static func _is_prop(spec: MapSpec, symbol: String) -> bool:
	for prop: Dictionary in spec.props:
		if prop["marker"] == symbol:
			return true
	return false


## "door", "stairs" or "ladder" for a link marker, "" for anything else.
static func _link_kind(spec: MapSpec, symbol: String) -> String:
	for link: Dictionary in spec.links:
		if link["marker"] == symbol:
			return link["kind"]
	return ""


static func _label(spec: MapSpec, symbol: String) -> String:
	match symbol:
		">":
			return "E"
		"S":
			return "S"
		"L":
			return "L"
	match _link_kind(spec, symbol):
		"door":
			return "D"
		"stairs":
			return "S"
		"ladder":
			return "L"
	return ""


static func _draw_glyph(image: Image, letter: String, centre: Vector2) -> void:
	var glyph: String = GLYPHS[letter]
	var origin: Vector2 = centre - Vector2(1.5 * LABEL_PIXEL, 2.5 * LABEL_PIXEL)
	for index: int in glyph.length():
		if glyph[index] == "#":
			var x: int = index % 3
			("integer_division")
			var y: int = index / 3
			var corner: Vector2 = origin + Vector2(x, y) * LABEL_PIXEL
			_fill_polygon(image, PackedVector2Array([
				corner, corner + Vector2(LABEL_PIXEL, 0.0),
				corner + Vector2(LABEL_PIXEL, LABEL_PIXEL), corner + Vector2(0.0, LABEL_PIXEL),
			]), LABEL_COLOR)


## Fills a convex polygon row by row.
static func _fill_polygon(image: Image, points: PackedVector2Array, colour: Color) -> void:
	var low: float = INF
	var high: float = -INF
	for point: Vector2 in points:
		low = minf(low, point.y)
		high = maxf(high, point.y)
	for y: int in range(maxi(ceili(low), 0), mini(floori(high), image.get_height() - 1) + 1):
		var left: float = INF
		var right: float = -INF
		for index: int in points.size():
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			if (a.y <= y and b.y >= y) or (b.y <= y and a.y >= y):
				var x: float = a.x if is_equal_approx(a.y, b.y) else a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y)
				left = minf(left, x)
				right = maxf(right, x)
				if is_equal_approx(a.y, b.y):
					left = minf(left, minf(a.x, b.x))
					right = maxf(right, maxf(a.x, b.x))
		for x: int in range(maxi(ceili(left), 0), mini(floori(right), image.get_width() - 1) + 1):
			image.set_pixel(x, y, colour)
