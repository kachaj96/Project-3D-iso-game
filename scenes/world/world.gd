class_name World
extends Node2D
## Exploration scene. Turns taps into MoveCommands, sends them to the Authority and plays
## the returned events (walking, map change). It never changes game state itself.

signal walk_finished
signal map_shown(map_id: String)

const PLAYER_ID: String = "player:1"
const START_MAP_ID: String = "map.start.01"
const RNG_SEED: int = 20261024
## Height of one block in pixels. Obstacles are drawn one block higher than the ground.
const BLOCK_HEIGHT: int = 64
const PLAYER_SCENE: PackedScene = preload("res://scenes/world/player_actor.tscn")
const MARKER_SCENE: PackedScene = preload("res://scenes/world/tap_marker.tscn")

## Map id -> where its data and painted scene live.
const MAP_FILES: Dictionary = {
	"map.start.01": {"def": "res://content/maps/start_01.tres", "scene": "res://scenes/world/map_start_01.tscn"},
	"map.start.02": {"def": "res://content/maps/start_02.tres", "scene": "res://scenes/world/map_start_02.tscn"},
}

@export var walk_speed: float = 360.0:
	set(value):
		walk_speed = value
		if _player != null:
			_player.speed = value

var _grid: GridMath = GridMath.new()
var _authority: Authority
var _map_root: Node2D
var _ground: TileMapLayer
var _player: PlayerActor
var _marker: TapMarker
var _current_map_id: String = ""
var _busy: bool = false


func _ready() -> void:
	var maps: Dictionary = {}
	for map_id: String in MAP_FILES:
		maps[map_id] = load(MAP_FILES[map_id]["def"])
	assert(MapDef.validate_set(maps).is_empty(), "map data is invalid")
	_authority = Authority.new(maps, RNG_SEED)
	var character: CharacterState = _authority.add_character(PLAYER_ID, START_MAP_ID)

	_player = PLAYER_SCENE.instantiate()
	_player.speed = walk_speed
	_marker = MARKER_SCENE.instantiate()
	_show_map(character.map_id, character.cell)


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		tap_at(get_global_mouse_position())


## A tap at a world (not screen) position. Returns the events the Authority produced.
## While the character is walking, taps are ignored.
func tap_at(world_position: Vector2) -> Array[GameEvent]:
	if _busy:
		return []
	var cell: Vector2i = _grid.pixel_to_cell(_ground.to_local(world_position))
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create(PLAYER_ID, cell))
	_play(events, cell)
	return events


func current_map_id() -> String:
	return _current_map_id


func player_position() -> Vector2:
	return _player.position


## Presentation only: puts the character picture on a cell without telling the Authority.
## For screenshots and tests of drawing order.
func place_player_visual_at(cell: Vector2i) -> void:
	_player.place_at(_grid.cell_to_pixel(cell))


func _play(events: Array[GameEvent], tapped_cell: Vector2i) -> void:
	var moved: MovedEvent = null
	var changed: MapChangedEvent = null
	for event: GameEvent in events:
		if event is MovedEvent:
			moved = event as MovedEvent
		elif event is MapChangedEvent:
			changed = event as MapChangedEvent
	_marker.show_at(_grid.cell_to_pixel(tapped_cell), moved != null)
	if moved == null:
		return

	_busy = true
	var points: Array[Vector2] = []
	for cell: Vector2i in moved.path:
		points.append(_grid.cell_to_pixel(cell))
	_player.walk_along(points)
	await _player.walk_finished
	if changed != null:
		_show_map(changed.map_id, changed.cell)
	_busy = false
	walk_finished.emit()


func _show_map(map_id: String, cell: Vector2i) -> void:
	for node: Node in [_player, _marker]:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
	if _map_root != null:
		_map_root.queue_free()

	var scene: PackedScene = load(MAP_FILES[map_id]["scene"])
	_map_root = scene.instantiate()
	add_child(_map_root)
	_ground = _map_root.get_node("Ground")
	var objects: TileMapLayer = _map_root.get_node("Objects")

	# Drawing order: the ground is always behind. Obstacles and the character are sorted
	# by their feet position. The obstacle layer is shifted up one block, so its sort
	# origin shifts back down by the same amount.
	_map_root.y_sort_enabled = true
	_ground.z_index = -1
	objects.y_sort_enabled = true
	objects.y_sort_origin = BLOCK_HEIGHT

	_map_root.add_child(_player)
	_map_root.add_child(_marker)
	_player.place_at(_grid.cell_to_pixel(cell))
	_current_map_id = map_id
	map_shown.emit(map_id)
