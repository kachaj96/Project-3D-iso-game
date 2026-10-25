extends SceneTree
## Alignment check: draws the cell grid of a map over a backdrop picture, so you can see whether
## the picture agrees with the walking rules. Cells are drawn at their level. Green outline:
## walkable, red: blocked, blue: exit, yellow: stairs, orange: ladder, white dot: spawn.
##
##   godot --headless --path . --script res://tools/maps/overlay_check.gd -- <map id> <picture> <output.png>
##
## The picture is scaled to the final backdrop size (render scale 2), so any size with the
## right proportions works.

const OUTLINE_WIDTH: int = 3


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("Usage: -- <map id> <picture> <output.png>")
		quit(1)
		return
	var path: String = "res://content/map_specs/%s.txt" % MapGenerator.relative_path(args[0])
	if not FileAccess.file_exists(path):
		printerr("No map file at " + path)
		quit(1)
		return
	var spec: MapSpec = MapSpec.parse(FileAccess.get_file_as_string(path))
	if not spec.is_valid():
		printerr("The map file has errors: " + str(spec.errors))
		quit(1)
		return
	var picture: Image = Image.load_from_file(args[1])
	if picture == null:
		printerr("Cannot read the picture " + args[1])
		quit(1)
		return
	var size: Vector2 = MapLayout.pixel_size(spec.columns, spec.rows) * MapBlockout.SCALE
	picture.convert(Image.FORMAT_RGBA8)
	picture.resize(int(size.x), int(size.y), Image.INTERPOLATE_LANCZOS)
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			_outline_cell(picture, spec, row, col)
	var error: Error = picture.save_png(args[2])
	print("wrote %s (%s)" % [args[2], error_string(error)])
	quit(0 if error == OK else 1)


func _outline_cell(picture: Image, spec: MapSpec, row: int, col: int) -> void:
	var symbol: String = spec.symbol_at(row, col)
	var lift: float = spec.height_at(row, col) * GridMath.LEVEL_HEIGHT * MapBlockout.SCALE
	var centre: Vector2 = MapLayout.pixel_center(row, col) * MapBlockout.SCALE - Vector2(0.0, lift)
	var half_width: float = GridMath.DEFAULT_TILE_WIDTH / 2.0 * MapBlockout.SCALE
	var half_height: float = GridMath.DEFAULT_TILE_HEIGHT / 2.0 * MapBlockout.SCALE
	var colour: Color = _colour_of(spec, symbol)
	var corners: Array[Vector2] = [
		centre + Vector2(0.0, -half_height), centre + Vector2(half_width, 0.0),
		centre + Vector2(0.0, half_height), centre + Vector2(-half_width, 0.0),
	]
	for index: int in 4:
		_line(picture, corners[index], corners[(index + 1) % 4], colour)
	if symbol == "@":
		for dx: int in range(-8, 9):
			for dy: int in range(-8, 9):
				_dot(picture, centre + Vector2(dx, dy), Color.WHITE)


func _colour_of(spec: MapSpec, symbol: String) -> Color:
	if symbol == ">":
		return Color(0.3, 0.55, 1.0)
	if symbol == "S":
		return Color(1.0, 0.9, 0.2)
	if symbol == "L":
		return Color(1.0, 0.55, 0.1)
	return Color(0.25, 1.0, 0.35) if _walkable(spec, symbol) else Color(1.0, 0.25, 0.25)


func _walkable(spec: MapSpec, symbol: String) -> bool:
	if MapSpec.WALKABLE_SYMBOLS.contains(symbol):
		return true
	for link: Dictionary in spec.links:
		if link["marker"] == symbol:
			return true
	return false


func _line(picture: Image, from: Vector2, to: Vector2, colour: Color) -> void:
	var steps: int = int(maxf(absf(to.x - from.x), absf(to.y - from.y)))
	for step: int in steps + 1:
		var point: Vector2 = from.lerp(to, step / float(maxi(steps, 1)))
		for dx: int in OUTLINE_WIDTH:
			for dy: int in OUTLINE_WIDTH:
				_dot(picture, point + Vector2(dx - 1, dy - 1), colour)


func _dot(picture: Image, point: Vector2, colour: Color) -> void:
	var x: int = roundi(point.x)
	var y: int = roundi(point.y)
	if x >= 0 and y >= 0 and x < picture.get_width() and y < picture.get_height():
		picture.set_pixel(x, y, colour)
