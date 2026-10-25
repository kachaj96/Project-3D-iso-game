class_name LocalSessionTest
extends GdUnitTestSuite

var _session: LocalSession
var _received: Array[GameEvent]


func before_test() -> void:
	var map: MapDef = load("res://tests/fixtures/maps/start_01.tres")
	var maps: Dictionary = {map.id: map, "map.start.02": load("res://tests/fixtures/maps/start_02.tres")}
	_session = LocalSession.new(Authority.new(maps, 1), "player:1")
	_received = []
	_session.events_emitted.connect(func(events: Array[GameEvent]) -> void: _received.append_array(events))


func test_start_announces_the_local_character() -> void:
	_session.start("char.0000000000000001", "map.start.01")
	assert_int(_received.size()).is_equal(1)
	assert_bool(_received[0] is CharacterSpawnedEvent).is_true()
	assert_str(_received[0].player_id).is_equal("player:1")


func test_send_delivers_the_results_as_events() -> void:
	_session.start("char.0000000000000001", "map.start.01")
	_session.send(MoveCommand.create("player:1", Vector2i(3, 5)))
	assert_bool(_received[1] is MovedEvent).is_true()


func test_a_command_written_for_another_seat_is_refused() -> void:
	_session.start("char.0000000000000001", "map.start.01")
	_session.send(MoveCommand.create("player:2", Vector2i(3, 5)))
	assert_str((_received[1] as CommandRejectedEvent).reason).is_equal("wrong_player")
