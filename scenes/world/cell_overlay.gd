class_name CellOverlay
extends Node2D
## Development aid: draws every cell of a map over the picture, to check that the picture and
## the walking rules agree. Green walkable, red blocked, blue exits, yellow stairs, orange
## ladders; the number is the level. Hidden by default; switch `visible` on in the editor or
## from code. Used by the scene stubs of the map generator.

const WALKABLE: Color = Color(0.2, 0.9, 0.3, 0.22)
const BLOCKED: Color = Color(0.95, 0.2, 0.2, 0.35)
const EXIT: Color = Color(0.2, 0.5, 1.0, 0.4)
const STAIRS: Color = Color(1.0, 0.9, 0.2, 0.4)
const LADDER: Color = Color(1.0, 0.55, 0.1, 0.45)

@export_file("*.tres") var map_path: String = ""

var _map: MapDef


func _ready() -> void:
	if not map_path.is_empty():
		_map = load(map_path)
	queue_redraw()


func show_map(map: MapDef) -> void:
	_map = map
	queue_redraw()


func _draw() -> void:
	if _map == null:
		return
	var grid: GridMath = GridMath.new()
	var half_width: float = grid.tile_width / 2.0
	var half_height: float = grid.tile_height / 2.0
	for cell: Vector2i in _map.all_cells():
		var level: int = _map.height_at(cell)
		var centre: Vector2 = grid.cell_to_pixel(cell) - Vector2(0.0, grid.level_lift(level))
		var corners: PackedVector2Array = PackedVector2Array([
			centre + Vector2(0.0, -half_height), centre + Vector2(half_width, 0.0),
			centre + Vector2(0.0, half_height), centre + Vector2(-half_width, 0.0),
		])
		draw_colored_polygon(corners, _color_of(cell))
		draw_polyline(corners + PackedVector2Array([corners[0]]), Color(0, 0, 0, 0.5), 1.0)
		if level > 0:
			draw_string(ThemeDB.fallback_font, centre + Vector2(-4.0, 5.0), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _color_of(cell: Vector2i) -> Color:
	if _map.is_blocked(cell):
		return BLOCKED
	if _map.find_exit_at(cell) != null:
		return EXIT
	match _map.kind_at(cell):
		"stairs":
			return STAIRS
		"ladder":
			return LADDER
	return WALKABLE
