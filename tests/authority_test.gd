class_name AuthorityTest
extends GdUnitTestSuite

const P1: String = "player:1"

var _authority: Authority
var _maps: Dictionary


func before_test() -> void:
	_maps = {}
	for path: String in ["res://tests/fixtures/maps/start_01.tres", "res://tests/fixtures/maps/start_02.tres"]:
		var map: MapDef = load(path)
		_maps[map.id] = map
	_authority = Authority.new(_maps, 1234)
	_authority.add_character(P1, "char.0000000000000001", "map.start.01")


func _move(sender: String, player: String, cell: Vector2i) -> Array[GameEvent]:
	return _authority.submit(sender, MoveCommand.create(player, cell))


func _reason(events: Array[GameEvent]) -> String:
	assert_bool(events[0] is CommandRejectedEvent).is_true()
	return (events[0] as CommandRejectedEvent).reason


func test_adding_a_character_returns_a_spawned_event_on_the_spawn_cell() -> void:
	var events: Array[GameEvent] = _authority.add_character("player:2", "char.0000000000000002", "map.start.02")
	assert_bool(events[0] is CharacterSpawnedEvent).is_true()
	var spawned: CharacterSpawnedEvent = events[0] as CharacterSpawnedEvent
	assert_str(spawned.player_id).is_equal("player:2")
	assert_str(spawned.character_id).is_equal("char.0000000000000002")
	assert_str(spawned.map_id).is_equal("map.start.02")
	assert_vector(spawned.cell).is_equal(Vector2i(2, 5))
	assert_str(_authority.get_character("player:2").character_id).is_equal("char.0000000000000002")


func test_a_taken_seat_is_rejected() -> void:
	assert_str(_reason(_authority.add_character(P1, "char.0000000000000009", "map.start.01"))).is_equal("seat_taken")


func test_the_same_character_cannot_join_twice() -> void:
	assert_str(_reason(_authority.add_character("player:2", "char.0000000000000001", "map.start.01"))).is_equal("character_already_present")


func test_an_unknown_map_or_empty_ids_are_rejected() -> void:
	assert_str(_reason(_authority.add_character("player:2", "char.0000000000000002", "map.nowhere"))).is_equal("unknown_map")
	assert_str(_reason(_authority.add_character("", "char.0000000000000002", "map.start.01"))).is_equal("invalid_character")
	assert_str(_reason(_authority.add_character("player:2", "", "map.start.01"))).is_equal("invalid_character")


func test_valid_move_changes_state_and_returns_a_moved_event() -> void:
	var events: Array[GameEvent] = _move(P1, P1, Vector2i(2, 8))
	assert_int(events.size()).is_equal(1)
	var moved: MovedEvent = events[0] as MovedEvent
	assert_vector(moved.path[0]).is_equal(Vector2i(2, 5))
	assert_vector(moved.path.back()).is_equal(Vector2i(2, 8))
	assert_vector(_authority.get_character(P1).cell).is_equal(Vector2i(2, 8))


func test_exploration_moves_diagonally_and_every_step_is_legal() -> void:
	var events: Array[GameEvent] = _move(P1, P1, Vector2i(9, 8))
	var moved: MovedEvent = events[0] as MovedEvent
	var map: MapDef = _maps["map.start.01"]
	var diagonal_steps: int = 0
	for i: int in range(1, moved.path.size()):
		var step: Vector2i = moved.path[i] - moved.path[i - 1]
		assert_int(maxi(absi(step.x), absi(step.y))).is_equal(1)
		assert_bool(map.is_blocked(moved.path[i])).is_false()
		if step.x != 0 and step.y != 0:
			diagonal_steps += 1
	assert_int(diagonal_steps).is_greater(0)


func test_a_command_for_another_player_is_rejected() -> void:
	_authority.add_character("player:2", "char.0000000000000002", "map.start.01")
	var events: Array[GameEvent] = _move("player:2", P1, Vector2i(2, 8))
	assert_str(_reason(events)).is_equal("wrong_player")
	assert_str(events[0].player_id).is_equal("player:2")
	assert_vector(_authority.get_character(P1).cell).is_equal(Vector2i(2, 5))


func test_a_null_or_unknown_command_is_rejected_without_crashing() -> void:
	assert_str(_reason(_authority.submit(P1, null))).is_equal("invalid_command")
	var unknown: GameCommand = GameCommand.new()
	unknown.player_id = P1
	assert_str(_reason(_authority.submit(P1, unknown))).is_equal("unknown_command")


func test_move_to_a_blocked_cell_is_rejected_and_state_is_unchanged() -> void:
	assert_str(_reason(_move(P1, P1, Vector2i(5, 5)))).is_equal("no_path")
	assert_vector(_authority.get_character(P1).cell).is_equal(Vector2i(2, 5))


func test_move_to_the_current_cell_is_rejected() -> void:
	assert_str(_reason(_move(P1, P1, Vector2i(2, 5)))).is_equal("already_there")


func test_a_seat_without_a_character_is_rejected() -> void:
	assert_str(_reason(_move("player:9", "player:9", Vector2i(3, 5)))).is_equal("unknown_player")


func test_walking_onto_an_exit_cell_changes_the_map() -> void:
	var events: Array[GameEvent] = _move(P1, P1, Vector2i(11, 5))
	assert_int(events.size()).is_equal(2)
	assert_bool(events[0] is MovedEvent).is_true()
	var changed: MapChangedEvent = events[1] as MapChangedEvent
	assert_str(changed.from_map_id).is_equal("map.start.01")
	assert_str(changed.map_id).is_equal("map.start.02")
	var character: CharacterState = _authority.get_character(P1)
	assert_str(character.map_id).is_equal("map.start.02")
	assert_vector(character.cell).is_equal(Vector2i(1, 5))


func test_walking_across_an_exit_cell_does_not_change_the_map() -> void:
	# A corridor whose only way through is the exit cell (1, 1). Decision D-010: only the
	# cell where a walk ends can trigger an exit.
	var corridor: MapDef = MapDef.new()
	corridor.id = "map.test.corridor"
	corridor.size = Vector2i(3, 3)
	corridor.spawn_cell = Vector2i(1, 0)
	corridor.blocked_cells = [Vector2i(0, 1), Vector2i(2, 1)]
	var exit: MapExit = MapExit.new()
	exit.cells = [Vector2i(1, 1)]
	exit.target_map_id = "map.start.01"
	exit.target_entry_cell = Vector2i(2, 5)
	corridor.exits = [exit]
	var authority: Authority = Authority.new({"map.test.corridor": corridor, "map.start.01": _maps["map.start.01"]}, 1)
	authority.add_character(P1, "char.0000000000000001", "map.test.corridor")
	var events: Array[GameEvent] = authority.submit(P1, MoveCommand.create(P1, Vector2i(1, 2)))
	assert_int(events.size()).is_equal(1)
	assert_bool((events[0] as MovedEvent).path.has(Vector2i(1, 1))).is_true()
	assert_str(authority.get_character(P1).map_id).is_equal("map.test.corridor")


func test_after_changing_map_moves_use_the_new_map() -> void:
	_move(P1, P1, Vector2i(11, 5))
	assert_str(_reason(_move(P1, P1, Vector2i(4, 3)))).is_equal("no_path")
	var events: Array[GameEvent] = _move(P1, P1, Vector2i(3, 5))
	assert_str((events[0] as MovedEvent).map_id).is_equal("map.start.02")


func test_two_characters_are_independent() -> void:
	_authority.add_character("player:2", "char.0000000000000002", "map.start.02")
	_move(P1, P1, Vector2i(2, 8))
	assert_vector(_authority.get_character("player:2").cell).is_equal(Vector2i(2, 5))
	assert_str(_authority.get_character("player:2").map_id).is_equal("map.start.02")


func test_same_seed_gives_same_random_sequence() -> void:
	var other: Authority = Authority.new({}, 1234)
	assert_int(other.rng.randi()).is_equal(_authority.rng.randi())


func test_generated_character_ids_have_the_agreed_format_and_differ() -> void:
	var a: String = CharacterState.generate_character_id()
	var b: String = CharacterState.generate_character_id()
	assert_bool(RegEx.create_from_string("^char\\.[0-9a-f]{16}$").search(a) != null).is_true()
	assert_str(a).is_not_equal(b)


func _interact(player: String, cell: Vector2i) -> Array[GameEvent]:
	return _authority.submit(player, InteractCommand.create(player, cell))


func _sign_on(cell: Vector2i) -> MapProp:
	var prop: MapProp = MapProp.new()
	prop.id = "prop.test.sign"
	prop.cell = cell
	prop.text_key = "sign.test"
	return prop


func test_using_a_sign_from_afar_walks_beside_it_and_reads_it() -> void:
	var events: Array[GameEvent] = _interact(P1, Vector2i(3, 7))
	assert_int(events.size()).is_equal(2)
	var end: Vector2i = (events[0] as MovedEvent).path.back()
	assert_int(maxi(absi(end.x - 3), absi(end.y - 7))).is_equal(1)
	assert_bool((_maps["map.start.01"] as MapDef).is_blocked(end)).is_false()
	assert_vector(_authority.get_character(P1).cell).is_equal(end)
	var read: InteractedEvent = events[1] as InteractedEvent
	assert_str(read.prop_id).is_equal("prop.start.welcome_sign")
	assert_str(read.text_key).is_equal("sign.start.welcome")


func test_using_a_sign_when_already_beside_it_does_not_move() -> void:
	_move(P1, P1, Vector2i(3, 6))
	var events: Array[GameEvent] = _interact(P1, Vector2i(3, 7))
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0] is InteractedEvent).is_true()
	assert_vector(_authority.get_character(P1).cell).is_equal(Vector2i(3, 6))


func test_using_an_empty_cell_or_for_another_seat_is_rejected() -> void:
	assert_str(_reason(_interact(P1, Vector2i(2, 2)))).is_equal("nothing_there")
	assert_str(_reason(_authority.submit(P1, InteractCommand.create("player:2", Vector2i(3, 7))))).is_equal("wrong_player")


func test_a_sign_nobody_can_get_next_to_is_rejected_without_moving() -> void:
	var closed: MapDef = MapDef.new()
	closed.id = "map.test.closed"
	closed.size = Vector2i(5, 5)
	closed.spawn_cell = Vector2i(0, 0)
	closed.blocked_cells = [Vector2i(2, 2), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]
	closed.props = [_sign_on(Vector2i(2, 2))]
	var authority: Authority = Authority.new({"map.test.closed": closed}, 1)
	authority.add_character(P1, "char.0000000000000001", "map.test.closed")
	var events: Array[GameEvent] = authority.submit(P1, InteractCommand.create(P1, Vector2i(2, 2)))
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("no_path")
	assert_vector(authority.get_character(P1).cell).is_equal(Vector2i(0, 0))


func test_the_cell_beside_a_sign_is_never_an_exit_cell() -> void:
	var map: MapDef = MapDef.new()
	map.id = "map.test.exitbeside"
	map.size = Vector2i(4, 4)
	map.spawn_cell = Vector2i(0, 0)
	map.blocked_cells = [Vector2i(2, 1)]
	var exit: MapExit = MapExit.new()
	exit.cells = [Vector2i(1, 1)]
	exit.target_map_id = "map.start.01"
	exit.target_entry_cell = Vector2i(2, 5)
	map.exits = [exit]
	map.props = [_sign_on(Vector2i(2, 1))]
	var authority: Authority = Authority.new({"map.test.exitbeside": map, "map.start.01": _maps["map.start.01"]}, 1)
	authority.add_character(P1, "char.0000000000000001", "map.test.exitbeside")
	var events: Array[GameEvent] = authority.submit(P1, InteractCommand.create(P1, Vector2i(2, 1)))
	assert_int(events.size()).is_equal(2)
	assert_bool(map.find_exit_at((events[0] as MovedEvent).path.back()) == null).is_true()
	assert_str(authority.get_character(P1).map_id).is_equal("map.test.exitbeside")


## A 5x5 map with a sign at (2,2) on level 0, surrounded by a ring of cells on `ring_level`,
## reached from the start (0,0) by a climbing cell at (0,1).
func _sign_with_raised_ring(ring_level: int, kind: String) -> Authority:
	var map: MapDef = MapDef.new()
	map.id = "map.test.ring"
	map.size = Vector2i(5, 5)
	map.spawn_cell = Vector2i(0, 0)
	map.blocked_cells = [Vector2i(2, 2)]
	for x: int in range(1, 4):
		for y: int in range(1, 4):
			if Vector2i(x, y) != Vector2i(2, 2):
				map.heights[Vector2i(x, y)] = ring_level
	map.cell_kinds = {Vector2i(0, 1): kind}
	map.props = [_sign_on(Vector2i(2, 2))]
	var authority: Authority = Authority.new({"map.test.ring": map}, 1)
	authority.add_character(P1, "char.0000000000000001", "map.test.ring")
	return authority


func test_a_sign_cannot_be_used_from_two_levels_above() -> void:
	var authority: Authority = _sign_with_raised_ring(2, "ladder")
	var events: Array[GameEvent] = authority.submit(P1, InteractCommand.create(P1, Vector2i(2, 2)))
	assert_str((events[0] as CommandRejectedEvent).reason).is_equal("no_path")


func test_a_sign_can_be_used_from_one_level_above() -> void:
	var authority: Authority = _sign_with_raised_ring(1, "stairs")
	var events: Array[GameEvent] = authority.submit(P1, InteractCommand.create(P1, Vector2i(2, 2)))
	assert_bool(events.back() is InteractedEvent).is_true()
