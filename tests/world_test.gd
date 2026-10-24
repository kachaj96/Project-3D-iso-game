class_name WorldTest
extends GdUnitTestSuite

var _grid: GridMath = GridMath.new()


func _make_world() -> World:
	var world: World = auto_free((load("res://scenes/world/world.tscn") as PackedScene).instantiate())
	world.walk_speed = 1000000.0
	add_child(world)
	return world


func test_world_starts_on_the_first_map_at_its_spawn_cell() -> void:
	var world: World = _make_world()
	assert_str(world.current_map_id()).is_equal("map.start.01")
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 5)))


func test_tap_walks_the_character_to_the_tapped_cell() -> void:
	var world: World = _make_world()
	var events: Array[GameEvent] = world.tap_at(_grid.cell_to_pixel(Vector2i(2, 8)))
	assert_bool(events[0] is MovedEvent).is_true()
	await world.walk_finished
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 8)))


func test_tap_inside_a_cell_not_only_on_its_centre_works() -> void:
	var world: World = _make_world()
	var events: Array[GameEvent] = world.tap_at(_grid.cell_to_pixel(Vector2i(3, 5)) + Vector2(20, 10))
	assert_vector((events[0] as MovedEvent).path.back()).is_equal(Vector2i(3, 5))
	await world.walk_finished


func test_tap_on_an_obstacle_is_refused_and_the_character_stays() -> void:
	var world: World = _make_world()
	var events: Array[GameEvent] = world.tap_at(_grid.cell_to_pixel(Vector2i(5, 5)))
	assert_bool(events[0] is CommandRejectedEvent).is_true()
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 5)))


func test_taps_while_walking_are_ignored() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 9)))
	assert_array(world.tap_at(_grid.cell_to_pixel(Vector2i(4, 9)))).is_empty()
	await world.walk_finished
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 9)))


func test_walking_onto_an_exit_shows_the_next_map() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(11, 5)))
	await world.walk_finished
	assert_str(world.current_map_id()).is_equal("map.start.02")
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(1, 5)))
	var events: Array[GameEvent] = world.tap_at(_grid.cell_to_pixel(Vector2i(3, 5)))
	assert_bool(events[0] is MovedEvent).is_true()
	assert_str((events[0] as MovedEvent).map_id).is_equal("map.start.02")
	await world.walk_finished
