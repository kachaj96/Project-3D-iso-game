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


func test_eight_way_walks_diagonally_when_it_is_shorter() -> void:
	var finder: Pathfinder = Pathfinder.new(_make_map([]), Pathfinder.Movement.EIGHT_WAY)
	assert_array(finder.find_path(Vector2i(0, 0), Vector2i(3, 3))).is_equal([Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)])


func test_eight_way_never_cuts_the_corner_of_an_obstacle() -> void:
	var finder: Pathfinder = Pathfinder.new(_make_map([Vector2i(1, 0)]), Pathfinder.Movement.EIGHT_WAY)
	assert_array(finder.find_path(Vector2i(0, 0), Vector2i(1, 1))).is_equal([Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)])


func test_eight_way_cannot_squeeze_between_two_diagonal_obstacles() -> void:
	var finder: Pathfinder = Pathfinder.new(_make_map([Vector2i(1, 0), Vector2i(0, 1)]), Pathfinder.Movement.EIGHT_WAY)
	assert_array(finder.find_path(Vector2i(0, 0), Vector2i(1, 1))).is_empty()


func test_eight_way_steps_are_single_and_avoid_obstacles() -> void:
	var blocked: Array[Vector2i] = [Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(4, 4)]
	var path: Array[Vector2i] = Pathfinder.new(_make_map(blocked), Pathfinder.Movement.EIGHT_WAY).find_path(Vector2i(0, 2), Vector2i(5, 5))
	assert_bool(path.is_empty()).is_false()
	for i: int in range(1, path.size()):
		var step: Vector2i = path[i] - path[i - 1]
		assert_int(maxi(absi(step.x), absi(step.y))).is_equal(1)
		assert_bool(blocked.has(path[i])).is_false()


func test_paths_reach_corners_and_edges_of_the_map() -> void:
	for movement: Pathfinder.Movement in [Pathfinder.Movement.FOUR_WAY, Pathfinder.Movement.EIGHT_WAY]:
		var finder: Pathfinder = Pathfinder.new(_make_map([]), movement)
		assert_vector(finder.find_path(Vector2i(0, 0), Vector2i(5, 5)).back()).is_equal(Vector2i(5, 5))
		assert_vector(finder.find_path(Vector2i(5, 0), Vector2i(0, 5)).back()).is_equal(Vector2i(0, 5))
		assert_vector(finder.find_path(Vector2i(0, 5), Vector2i(5, 5)).back()).is_equal(Vector2i(5, 5))


func test_path_from_a_cell_to_itself_is_that_cell() -> void:
	assert_array(Pathfinder.new(_make_map([])).find_path(Vector2i(2, 2), Vector2i(2, 2))).is_equal([Vector2i(2, 2)])


## A 6x6 map where x 3..5 is a platform on level 1, reached only by stairs at (2,2).
func _make_platform_map() -> MapDef:
	var map: MapDef = _make_map([])
	for x: int in range(3, 6):
		for y: int in 6:
			map.heights[Vector2i(x, y)] = 1
	map.cell_kinds = {Vector2i(2, 2): "stairs"}
	return map


func test_a_path_climbs_the_platform_only_by_the_stairs() -> void:
	var finder: Pathfinder = Pathfinder.new(_make_platform_map(), Pathfinder.Movement.EIGHT_WAY)
	var path: Array[Vector2i] = finder.find_path(Vector2i(0, 5), Vector2i(5, 5))
	assert_bool(path.is_empty()).is_false()
	assert_bool(path.has(Vector2i(2, 2))).is_true()
	assert_vector(path[path.find(Vector2i(2, 2)) + 1]).is_equal(Vector2i(3, 2))


func test_a_platform_without_stairs_cannot_be_reached() -> void:
	var map: MapDef = _make_platform_map()
	map.cell_kinds = {}
	assert_array(Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY).find_path(Vector2i(0, 0), Vector2i(5, 5))).is_empty()


func test_paths_never_change_level_on_a_diagonal_step() -> void:
	var map: MapDef = _make_platform_map()
	var finder: Pathfinder = Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY)
	var path: Array[Vector2i] = finder.find_path(Vector2i(0, 0), Vector2i(5, 5))
	for i: int in range(1, path.size()):
		var step: Vector2i = path[i] - path[i - 1]
		if step.x != 0 and step.y != 0:
			assert_int(map.height_at(path[i])).is_equal(map.height_at(path[i - 1]))


func test_stairs_are_preferred_to_a_ladder_unless_the_ladder_is_much_shorter() -> void:
	# Level 1 platform for x >= 3. Stairs at (2,0) and a ladder at (2,5); start at (0,5).
	var map: MapDef = _make_map([])
	for x: int in range(3, 6):
		for y: int in 6:
			map.heights[Vector2i(x, y)] = 1
	map.cell_kinds = {Vector2i(2, 0): "stairs", Vector2i(2, 5): "ladder"}
	var finder: Pathfinder = Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY)
	# From the ladder side the short ladder route (about 3 steps + weight) beats walking 5 rows up.
	assert_bool(finder.find_path(Vector2i(0, 5), Vector2i(5, 5)).has(Vector2i(2, 5))).is_true()
	# Next to the stairs, the stairs win.
	assert_bool(finder.find_path(Vector2i(0, 0), Vector2i(5, 0)).has(Vector2i(2, 0))).is_true()


func test_a_ladder_is_used_when_it_is_the_only_way_up() -> void:
	var map: MapDef = _make_map([])
	for x: int in range(3, 6):
		for y: int in 6:
			map.heights[Vector2i(x, y)] = 4
	map.cell_kinds = {Vector2i(2, 3): "ladder"}
	var path: Array[Vector2i] = Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY).find_path(Vector2i(0, 0), Vector2i(5, 5))
	assert_bool(path.has(Vector2i(2, 3))).is_true()


func test_a_path_works_on_a_screen_shaped_map() -> void:
	var map: MapDef = MapDef.new()
	map.id = "map.test.screen"
	map.shape = MapDef.Shape.SCREEN
	map.size = Vector2i(10, 20)
	var finder: Pathfinder = Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY)
	var start: Vector2i = MapLayout.cell_from_row_col(0, 0)
	var goal: Vector2i = MapLayout.cell_from_row_col(19, 8)
	var path: Array[Vector2i] = finder.find_path(start, goal)
	assert_bool(path.is_empty()).is_false()
	for cell: Vector2i in path:
		assert_bool(map.is_in_bounds(cell)).is_true()
