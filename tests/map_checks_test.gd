class_name MapChecksTest
extends GdUnitTestSuite


func _screen_map(columns: int, rows: int) -> MapDef:
	var map: MapDef = MapDef.new()
	map.id = "map.test.00_00"
	map.shape = MapDef.Shape.SCREEN
	map.size = Vector2i(columns, rows)
	map.spawn_cell = MapLayout.cell_from_row_col(0, 0)
	return map


func test_an_open_map_has_no_unreachable_cells() -> void:
	assert_array(MapChecks.unreachable_cells(_screen_map(6, 8))).is_empty()


func test_a_cell_walled_off_from_the_spawn_is_reported() -> void:
	var map: MapDef = _screen_map(6, 8)
	# Wall off cell row 4 column 3 completely: its eight neighbours are blocked.
	var inside: Vector2i = MapLayout.cell_from_row_col(4, 3)
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				map.blocked_cells.append(inside + Vector2i(dx, dy))
	var errors: Array[String] = MapChecks.unreachable_cells(map)
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0]).contains("row 4 column 3")


func test_a_platform_without_stairs_is_unreachable_and_with_stairs_is_reachable() -> void:
	var map: MapDef = _screen_map(6, 8)
	var platform: Vector2i = MapLayout.cell_from_row_col(4, 3)
	map.heights = {platform: 1}
	assert_int(MapChecks.unreachable_cells(map).size()).is_equal(1)
	# Stairs on the cell beside it, at the lower level, leading up to the platform.
	map.cell_kinds = {platform + Vector2i(-1, 0): "stairs"}
	assert_array(map.validate()).is_empty()
	assert_array(MapChecks.unreachable_cells(map)).is_empty()


func test_missing_translations_are_reported_per_language() -> void:
	var keys_by_language: Dictionary = {"en": ["sign.a", "sign.b"], "pl": ["sign.a"]}
	var errors: Array[String] = MapChecks.missing_translations("map.test.00_00", ["sign.a", "sign.b"], keys_by_language)
	assert_int(errors.size()).is_equal(1)
	assert_str(errors[0]).contains("'sign.b'").contains("'pl'")


func test_a_tall_platform_in_front_hides_a_cell_behind_it() -> void:
	var map: MapDef = _screen_map(8, 12)
	var behind: Vector2i = MapLayout.cell_from_row_col(4, 3)
	# One cell in front on the screen: the cell below it (two rows down, same column).
	var front: Vector2i = MapLayout.cell_from_row_col(6, 3)
	map.heights = {front: 4}
	var warnings: Array[String] = MapChecks.hidden_cells(map)
	var found: bool = false
	for warning: String in warnings:
		found = found or warning.contains("row 4 column 3")
	assert_bool(found).is_true()
	assert_bool(behind != front).is_true()


func test_a_flat_map_hides_nothing() -> void:
	assert_array(MapChecks.hidden_cells(_screen_map(8, 12))).is_empty()


func test_a_low_platform_hides_nothing_far_behind() -> void:
	var map: MapDef = _screen_map(8, 12)
	map.heights = {MapLayout.cell_from_row_col(10, 3): 1}
	for warning: String in MapChecks.hidden_cells(map):
		assert_bool(warning.contains("row 2 ")).is_false()


func test_check_set_combines_validation_and_reachability() -> void:
	var map: MapDef = _screen_map(6, 8)
	map.heights = {MapLayout.cell_from_row_col(4, 3): 1}
	var errors: Array[String] = MapChecks.check_set({map.id: map})
	assert_int(errors.size()).is_equal(1)
