class_name MapDefTest
extends GdUnitTestSuite


func _make_map(id: String) -> MapDef:
	var map: MapDef = MapDef.new()
	map.id = id
	map.size = Vector2i(6, 6)
	map.spawn_cell = Vector2i(1, 1)
	return map


func _make_exit(cell: Vector2i, target: String, entry: Vector2i) -> MapExit:
	var exit: MapExit = MapExit.new()
	exit.cells = [cell]
	exit.target_map_id = target
	exit.target_entry_cell = entry
	return exit


func test_valid_map_has_no_problems() -> void:
	assert_array(_make_map("map.test.01").validate()).is_empty()


func test_bad_id_is_reported() -> void:
	assert_bool(_make_map("Not A Map").validate().is_empty()).is_false()


func test_blocked_spawn_and_out_of_bounds_cells_are_reported() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.blocked_cells = [Vector2i(1, 1), Vector2i(20, 20)]
	assert_int(map.validate().size()).is_equal(2)


func test_find_exit_at_returns_exit_or_null() -> void:
	var map: MapDef = _make_map("map.test.01")
	var exit: MapExit = _make_exit(Vector2i(5, 2), "map.test.02", Vector2i(0, 2))
	map.exits = [exit]
	assert_object(map.find_exit_at(Vector2i(5, 2))).is_same(exit)
	assert_object(map.find_exit_at(Vector2i(0, 0))).is_null()


func test_validate_set_catches_unknown_target_and_bad_entry_cell() -> void:
	var a: MapDef = _make_map("map.test.01")
	var b: MapDef = _make_map("map.test.02")
	b.blocked_cells = [Vector2i(0, 2)]
	a.exits = [_make_exit(Vector2i(5, 2), "map.test.02", Vector2i(0, 2)), _make_exit(Vector2i(5, 3), "map.nowhere", Vector2i(0, 0))]
	var problems: Array[String] = MapDef.validate_set({"map.test.01": a, "map.test.02": b})
	assert_int(problems.size()).is_equal(2)


func test_shipped_start_maps_are_valid_and_connected() -> void:
	var maps: Dictionary = {}
	for path: String in ["res://content/maps/start_01.tres", "res://content/maps/start_02.tres"]:
		var map: MapDef = load(path)
		assert_object(map).is_not_null()
		maps[map.id] = map
	assert_array(MapDef.validate_set(maps)).is_empty()
	assert_int((maps["map.start.01"] as MapDef).size.x).is_equal(12)


func _make_prop(id: String, cell: Vector2i) -> MapProp:
	var prop: MapProp = MapProp.new()
	prop.id = id
	prop.cell = cell
	prop.text_key = "sign.test"
	return prop


func test_a_prop_on_a_blocked_cell_is_valid() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.blocked_cells = [Vector2i(3, 3)]
	map.props = [_make_prop("prop.test.sign", Vector2i(3, 3))]
	assert_array(map.validate()).is_empty()
	assert_object(map.find_prop_at(Vector2i(3, 3))).is_not_null()
	assert_object(map.find_prop_at(Vector2i(0, 0))).is_null()


func test_bad_props_are_reported() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.blocked_cells = [Vector2i(3, 3), Vector2i(4, 4)]
	var no_key: MapProp = _make_prop("prop.test.b", Vector2i(4, 4))
	no_key.text_key = ""
	map.props = [
		_make_prop("prop.test.a", Vector2i(2, 2)),
		_make_prop("Bad Id", Vector2i(3, 3)),
		_make_prop("prop.test.a", Vector2i(3, 3)),
		no_key,
	]
	assert_int(map.validate().size()).is_equal(4)


func test_a_prop_of_unknown_kind_is_reported() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.blocked_cells = [Vector2i(3, 3)]
	var typo: MapProp = _make_prop("prop.test.sign", Vector2i(3, 3))
	typo.kind = "sing"
	map.props = [typo]
	assert_int(map.validate().size()).is_equal(1)


func _make_stairs_map() -> MapDef:
	# Stairs at (2,2) on level 0 lead up to (3,2) on level 1.
	var map: MapDef = _make_map("map.test.01")
	map.heights = {Vector2i(3, 2): 1, Vector2i(4, 2): 1}
	map.cell_kinds = {Vector2i(2, 2): "stairs"}
	return map


func test_cells_without_a_height_or_kind_are_plain_level_zero() -> void:
	var map: MapDef = _make_stairs_map()
	assert_int(map.height_at(Vector2i(0, 0))).is_equal(0)
	assert_int(map.height_at(Vector2i(3, 2))).is_equal(1)
	assert_str(map.kind_at(Vector2i(0, 0))).is_equal("")
	assert_str(map.kind_at(Vector2i(2, 2))).is_equal("stairs")


func test_a_map_with_valid_stairs_has_no_problems() -> void:
	assert_array(_make_stairs_map().validate()).is_empty()


func test_stairs_without_a_higher_neighbour_are_reported() -> void:
	var map: MapDef = _make_stairs_map()
	map.heights = {}
	assert_int(map.validate().size()).is_equal(1)


func test_stairs_leading_to_two_neighbours_are_reported() -> void:
	var map: MapDef = _make_stairs_map()
	map.heights[Vector2i(1, 2)] = 1
	assert_int(map.validate().size()).is_equal(1)


func test_a_ladder_may_lead_up_several_levels() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.heights = {Vector2i(3, 2): 4}
	map.cell_kinds = {Vector2i(2, 2): "ladder"}
	assert_array(map.validate()).is_empty()
	map.heights = {Vector2i(3, 2): 5}
	assert_int(map.validate().size()).is_equal(1)


func test_levels_outside_zero_to_seven_are_reported() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.heights = {Vector2i(1, 3): 8, Vector2i(2, 3): -1}
	assert_int(map.validate().size()).is_equal(2)


func test_unknown_cell_kind_and_blocked_stairs_are_reported() -> void:
	var map: MapDef = _make_stairs_map()
	map.cell_kinds[Vector2i(0, 5)] = "elevator"
	map.blocked_cells = [Vector2i(2, 2)]
	assert_int(map.validate().size()).is_equal(2)


func test_unknown_exit_kind_is_reported() -> void:
	var map: MapDef = _make_map("map.test.01")
	var exit: MapExit = _make_exit(Vector2i(5, 2), "map.test.02", Vector2i(0, 2))
	exit.kind = "portal"
	map.exits = [exit]
	assert_int(map.validate().size()).is_equal(1)
	exit.kind = "stairs"
	assert_array(map.validate()).is_empty()


func test_can_step_follows_the_level_rules() -> void:
	var map: MapDef = _make_stairs_map()
	assert_bool(map.can_step(Vector2i(2, 2), Vector2i(3, 2))).is_true()
	assert_bool(map.can_step(Vector2i(3, 2), Vector2i(2, 2))).is_true()
	assert_bool(map.can_step(Vector2i(1, 2), Vector2i(2, 2))).is_true()
	# A plain cell never climbs: (4,2) is level 1 and (4,3) level 0.
	assert_bool(map.can_step(Vector2i(4, 2), Vector2i(4, 3))).is_false()
	# A diagonal step off the stairs never changes level, even toward a cell one level higher.
	map.heights[Vector2i(3, 3)] = 1
	assert_bool(map.can_step(Vector2i(2, 2), Vector2i(3, 3))).is_false()


func test_can_step_refuses_blocked_cells_and_cut_corners() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.blocked_cells = [Vector2i(2, 1)]
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(2, 1))).is_false()
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(2, 2))).is_false()
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(1, 2))).is_true()
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(9, 9))).is_false()


func test_a_screen_map_uses_the_screen_layout_for_bounds() -> void:
	var map: MapDef = MapDef.new()
	map.id = "map.test.screen"
	map.shape = MapDef.Shape.SCREEN
	map.size = Vector2i(10, 20)
	map.spawn_cell = MapLayout.cell_from_row_col(5, 4)
	assert_array(map.validate()).is_empty()
	assert_int(map.all_cells().size()).is_equal(190)
	assert_bool(map.is_in_bounds(MapLayout.cell_from_row_col(0, 0))).is_true()
	assert_bool(map.is_in_bounds(MapLayout.cell_from_row_col(1, 9))).is_false()
	assert_bool(map.is_in_bounds(Vector2i(-50, 50))).is_false()


func test_a_diamond_map_lists_all_its_cells() -> void:
	assert_int(_make_map("map.test.01").all_cells().size()).is_equal(36)


func test_a_diagonal_step_cannot_squeeze_between_two_platform_corners() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.heights = {Vector2i(2, 1): 3, Vector2i(1, 2): 3}
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(2, 2))).is_false()
	assert_bool(map.can_step(Vector2i(2, 2), Vector2i(1, 1))).is_false()


func test_a_diagonal_step_cannot_cut_the_corner_of_a_platform_wall() -> void:
	var map: MapDef = _make_map("map.test.01")
	map.heights = {Vector2i(2, 1): 1}
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(2, 2))).is_false()
	assert_bool(map.can_step(Vector2i(2, 2), Vector2i(1, 1))).is_false()


func test_a_diagonal_step_along_the_edge_of_a_drop_is_allowed() -> void:
	# On a level 2 platform, walking diagonally past the corner of a lower cell.
	var map: MapDef = _make_map("map.test.01")
	for x: int in 6:
		for y: int in 6:
			map.heights[Vector2i(x, y)] = 2
	map.heights[Vector2i(2, 1)] = 0
	assert_bool(map.can_step(Vector2i(1, 1), Vector2i(2, 2))).is_true()
	assert_bool(map.can_step(Vector2i(2, 2), Vector2i(1, 1))).is_true()
