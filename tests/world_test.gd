class_name WorldTest
extends GdUnitTestSuite

var _grid: GridMath = GridMath.new()
var _events: Array[GameEvent]


const FIXTURE_CATALOG: String = "res://tests/fixtures/maps/catalog.tres"


func _make_world() -> World:
	var world: World = auto_free((load("res://scenes/world/world.tscn") as PackedScene).instantiate())
	world.catalog_path = FIXTURE_CATALOG
	world.start_map_id = "map.start.01"
	world.walk_speed = 1000000.0
	add_child(world)
	_events = []
	world.session().events_emitted.connect(func(events: Array[GameEvent]) -> void: _events.append_array(events))
	return world


func test_world_starts_on_the_first_map_at_its_spawn_cell() -> void:
	var world: World = _make_world()
	assert_str(world.current_map_id()).is_equal("map.start.01")
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 5)))


func test_tap_walks_the_character_to_the_tapped_cell() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 8)))
	assert_bool(_events[0] is MovedEvent).is_true()
	await world.walk_finished
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 8)))


func test_tap_walks_diagonally_on_the_grid() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(4, 3)))
	assert_array((_events[0] as MovedEvent).path).is_equal([Vector2i(2, 5), Vector2i(3, 4), Vector2i(4, 3)])
	await world.walk_finished


func test_tap_inside_a_cell_not_only_on_its_centre_works() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 5)) + Vector2(20, 10))
	assert_vector((_events[0] as MovedEvent).path.back()).is_equal(Vector2i(3, 5))
	await world.walk_finished


func test_tap_on_an_obstacle_is_refused_and_the_character_stays() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(5, 5)))
	assert_bool(_events[0] is CommandRejectedEvent).is_true()
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 5)))


func test_taps_while_walking_are_ignored() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 9)))
	world.tap_at(_grid.cell_to_pixel(Vector2i(4, 9)))
	assert_int(_events.size()).is_equal(1)
	await world.walk_finished
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 9)))


func test_events_of_other_players_do_not_move_the_local_character() -> void:
	var world: World = _make_world()
	var stranger: MovedEvent = MovedEvent.new()
	stranger.player_id = "player:2"
	stranger.map_id = "map.start.01"
	stranger.path = [Vector2i(0, 0), Vector2i(1, 0)]
	world.session().events_emitted.emit([stranger] as Array[GameEvent])
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(2, 5)))


func test_walking_onto_an_exit_shows_the_next_map() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(11, 5)))
	await world.walk_finished
	assert_str(world.current_map_id()).is_equal("map.start.02")
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(Vector2i(1, 5)))
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 5)))
	assert_str((_events.back() as MovedEvent).map_id).is_equal("map.start.02")
	await world.walk_finished


func test_camera_view_stays_inside_the_map_in_a_corner() -> void:
	var world: World = _make_world()
	world.place_player_visual_at(Vector2i(0, 0))
	await get_tree().process_frame
	var camera: CameraRig = world.camera()
	var half_view: Vector2 = camera.get_viewport_rect().size / camera.zoom.x / 2.0
	var view: Rect2 = Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0)
	var bounds: Rect2 = _grid.map_pixel_bounds(Vector2i(12, 12)).grow_individual(0.0, camera.vertical_margin, 0.0, camera.vertical_margin)
	assert_bool(bounds.grow(1.0).encloses(view)).is_true()


func test_zoom_is_limited_at_both_ends() -> void:
	var world: World = _make_world()
	var camera: CameraRig = world.camera()
	camera.zoom_by(1000.0)
	assert_float(camera.zoom.x).is_equal_approx(camera.max_zoom, 0.0001)
	camera.zoom_by(0.0001)
	assert_float(camera.zoom.x).is_equal_approx(camera.min_zoom(), 0.0001)
	var view: Vector2 = camera.get_viewport_rect().size
	var bounds: Rect2 = _grid.map_pixel_bounds(Vector2i(12, 12))
	assert_float(camera.min_zoom()).is_greater_equal(view.x / (bounds.size.x + 1.0))


func test_camera_jumps_to_the_new_map_spawn_after_a_map_change() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(11, 5)))
	await world.walk_finished
	var camera: CameraRig = world.camera()
	await get_tree().process_frame
	assert_float(camera.global_position.distance_to(world.player_position() + camera.look_offset)).is_less(1.0)


func test_a_tap_on_the_screen_goes_to_the_cell_under_the_finger() -> void:
	var world: World = _make_world()
	await get_tree().process_frame
	var camera: CameraRig = world.camera()
	var gestures: TouchGestures = world.get_node("Gestures")
	var screen_point: Vector2 = camera.get_viewport_rect().size / 2.0 + Vector2(0, 100)
	var expected_cell: Vector2i = _grid.pixel_to_cell(camera.get_screen_center_position() + Vector2(0, 100) / camera.zoom.x)
	gestures.handle_touch(0, screen_point, true, 0)
	gestures.handle_touch(0, screen_point, false, 100)
	await world.walk_finished
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(expected_cell))


func test_taps_work_again_if_a_walk_is_cut_short() -> void:
	var world: World = _make_world()
	world.walk_speed = 1.0
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 9)))
	world.place_player_visual_at(Vector2i(2, 5))
	world.walk_speed = 1000000.0
	var before: int = _events.size()
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 9)))
	assert_int(_events.size()).is_greater(before)
	await world.walk_finished


func test_tapping_a_sign_walks_beside_it_and_opens_its_text() -> void:
	var world: World = _make_world()
	TranslationServer.set_locale("pl")
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 7)))
	assert_bool(_events[0] is MovedEvent).is_true()
	assert_bool(_events[1] is InteractedEvent).is_true()
	await world.walk_finished
	assert_bool(world.popup().is_open()).is_true()
	var label: Label = world.popup().get_node("Panel/Margin/Content/Text")
	assert_str(label.text).contains("Witaj w Overthune")
	TranslationServer.set_locale("en")
	world.popup().close()


func test_the_popup_text_follows_the_language() -> void:
	var world: World = _make_world()
	TranslationServer.set_locale("en")
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 7)))
	await world.walk_finished
	var label: Label = world.popup().get_node("Panel/Margin/Content/Text")
	assert_str(label.text).contains("Welcome to Overthune")
	world.popup().close()


func test_taps_are_ignored_while_the_text_is_open_and_work_after_closing() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 7)))
	await world.walk_finished
	var before: int = _events.size()
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 2)))
	assert_int(_events.size()).is_equal(before)
	world.popup().close()
	world.tap_at(_grid.cell_to_pixel(Vector2i(2, 2)))
	assert_int(_events.size()).is_greater(before)
	await world.walk_finished


func test_tapping_a_sign_you_stand_beside_opens_it_without_walking() -> void:
	var world: World = _make_world()
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 6)))
	await world.walk_finished
	var before: int = _events.size()
	world.tap_at(_grid.cell_to_pixel(Vector2i(3, 7)))
	assert_int(_events.size() - before).is_equal(1)
	assert_bool(_events.back() is InteractedEvent).is_true()
	assert_bool(world.popup().is_open()).is_true()
	world.popup().close()


func test_the_real_game_starts_on_the_forest_crypt_at_its_spawn_cell() -> void:
	var world: World = auto_free((load("res://scenes/world/world.tscn") as PackedScene).instantiate())
	add_child(world)
	assert_str(world.current_map_id()).is_equal("map.gluchobor.02_02")
	var map: MapDef = (load("res://content/maps/catalog.tres") as MapCatalog).load_maps()["map.gluchobor.02_02"]
	assert_vector(world.player_position()).is_equal(_grid.cell_to_pixel(map.spawn_cell))


func test_on_a_screen_shaped_map_the_camera_never_shows_beyond_the_picture() -> void:
	var world: World = auto_free((load("res://scenes/world/world.tscn") as PackedScene).instantiate())
	add_child(world)
	var camera: CameraRig = world.camera()
	var map: MapDef = (load("res://content/maps/catalog.tres") as MapCatalog).load_maps()["map.gluchobor.02_02"]
	var picture: Rect2 = Rect2(0.0, 0.0, 1280.0, 672.0)
	# The camera may not reach above the picture or below it, so its smallest zoom is a little above 1
	# on a 16:9 screen (672 px of picture must cover the 720 px of screen height).
	assert_float(camera.min_zoom()).is_greater_equal(camera.get_viewport_rect().size.y / 672.0 - 0.001)
	for corner: Vector2i in [MapLayout.cell_from_row_col(0, 0), MapLayout.cell_from_row_col(0, 9), MapLayout.cell_from_row_col(19, 8), MapLayout.cell_from_row_col(19, 0)]:
		world.place_player_visual_at(corner)
		await get_tree().process_frame
		await get_tree().process_frame
		var half_view: Vector2 = camera.get_viewport_rect().size / camera.zoom.x / 2.0
		var view: Rect2 = Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0)
		assert_bool(picture.grow(1.0).encloses(view)).is_true()
	assert_bool(map.shape == MapDef.Shape.SCREEN).is_true()
