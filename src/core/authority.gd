class_name Authority
extends RefCounted
## The only place where game state changes. Takes a command, checks the rules, changes
## the state and returns the list of events that happened. In single player it runs
## locally. In co-op the host runs it and clients send commands to it.

var world: WorldState = WorldState.new()
## The one random number generator for all gameplay randomness.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _maps: Dictionary
## player_id -> CharacterState
var _characters: Dictionary = {}
var _pathfinders: Dictionary = {}


## maps: Dictionary of map id -> MapDef.
func _init(maps: Dictionary, rng_seed: int) -> void:
	_maps = maps
	rng.seed = rng_seed


## Seats a character at player_id and puts it on the spawn cell of map_id.
## Returns a CharacterSpawnedEvent, or a rejection if the seat is taken, the character is
## already in the game, or the map is unknown.
func add_character(player_id: String, character_id: String, map_id: String) -> Array[GameEvent]:
	if player_id.is_empty() or character_id.is_empty():
		return [CommandRejectedEvent.create(player_id, "invalid_character")]
	if _characters.has(player_id):
		return [CommandRejectedEvent.create(player_id, "seat_taken")]
	for other: CharacterState in _characters.values():
		if other.character_id == character_id:
			return [CommandRejectedEvent.create(player_id, "character_already_present")]
	if not _maps.has(map_id):
		return [CommandRejectedEvent.create(player_id, "unknown_map")]

	var character: CharacterState = CharacterState.new()
	character.character_id = character_id
	character.player_id = player_id
	character.map_id = map_id
	character.cell = (_maps[map_id] as MapDef).spawn_cell
	_characters[player_id] = character

	var spawned: CharacterSpawnedEvent = CharacterSpawnedEvent.new()
	spawned.player_id = player_id
	spawned.character_id = character_id
	spawned.map_id = map_id
	spawned.cell = character.cell
	return [spawned]


func get_character(player_id: String) -> CharacterState:
	return _characters.get(player_id)


## sender_id is who actually sent the command, as known by whoever delivered it (the local
## session, or later the network layer). It is never read from the command itself, so a
## player cannot act for someone else by writing another id into a command.
func submit(sender_id: String, command: GameCommand) -> Array[GameEvent]:
	if command == null:
		return [CommandRejectedEvent.create(sender_id, "invalid_command")]
	if command.player_id != sender_id:
		return [CommandRejectedEvent.create(sender_id, "wrong_player")]
	if command is MoveCommand:
		return _handle_move(command as MoveCommand)
	return [CommandRejectedEvent.create(sender_id, "unknown_command")]


func _handle_move(command: MoveCommand) -> Array[GameEvent]:
	var character: CharacterState = get_character(command.player_id)
	if character == null:
		return [CommandRejectedEvent.create(command.player_id, "unknown_player")]
	var path: Array[Vector2i] = _pathfinder_for(character.map_id).find_path(character.cell, command.target_cell)
	if path.is_empty():
		return [CommandRejectedEvent.create(command.player_id, "no_path")]
	if path.size() < 2:
		return [CommandRejectedEvent.create(command.player_id, "already_there")]

	var events: Array[GameEvent] = []
	var moved: MovedEvent = MovedEvent.new()
	moved.player_id = command.player_id
	moved.map_id = character.map_id
	moved.path = path
	character.cell = path[path.size() - 1]
	events.append(moved)

	var exit: MapExit = (_maps[character.map_id] as MapDef).find_exit_at(character.cell)
	if exit != null:
		var changed: MapChangedEvent = MapChangedEvent.new()
		changed.player_id = command.player_id
		changed.from_map_id = character.map_id
		changed.map_id = exit.target_map_id
		changed.cell = exit.target_entry_cell
		character.map_id = exit.target_map_id
		character.cell = exit.target_entry_cell
		events.append(changed)
	return events


## Exploration walks in eight directions (decision D-008). Combat will build its own
## pathfinder with the movement it needs.
func _pathfinder_for(map_id: String) -> Pathfinder:
	if not _pathfinders.has(map_id):
		_pathfinders[map_id] = Pathfinder.new(_maps[map_id], Pathfinder.Movement.EIGHT_WAY)
	return _pathfinders[map_id]
