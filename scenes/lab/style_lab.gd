class_name StyleLab
extends Node2D
## Developer scene for judging art: a map with a character, plus a switch that imitates
## a phone screen in daylight (blacks lifted, contrast flattened). Every asset in M2 is
## checked here before it goes into the game. Not shown to players.

const MAP_SCENE: PackedScene = preload("res://scenes/world/map_start_01.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/world/player_actor.tscn")
## How much white is laid over the picture. Sunlight on glass is roughly this much.
const DAYLIGHT_WHITE: float = 0.38
const CENTRE_CELL: Vector2i = Vector2i(5, 5)

var _grid: GridMath = GridMath.new()

@onready var _glare: ColorRect = $Interface/Glare
@onready var _daylight_button: Button = $Interface/DaylightButton
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	var map: Node2D = MAP_SCENE.instantiate()
	add_child(map)
	var player: PlayerActor = PLAYER_SCENE.instantiate()
	map.add_child(player)
	map.y_sort_enabled = true
	(map.get_node("Ground") as TileMapLayer).z_index = -1
	var objects: TileMapLayer = map.get_node("Objects")
	objects.y_sort_enabled = true
	objects.y_sort_origin = World.BLOCK_HEIGHT
	player.place_at(_grid.cell_to_pixel(Vector2i(4, 5)))
	_camera.position = _grid.cell_to_pixel(CENTRE_CELL)
	_glare.color = Color(1, 1, 1, DAYLIGHT_WHITE)
	_glare.visible = false
	_daylight_button.toggled.connect(set_daylight)


func set_daylight(enabled: bool) -> void:
	_glare.visible = enabled
	_daylight_button.text = "Daylight: on" if enabled else "Daylight: off"
	if _daylight_button.button_pressed != enabled:
		_daylight_button.button_pressed = enabled


func is_daylight_on() -> bool:
	return _glare.visible
