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
