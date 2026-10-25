extends SceneTree
## Dev tool: puts a reference character picture next to our sprites at the same on-screen
## height, as they would look on a phone, once normally and once with the "daylight" glare.
## The reference is only read from where it lies and is never copied into the project.
##
## Run: godot --headless --path . --script res://tools/art/compare_with_reference.gd -- <out.png> <reference.png> <left|right|full> <our1.png> [our2.png ...]
##   left, right  use that half of the reference picture (class pictures hold two figures)
## Optional environment values: HEIGHT (default 120, character height in project pixels),
## PHONE (default 1.5, physical pixels per project pixel on a typical phone).

const GROUND: Color = Color(0.45, 0.50, 0.40, 1.0)
const DAYLIGHT_WHITE: float = 0.38
const MARGIN: int = 24


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("usage: -- <out.png> <reference.png> <left|right|full> <ours.png> ...")
		quit(1)
		return
	var height: int = int(OS.get_environment("HEIGHT")) if OS.get_environment("HEIGHT") != "" else 120
	var phone: float = float(OS.get_environment("PHONE")) if OS.get_environment("PHONE") != "" else 1.5

	var reference: Image = Image.load_from_file(args[1])
	reference.convert(Image.FORMAT_RGBA8)
	if args[2] == "left":
		reference = reference.get_region(Rect2i(0, 0, reference.get_width() / 2, reference.get_height()))
	elif args[2] == "right":
		reference = reference.get_region(Rect2i(reference.get_width() / 2, 0, reference.get_width() / 2, reference.get_height()))
	var figures: Array[Image] = [_fit(reference, height)]
	for i: int in range(3, args.size()):
		var ours: Image = Image.load_from_file(args[i])
		ours.convert(Image.FORMAT_RGBA8)
		figures.append(_fit(ours, height))

	var width: int = MARGIN
	for figure: Image in figures:
		width += figure.get_width() + MARGIN
	var canvas_height: int = height + 2 * MARGIN
	var normal: Image = Image.create_empty(width, canvas_height, false, Image.FORMAT_RGBA8)
	normal.fill(GROUND)
	var x: int = MARGIN
	for figure: Image in figures:
		normal.blend_rect(figure, Rect2i(Vector2i.ZERO, figure.get_size()), Vector2i(x, MARGIN))
		x += figure.get_width() + MARGIN
	var glare: Image = normal.duplicate()
	var white: Image = Image.create_empty(width, canvas_height, false, Image.FORMAT_RGBA8)
	white.fill(Color(1, 1, 1, DAYLIGHT_WHITE))
	glare.blend_rect(white, Rect2i(0, 0, width, canvas_height), Vector2i.ZERO)

	var sheet: Image = Image.create_empty(width, canvas_height * 2, false, Image.FORMAT_RGBA8)
	sheet.blit_rect(normal, Rect2i(0, 0, width, canvas_height), Vector2i.ZERO)
	sheet.blit_rect(glare, Rect2i(0, 0, width, canvas_height), Vector2i(0, canvas_height))
	sheet.resize(roundi(width * phone), roundi(canvas_height * 2 * phone), Image.INTERPOLATE_BILINEAR)
	var error: Error = sheet.save_png(args[0])
	print("Comparison written: %s (%s) %s" % [args[0], sheet.get_size(), error_string(error)])
	quit(0 if error == OK else 1)


## Cuts away the empty border and scales the figure to a fixed height.
func _fit(image: Image, height: int) -> Image:
	var used: Rect2i = image.get_used_rect()
	var figure: Image = image.get_region(used)
	var width: int = maxi(1, roundi(figure.get_width() * (height / float(figure.get_height()))))
	figure.resize(width, height, Image.INTERPOLATE_LANCZOS)
	return figure
