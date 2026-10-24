class_name AuthorityTest
extends GdUnitTestSuite

var _authority: Authority


func before_test() -> void:
	var maps: Dictionary = {}
	for path: String in ["res://content/maps/start_01.tres", "res://content/maps/start_02.tres"]:
		var map: MapDef = load(path)
		maps[map.id] = map
	_authority = Authority.new(maps, 1234)
	_authority.add_character("player:1", "map.start.01")


func test_new_character_stands_on_the_spawn_cell() -> void:
	var character: CharacterState = _authority.get_character("player:1")
	assert_str(character.map_id).is_equal("map.start.01")
	assert_vector(character.cell).is_equal(Vector2i(2, 5))


func test_valid_move_changes_state_and_returns_a_moved_event() -> void:
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:1", Vector2i(2, 8)))
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0] is MovedEvent).is_true()
	var moved: MovedEvent = events[0] as MovedEvent
	assert_vector(moved.path[0]).is_equal(Vector2i(2, 5))
	assert_vector(moved.path[moved.path.size() - 1]).is_equal(Vector2i(2, 8))
	assert_vector(_authority.get_character("player:1").cell).is_equal(Vector2i(2, 8))


func test_move_to_a_blocked_cell_is_rejected_and_state_is_unchanged() -> void:
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:1", Vector2i(5, 5)))
	assert_bool(events[0] is CommandRejectedEvent).is_true()
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("no_path")
	assert_vector(_authority.get_character("player:1").cell).is_equal(Vector2i(2, 5))


func test_move_to_the_current_cell_is_rejected() -> void:
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:1", Vector2i(2, 5)))
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("already_there")


func test_unknown_player_is_rejected() -> void:
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:99", Vector2i(3, 5)))
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("unknown_player")


func test_walking_onto_an_exit_cell_changes_the_map() -> void:
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:1", Vector2i(11, 5)))
	assert_int(events.size()).is_equal(2)
	assert_bool(events[0] is MovedEvent).is_true()
	assert_bool(events[1] is MapChangedEvent).is_true()
	var changed: MapChangedEvent = events[1] as MapChangedEvent
	assert_str(changed.from_map_id).is_equal("map.start.01")
	assert_str(changed.map_id).is_equal("map.start.02")
	var character: CharacterState = _authority.get_character("player:1")
	assert_str(character.map_id).is_equal("map.start.02")
	assert_vector(character.cell).is_equal(Vector2i(1, 5))


func test_after_changing_map_moves_use_the_new_map() -> void:
	_authority.submit(MoveCommand.create("player:1", Vector2i(11, 5)))
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create("player:1", Vector2i(4, 3)))
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("no_path")
	events = _authority.submit(MoveCommand.create("player:1", Vector2i(3, 5)))
	assert_str((events[0] as MovedEvent).map_id).is_equal("map.start.02")


func test_two_characters_are_independent() -> void:
	_authority.add_character("player:2", "map.start.02")
	_authority.submit(MoveCommand.create("player:1", Vector2i(2, 8)))
	assert_vector(_authority.get_character("player:2").cell).is_equal(Vector2i(2, 5))
	assert_str(_authority.get_character("player:2").map_id).is_equal("map.start.02")


func test_same_seed_gives_same_random_sequence() -> void:
	var other: Authority = Authority.new({}, 1234)
	assert_int(other.rng.randi()).is_equal(_authority.rng.randi())
