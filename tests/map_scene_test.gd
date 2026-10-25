class_name MapSceneTest
extends GdUnitTestSuite
## Keeps the painted map scenes honest: what you see (TileMapLayers) must match the data
## the rules use (MapDef) and the pixel maths used for input (GridMath).

const MAPS: Dictionary = {
	"res://tests/fixtures/maps/start_01.tres": "res://tests/fixtures/maps/map_start_01.tscn",
	"res://tests/fixtures/maps/start_02.tres": "res://tests/fixtures/maps/map_start_02.tscn",
}


func _kind_at(layer: TileMapLayer, cell: Vector2i) -> String:
	var data: TileData = layer.get_cell_tile_data(cell)
	return "" if data == null else str(data.get_custom_data("kind"))


func test_ground_covers_exactly_the_map_area() -> void:
	for map_path: String in MAPS:
		var map: MapDef = load(map_path)
		var scene: Node2D = auto_free((load(MAPS[map_path]) as PackedScene).instantiate())
		var ground: TileMapLayer = scene.get_node("Ground")
		assert_int(ground.get_used_cells().size()).is_equal(map.size.x * map.size.y)
		for cell: Vector2i in ground.get_used_cells():
			assert_bool(map.is_in_bounds(cell)).is_true()


func test_obstacles_match_blocked_cells_of_the_map_data() -> void:
	for map_path: String in MAPS:
		var map: MapDef = load(map_path)
		var scene: Node2D = auto_free((load(MAPS[map_path]) as PackedScene).instantiate())
		var objects: TileMapLayer = scene.get_node("Objects")
		var painted: Array[Vector2i] = []
		for cell: Vector2i in objects.get_used_cells():
			assert_str(_kind_at(objects, cell)).is_equal("obstacle")
			painted.append(cell)
		painted.sort()
		var expected: Array[Vector2i] = map.blocked_cells.duplicate()
		expected.sort()
		assert_array(painted).is_equal(expected)


func test_exit_tiles_match_exit_cells_of_the_map_data() -> void:
	for map_path: String in MAPS:
		var map: MapDef = load(map_path)
		var scene: Node2D = auto_free((load(MAPS[map_path]) as PackedScene).instantiate())
		var ground: TileMapLayer = scene.get_node("Ground")
		var painted: Array[Vector2i] = []
		for cell: Vector2i in ground.get_used_cells():
			if _kind_at(ground, cell) == "exit":
				painted.append(cell)
		painted.sort()
		var expected: Array[Vector2i] = []
		for exit: MapExit in map.exits:
			expected.append_array(exit.cells)
		expected.sort()
		assert_array(painted).is_equal(expected)


func test_tilemap_positions_agree_with_grid_math() -> void:
	var scene: Node2D = auto_free((load("res://tests/fixtures/maps/map_start_01.tscn") as PackedScene).instantiate())
	var ground: TileMapLayer = scene.get_node("Ground")
	var grid: GridMath = GridMath.new()
	assert_vector(Vector2(ground.tile_set.tile_size)).is_equal(Vector2(grid.tile_width, grid.tile_height))
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 7), Vector2i(11, 11), Vector2i(5, 9)]:
		assert_vector(ground.map_to_local(cell)).is_equal(grid.cell_to_pixel(cell))
		assert_vector(ground.local_to_map(grid.cell_to_pixel(cell))).is_equal(cell)
