class_name MapLayoutTest
extends GdUnitTestSuite

const COLUMNS: int = 10
const ROWS: int = 20


func test_even_rows_hold_all_columns_and_odd_rows_one_less() -> void:
	assert_int(MapLayout.row_length(COLUMNS, 0)).is_equal(10)
	assert_int(MapLayout.row_length(COLUMNS, 1)).is_equal(9)
	assert_int(MapLayout.row_length(COLUMNS, 18)).is_equal(10)
	assert_int(MapLayout.row_length(COLUMNS, 19)).is_equal(9)


func test_a_10_by_20_map_has_190_cells() -> void:
	assert_int(MapLayout.cell_count(COLUMNS, ROWS)).is_equal(190)
	assert_int(MapLayout.all_cells(COLUMNS, ROWS).size()).is_equal(190)


func test_known_rows_and_columns_map_to_known_cells() -> void:
	assert_vector(MapLayout.cell_from_row_col(0, 0)).is_equal(Vector2i(0, 0))
	assert_vector(MapLayout.cell_from_row_col(0, 1)).is_equal(Vector2i(1, -1))
	assert_vector(MapLayout.cell_from_row_col(1, 0)).is_equal(Vector2i(1, 0))
	assert_vector(MapLayout.cell_from_row_col(2, 0)).is_equal(Vector2i(1, 1))
	assert_vector(MapLayout.cell_from_row_col(3, 2)).is_equal(Vector2i(4, -1))


func test_every_cell_survives_the_round_trip() -> void:
	for row: int in ROWS:
		for col: int in MapLayout.row_length(COLUMNS, row):
			var cell: Vector2i = MapLayout.cell_from_row_col(row, col)
			assert_vector(MapLayout.row_col_from_cell(cell)).is_equal(Vector2i(row, col))


func test_all_cells_are_different() -> void:
	var seen: Dictionary = {}
	for cell: Vector2i in MapLayout.all_cells(COLUMNS, ROWS):
		assert_bool(seen.has(cell)).is_false()
		seen[cell] = true


func test_neighbours_in_a_row_are_two_cells_apart_on_the_diamond_grid() -> void:
	var left: Vector2i = MapLayout.cell_from_row_col(4, 3)
	var right: Vector2i = MapLayout.cell_from_row_col(4, 4)
	assert_vector(right - left).is_equal(Vector2i(1, -1))


func test_the_cell_below_is_one_diagonal_step() -> void:
	var cell: Vector2i = MapLayout.cell_from_row_col(4, 3)
	var below_right: Vector2i = MapLayout.cell_from_row_col(5, 3)
	var below_left: Vector2i = MapLayout.cell_from_row_col(5, 2)
	assert_vector(below_right - cell).is_equal(Vector2i(1, 0))
	assert_vector(below_left - cell).is_equal(Vector2i(0, 1))


func test_pixel_positions_agree_with_grid_math() -> void:
	var grid: GridMath = GridMath.new()
	for row: int in ROWS:
		for col: int in MapLayout.row_length(COLUMNS, row):
			var from_layout: Vector2 = MapLayout.pixel_center(row, col)
			var from_grid: Vector2 = grid.cell_to_pixel(MapLayout.cell_from_row_col(row, col))
			assert_vector(from_layout).is_equal(from_grid)


func test_the_map_picture_is_1280_by_672() -> void:
	assert_vector(MapLayout.pixel_size(COLUMNS, ROWS)).is_equal(Vector2(1280, 672))


func test_every_cell_diamond_lies_inside_the_picture() -> void:
	var size: Vector2 = MapLayout.pixel_size(COLUMNS, ROWS)
	for row: int in ROWS:
		for col: int in MapLayout.row_length(COLUMNS, row):
			var centre: Vector2 = MapLayout.pixel_center(row, col)
			assert_float(centre.x - 64.0).is_greater_equal(0.0)
			assert_float(centre.x + 64.0).is_less_equal(size.x)
			assert_float(centre.y - 32.0).is_greater_equal(0.0)
			assert_float(centre.y + 32.0).is_less_equal(size.y)


func test_contains_accepts_cells_of_the_map_and_rejects_others() -> void:
	assert_bool(MapLayout.contains(COLUMNS, ROWS, Vector2i(0, 0))).is_true()
	assert_bool(MapLayout.contains(COLUMNS, ROWS, MapLayout.cell_from_row_col(19, 8))).is_true()
	assert_bool(MapLayout.contains(COLUMNS, ROWS, MapLayout.cell_from_row_col(19, 9))).is_false()
	assert_bool(MapLayout.contains(COLUMNS, ROWS, MapLayout.cell_from_row_col(20, 0))).is_false()
	assert_bool(MapLayout.contains(COLUMNS, ROWS, Vector2i(-1, 0))).is_false()


func test_edges_of_cells() -> void:
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 0, 4)).is_equal(["top"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 19, 4)).is_equal(["bottom"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 7, 0)).is_equal(["left"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 6, 9)).is_equal(["right"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 7, 8)).is_equal(["right"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 0, 0)).is_equal(["top", "left"])
	assert_array(MapLayout.edges_of(COLUMNS, ROWS, 10, 5)).is_empty()
