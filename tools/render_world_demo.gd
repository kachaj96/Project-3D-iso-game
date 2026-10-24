extends SceneTree
## Dev tool: renders the exploration scene with the character drawn on given cells, one
## screenshot per cell. Used to check drawing order (character behind / in front of obstacles).
## Needs a display (do NOT use --headless).
##
## Run: godot --path . --script res://tools/render_world_demo.gd -- out_prefix zoom cam_x cam_y 5,3 5,7
## Writes out_prefix_1.png, out_prefix_2.png, ...

const FRAMES_PER_SHOT: int = 6

var _world: World
var _camera: Camera2D
var _prefix: String = ""
var _cells: Array[Vector2i] = []
var _index: int = 0
var _frames: int = 0
var _placed: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 5:
		push_error("usage: -- <out_prefix> <zoom> <cam_x> <cam_y> <cx,cy> [<cx,cy> ...]")
		quit(1)
		return
	_prefix = args[0]
	for i: int in range(4, args.size()):
		var parts: PackedStringArray = args[i].split(",")
		_cells.append(Vector2i(int(parts[0]), int(parts[1])))
	_world = (load("res://scenes/world/world.tscn") as PackedScene).instantiate()
	root.add_child(_world)
	_camera = _world.get_node("Camera")
	_camera.zoom = Vector2(float(args[1]), float(args[1]))
	_camera.position = Vector2(float(args[2]), float(args[3]))


func _process(_delta: float) -> bool:
	if _index >= _cells.size():
		quit(0)
		return true
	if not _placed:
		_world.place_player_visual_at(_cells[_index])
		_placed = true
		_frames = 0
		return false
	_frames += 1
	if _frames < FRAMES_PER_SHOT:
		return false
	var path: String = "%s_%d.png" % [_prefix, _index + 1]
	var error: Error = root.get_texture().get_image().save_png(path)
	print("Screenshot: %s (%s) player on %s" % [path, error_string(error), _cells[_index]])
	_index += 1
	_placed = false
	return false
