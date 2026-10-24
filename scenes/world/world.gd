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
var _maps: Dictionary = {}
var _authority: Authority
var _map_root: Node2D
var _ground: TileMapLayer
var _player: PlayerActor
var _marker: TapMarker
var _current_map_id: String = ""
var _busy: bool = false

@onready var _camera: CameraRig = $Camera
@onready var _gestures: TouchGestures = $Gestures


func _ready() -> void:
	for map_id: String in MAP_FILES:
		_maps[map_id] = load(MAP_FILES[map_id]["def"])
	var problems: Array[String] = MapDef.validate_set(_maps)
	if not problems.is_empty():
		# An assert would be removed from exported builds, so report the error ourselves.
		push_error("Map data is invalid, exploration will not start: " + "; ".join(problems))
		return
	_authority = Authority.new(_maps, RNG_SEED)
	var character: CharacterState = _authority.add_character(PLAYER_ID, START_MAP_ID)

	_gestures.tapped.connect(_on_screen_tapped)
	_gestures.pinched.connect(_camera.zoom_by)

	_player = PLAYER_SCENE.instantiate()
	_player.speed = walk_speed
	_marker = MARKER_SCENE.instantiate()
	_camera.target = _player
	_show_map(character.map_id, character.cell)


## A tap at a world (not screen) position. Returns the events the Authority produced.
## While the character is walking, taps are ignored.
func tap_at(world_position: Vector2) -> Array[GameEvent]:
	if _authority == null or _busy:
		return []
	var cell: Vector2i = _grid.pixel_to_cell(_ground.to_local(world_position))
	var events: Array[GameEvent] = _authority.submit(MoveCommand.create(PLAYER_ID, cell))
	_play(events, cell)
	return events


func current_map_id() -> String:
	return _current_map_id


func player_position() -> Vector2:
	return _player.position


func camera() -> CameraRig:
	return _camera


## Presentation only: puts the character picture on a cell without telling the Authority.
## For screenshots and tests of drawing order.
func place_player_visual_at(cell: Vector2i) -> void:
	_player.place_at(_grid.cell_to_pixel(cell))
	_camera.snap_to_target()


func _on_screen_tapped(screen_position: Vector2) -> void:
	var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_position
	tap_at(world_position)


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
	_camera.set_map_bounds(_grid.map_pixel_bounds((_maps[map_id] as MapDef).size))
	_camera.snap_to_target()
	_current_map_id = map_id
	map_shown.emit(map_id)
