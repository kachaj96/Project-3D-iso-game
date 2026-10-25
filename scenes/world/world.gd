class_name World
extends Node2D
## Exploration scene. Turns taps into MoveCommands and sends them through the GameSession.
## Everything it shows comes from the events the session hands back (decision D-014):
## where the character appears, how it walks, when the map changes. It never reads or
## changes game state itself.

signal walk_finished
signal map_shown(map_id: String)

## In solo play this device is always seat 1. In co-op the host will assign seats.
const LOCAL_PLAYER_ID: String = "player:1"
## The map the game starts on and the catalog the maps come from (written by tools/maps/generate.gd).
const START_MAP_ID: String = "map.gluchobor.02_02"
const CATALOG_PATH: String = "res://content/maps/catalog.tres"
const RNG_SEED: int = 20261024
## Height of one block in pixels. Obstacles are drawn one block higher than the ground.
const BLOCK_HEIGHT: int = 64
const PLAYER_SCENE: PackedScene = preload("res://scenes/world/player_actor.tscn")
const MARKER_SCENE: PackedScene = preload("res://scenes/world/tap_marker.tscn")
const POPUP_SCENE: PackedScene = preload("res://scenes/ui/text_popup.tscn")


## Tests start the world on a small fixture world instead of the real one.
@export var catalog_path: String = CATALOG_PATH
@export var start_map_id: String = START_MAP_ID
@export var walk_speed: float = 360.0:
	set(value):
		walk_speed = value
		if _player != null:
			_player.speed = value

var _grid: GridMath = GridMath.new()
var _maps: Dictionary = {}
var _catalog: MapCatalog
var _session: GameSession
var _map_root: Node2D
var _ground: TileMapLayer
var _player: PlayerActor
var _marker: TapMarker
var _popup: TextPopup
var _current_map_id: String = ""
var _last_tapped_cell: Vector2i = Vector2i.ZERO
var _busy: bool = false

@onready var _camera: CameraRig = $Camera
@onready var _gestures: TouchGestures = $Gestures


func _ready() -> void:
	_catalog = load(catalog_path)
	_maps = _catalog.load_maps()
	var problems: Array[String] = MapDef.validate_set(_maps)
	if not problems.is_empty():
		# An assert would be removed from exported builds, so report the error ourselves.
		push_error("Map data is invalid, exploration will not start: " + "; ".join(problems))
		return

	_player = PLAYER_SCENE.instantiate()
	_player.speed = walk_speed
	_marker = MARKER_SCENE.instantiate()
	_popup = POPUP_SCENE.instantiate()
	add_child(_popup)
	_camera.target = _player.visual
	_gestures.tapped.connect(_on_screen_tapped)
	_gestures.pinched.connect(_camera.zoom_by)

	# Solo play: the Authority runs on this device. A co-op guest would get a network
	# session here instead, and nothing else in this scene would change.
	var local: LocalSession = LocalSession.new(Authority.new(_maps, RNG_SEED), LOCAL_PLAYER_ID)
	_session = local
	_session.events_emitted.connect(_on_events)
	# Until saves exist (M4) every start creates a new character.
	local.start(CharacterState.generate_character_id(), start_map_id)


## A tap at a world (not screen) position. A tap on an object (a sign) uses it, any other tap
## walks. While the character walks or a text box is open, taps are ignored.
func tap_at(world_position: Vector2) -> void:
	if _session == null or _ground == null or _busy or _popup.is_open():
		return
	_last_tapped_cell = _grid.pick_cell(_ground.to_local(world_position), _maps[_current_map_id])
	if (_maps[_current_map_id] as MapDef).find_prop_at(_last_tapped_cell) != null:
		_session.send(InteractCommand.create(_session.local_player_id, _last_tapped_cell))
	else:
		_session.send(MoveCommand.create(_session.local_player_id, _last_tapped_cell))


func session() -> GameSession:
	return _session


func current_map_id() -> String:
	return _current_map_id


func player_position() -> Vector2:
	return _player.position


func camera() -> CameraRig:
	return _camera


func popup() -> TextPopup:
	return _popup


## Presentation only: puts the character picture on a cell without telling the Authority.
## For screenshots and tests of drawing order.
func place_player_visual_at(cell: Vector2i) -> void:
	_player.place_at(_grid.cell_to_pixel(cell), _lift_of(cell))
	_camera.snap_to_target()


func _on_screen_tapped(screen_position: Vector2) -> void:
	var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_position
	tap_at(world_position)


## The single entry point for everything that happened. Plays events in order; a map change
## that follows a walk is shown when the walk ends.
func _on_events(events: Array[GameEvent]) -> void:
	var walked: bool = false
	for event: GameEvent in events:
		if event.player_id != _session.local_player_id:
			continue  # Other players' characters are shown from M3.5 on.
		if event is CharacterSpawnedEvent:
			var spawned: CharacterSpawnedEvent = event as CharacterSpawnedEvent
			_show_map(spawned.map_id, spawned.cell)
		elif event is MovedEvent:
			var moved: MovedEvent = event as MovedEvent
			_marker.show_at(_marker_position(_last_tapped_cell), true)
			_busy = true
			walked = true
			var points: Array[Vector2] = []
			var lifts: Array[float] = []
			for cell: Vector2i in moved.path:
				points.append(_grid.cell_to_pixel(cell))
				lifts.append(_lift_of(cell))
			_player.walk_along(points, lifts)
			await _player.walk_finished
		elif event is MapChangedEvent:
			var changed: MapChangedEvent = event as MapChangedEvent
			_show_map(changed.map_id, changed.cell)
		elif event is InteractedEvent:
			var interacted: InteractedEvent = event as InteractedEvent
			_marker.show_at(_marker_position(_last_tapped_cell), true)
			if interacted.kind == "sign" or interacted.kind == "inspect":
				_popup.show_key(interacted.text_key)
		elif event is CommandRejectedEvent:
			if _current_map_id.is_empty():
				push_error("Could not place the character: " + (event as CommandRejectedEvent).reason)
			else:
				_marker.show_at(_marker_position(_last_tapped_cell), false)
	if walked:
		_busy = false
		walk_finished.emit()


func _show_map(map_id: String, cell: Vector2i) -> void:
	for node: Node in [_player, _marker]:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
	if _map_root != null:
		_map_root.queue_free()

	var scene: PackedScene = load(_catalog.scenes[map_id])
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
	_current_map_id = map_id
	_player.place_at(_grid.cell_to_pixel(cell), _lift_of(cell))
	var shown: MapDef = _maps[map_id]
	_player.set_aura(MapTheme.darkness(shown.theme) != Color.WHITE)
	_camera.set_map_bounds(_grid.bounds_of(shown), 0.0 if shown.shape == MapDef.Shape.SCREEN else -1.0)
	_camera.snap_to_target()
	map_shown.emit(map_id)


## How many pixels a cell of the current map is drawn above the ground.
func _lift_of(cell: Vector2i) -> float:
	return _grid.level_lift((_maps[_current_map_id] as MapDef).height_at(cell))


## The marker sits on the surface of the tapped cell, so it is raised like the character.
func _marker_position(cell: Vector2i) -> Vector2:
	return _grid.cell_to_pixel(cell) - Vector2(0.0, _lift_of(cell))
