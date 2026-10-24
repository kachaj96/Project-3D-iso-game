extends SceneTree
## Dev tool: starts the exploration scene, taps a cell, waits until the character stops (or
## a text box opens) and saves a screenshot. Needs a display (do NOT use --headless).
##
## Run: godot --path . --script res://tools/render_after_tap.gd -- out.png en 3,7
##   args: output file, language (en or pl), cell to tap as x,y

const MAX_FRAMES: int = 900
const SETTLE_FRAMES: int = 12

var _world: World
var _output: String = ""
var _cell: Vector2i = Vector2i.ZERO
var _frames: int = 0
var _settled: int = -1


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: -- <out.png> <en|pl> <x,y>")
		quit(1)
		return
	_output = args[0]
	TranslationServer.set_locale(args[1])
	var parts: PackedStringArray = args[2].split(",")
	_cell = Vector2i(int(parts[0]), int(parts[1]))
	_world = (load("res://scenes/world/world.tscn") as PackedScene).instantiate()
	root.add_child(_world)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		_world.tap_at(GridMath.new().cell_to_pixel(_cell))
	if _frames > 5 and _settled < 0 and (_world.popup().is_open() or _frames >= MAX_FRAMES):
		_settled = 0
	if _settled >= 0:
		_settled += 1
		if _settled >= SETTLE_FRAMES:
			var error: Error = root.get_texture().get_image().save_png(_output)
			print("Screenshot: %s (%s) popup open: %s" % [_output, error_string(error), _world.popup().is_open()])
			quit(0 if error == OK else 1)
			return true
	return false
