class_name PathfinderTest
extends GdUnitTestSuite


func _make_map(blocked: Array[Vector2i]) -> MapDef:
	var map: MapDef = MapDef.new()
	map.id = "map.test.01"
	map.size = Vector2i(6, 6)
	map.blocked_cells = blocked
	return map


func test_straight_path_includes_start_and_goal() -> void:
	var path: Array[Vector2i] = Pathfinder.new(_make_map([])).find_path(Vector2i(0, 0), Vector2i(3, 0))
	assert_array(path).is_equal([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])


func test_path_goes_around_a_wall() -> void:
	var wall: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
	var path: Array[Vector2i] = Pathfinder.new(_make_map(wall)).find_path(Vector2i(0, 0), Vector2i(4, 0))
	assert_bool(path.is_empty()).is_false()
	assert_vector(path[0]).is_equal(Vector2i(0, 0))
	assert_vector(path[path.size() - 1]).is_equal(Vector2i(4, 0))
	for cell: Vector2i in path:
		assert_bool(wall.has(cell)).is_false()


func test_steps_are_never_diagonal() -> void:
	var path: Array[Vector2i] = Pathfinder.new(_make_map([])).find_path(Vector2i(0, 0), Vector2i(4, 3))
	for i: int in range(1, path.size()):
		var step: Vector2i = path[i] - path[i - 1]
		assert_int(absi(step.x) + absi(step.y)).is_equal(1)


func test_no_route_gives_empty_path() -> void:
	var wall: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5)]
	assert_array(Pathfinder.new(_make_map(wall)).find_path(Vector2i(0, 0), Vector2i(4, 0))).is_empty()


func test_blocked_or_outside_goal_gives_empty_path() -> void:
	var finder: Pathfinder = Pathfinder.new(_make_map([Vector2i(3, 3)]))
	assert_array(finder.find_path(Vector2i(0, 0), Vector2i(3, 3))).is_empty()
	assert_array(finder.find_path(Vector2i(0, 0), Vector2i(9, 9))).is_empty()
	assert_array(finder.find_path(Vector2i(-1, 0), Vector2i(2, 2))).is_empty()


func test_path_from_a_cell_to_itself_is_that_cell() -> void:
	assert_array(Pathfinder.new(_make_map([])).find_path(Vector2i(2, 2), Vector2i(2, 2))).is_equal([Vector2i(2, 2)])
