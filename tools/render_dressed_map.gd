extends SceneTree
## Dev tool: checks the drawing order of a dressed map. Opens the scene the way the world scene
## does (objects sorted with the hero), puts the hero on each given cell in turn and saves one
## screenshot per cell. Needs a display (do NOT use --headless).
##
##   godot --path . --script res://tools/render_dressed_map.gd -- <scene.tscn> <out prefix> <row,col> [<row,col> ...]
##
## A cell is "row,column" of the map file. The pictures must be imported (godot --headless --import).

const FRAMES_TO_WAIT: int = 6

var _cells: Array[Vector2i] = []
var _prefix: String = ""
var _player: PlayerActor
var _frames: int = 0
var _shot: int = 0
var _grid: GridMath = GridMath.new()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: -- <scene.tscn> <out prefix> <row,col> [<row,col> ...]")
		quit(1)
		return
	_prefix = args[1]
	for index: int in range(2, args.size()):
		var parts: PackedStringArray = args[index].split(",")
		_cells.append(MapLayout.cell_from_row_col(int(parts[0]), int(parts[1])))
	var map_root: Node2D = (load(args[0]) as PackedScene).instantiate()
	root.add_child(map_root)
	# The same rules as World._show_map.
	map_root.y_sort_enabled = true
	var ground: Node2D = map_root.get_node_or_null("Ground")
	if ground != null:
		ground.z_index = -1
	var objects: TileMapLayer = map_root.get_node_or_null("Objects")
	if objects != null:
		objects.y_sort_enabled = true
		objects.y_sort_origin = World.BLOCK_HEIGHT
	_player = preload("res://scenes/world/player_actor.tscn").instantiate()
	map_root.add_child(_player)
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(640.0, 336.0)
	root.add_child(camera)
	_place()


func _place() -> void:
	_player.place_at(_grid.cell_to_pixel(_cells[_shot]))
	_frames = 0


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < FRAMES_TO_WAIT:
		return false
	var path: String = "%s_%02d.png" % [_prefix, _shot + 1]
	var error: Error = root.get_texture().get_image().save_png(path)
	print("Screenshot %s (%s)" % [path, error_string(error)])
	_shot += 1
	if _shot >= _cells.size():
		quit(0 if error == OK else 1)
		return true
	_place()
	return false
