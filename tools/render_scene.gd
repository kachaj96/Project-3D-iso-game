extends SceneTree
## Dev tool: opens a scene in a real window, saves a screenshot and quits.
## Needs a display (do NOT use --headless).
##
## Run: godot --path . --script res://tools/render_scene.gd -- res://scenes/world/map_start_01.tscn out.png
## Optional third argument: camera zoom (default 0.8). Optional fourth/fifth: camera x y.

const FRAMES_TO_WAIT: int = 8

var _frames: int = 0
var _output: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <scene.tscn> <output.png> [zoom] [cam_x cam_y]")
		quit(1)
		return
	_output = args[1]
	var scene: PackedScene = load(args[0])
	root.add_child(scene.instantiate())
	var camera: Camera2D = Camera2D.new()
	var zoom: float = float(args[2]) if args.size() > 2 else 0.6
	camera.zoom = Vector2(zoom, zoom)
	# Centre of a 12x12 map by default: cell (5.5, 5.5) of a 128x64 diamond grid is at pixel (64, 384).
	camera.position = Vector2(float(args[3]), float(args[4])) if args.size() > 4 else Vector2(64, 384)
	root.add_child(camera)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < FRAMES_TO_WAIT:
		return false
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(_output)
	print("Screenshot: %s (%s)" % [_output, error_string(error)])
	quit(0 if error == OK else 1)
	return true
