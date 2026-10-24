class_name Authority
extends RefCounted
## The only place where game state changes. Takes a command, checks the rules, changes
## the state and returns the list of events that happened. In single player it runs
## locally. In co-op the host runs it and clients send commands to it.

var world: WorldState = WorldState.new()
## The one random number generator for all gameplay randomness.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _maps: Dictionary
var _characters: Dictionary = {}
var _pathfinders: Dictionary = {}


## maps: Dictionary of map id -> MapDef.
func _init(maps: Dictionary, rng_seed: int) -> void:
	_maps = maps
	rng.seed = rng_seed


## Puts a new character on the spawn cell of a map. Returns null if the map is unknown
## or the player already has a character.
func add_character(player_id: String, map_id: String) -> CharacterState:
	if not _maps.has(map_id) or _characters.has(player_id):
		return null
	var character: CharacterState = CharacterState.new()
	character.player_id = player_id
	character.map_id = map_id
	character.cell = (_maps[map_id] as MapDef).spawn_cell
	_characters[player_id] = character
	return character


func get_character(player_id: String) -> CharacterState:
	return _characters.get(player_id)


func submit(command: GameCommand) -> Array[GameEvent]:
	if command is MoveCommand:
		return _handle_move(command as MoveCommand)
	return [CommandRejectedEvent.create(command.player_id, "unknown_command")]


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


func _pathfinder_for(map_id: String) -> Pathfinder:
	if not _pathfinders.has(map_id):
		_pathfinders[map_id] = Pathfinder.new(_maps[map_id])
	return _pathfinders[map_id]
