class_name GridMathTest
extends GdUnitTestSuite

var _grid: GridMath


func before_test() -> void:
	_grid = GridMath.new()


func test_origin_cell_centre_is_half_a_tile_from_the_origin() -> void:
	assert_vector(_grid.cell_to_pixel(Vector2i(0, 0))).is_equal(Vector2(64, 32))


func test_neighbour_cells_move_along_the_diamond_axes() -> void:
	assert_vector(_grid.cell_to_pixel(Vector2i(1, 0))).is_equal(Vector2(128, 64))
	assert_vector(_grid.cell_to_pixel(Vector2i(0, 1))).is_equal(Vector2(0, 64))
	assert_vector(_grid.cell_to_pixel(Vector2i(1, 1))).is_equal(Vector2(64, 96))


func test_round_trip_cell_pixel_cell_for_many_cells() -> void:
	for x: int in range(-20, 21):
		for y: int in range(-20, 21):
			var cell := Vector2i(x, y)
			assert_vector(_grid.pixel_to_cell(_grid.cell_to_pixel(cell))).is_equal(cell)


func test_points_inside_a_diamond_map_to_that_cell() -> void:
	var centre: Vector2 = _grid.cell_to_pixel(Vector2i(3, 5))
	for offset: Vector2 in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 15), Vector2(0, -15), Vector2(20, 10)]:
		assert_vector(_grid.pixel_to_cell(centre + offset)).is_equal(Vector2i(3, 5))


func test_points_just_across_each_edge_map_to_the_neighbour() -> void:
	var centre: Vector2 = _grid.cell_to_pixel(Vector2i(3, 5))
	assert_vector(_grid.pixel_to_cell(centre + Vector2(36, 18))).is_equal(Vector2i(4, 5))
	assert_vector(_grid.pixel_to_cell(centre + Vector2(-36, 18))).is_equal(Vector2i(3, 6))
	assert_vector(_grid.pixel_to_cell(centre + Vector2(-36, -18))).is_equal(Vector2i(2, 5))
	assert_vector(_grid.pixel_to_cell(centre + Vector2(36, -18))).is_equal(Vector2i(3, 4))


func test_negative_cells_round_trip() -> void:
	assert_vector(_grid.pixel_to_cell(_grid.cell_to_pixel(Vector2i(-7, 3)))).is_equal(Vector2i(-7, 3))


func test_map_bounds_hold_every_cell_of_the_map() -> void:
	var size := Vector2i(12, 12)
	var bounds: Rect2 = _grid.map_pixel_bounds(size)
	assert_vector(bounds.position).is_equal(Vector2(-704, 0))
	assert_vector(bounds.size).is_equal(Vector2(1536, 768))
	for x: int in [0, 11]:
		for y: int in [0, 11]:
			var centre: Vector2 = _grid.cell_to_pixel(Vector2i(x, y))
			assert_bool(bounds.has_point(centre)).is_true()
			assert_bool(bounds.has_point(centre + Vector2(60, 0))).is_true() if x == 11 and y == 0 else null


func test_custom_tile_size_is_respected() -> void:
	var small := GridMath.new(64, 32)
	assert_vector(small.cell_to_pixel(Vector2i(1, 0))).is_equal(Vector2(64, 32))
	assert_vector(small.pixel_to_cell(Vector2(64, 32))).is_equal(Vector2i(1, 0))
