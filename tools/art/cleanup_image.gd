extends SceneTree
## Dev tool: prepares ONE asset image made by an AI tool for the game.
##   1. removes the plain background (flood fill from the four corners)
##   2. cuts away the empty border
##   3. scales it so its width matches a target (for ground tiles: 128 px) and keeps the shape
##   4. softens the cut edge a little so no light halo is left
##
## It never repairs perspective or style. An image that breaks the style rules in
## docs/ART_PIPELINE.md is regenerated, not fixed here.
##
## Run: godot --headless --path . --script res://tools/art/cleanup_image.gd -- <in.png> <out.png> [width_px] [tolerance]
##   width_px   target width, default 128
##   tolerance  how far a pixel may differ from the corner color and still count as background, 0-1, default 0.12

const DEFAULT_WIDTH: int = 128
const DEFAULT_TOLERANCE: float = 0.12


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <in.png> <out.png> [width_px] [tolerance]")
		quit(1)
		return
	var width: int = int(args[2]) if args.size() > 2 else DEFAULT_WIDTH
	var tolerance: float = float(args[3]) if args.size() > 3 else DEFAULT_TOLERANCE
	var image: Image = Image.load_from_file(args[0])
	if image == null or image.is_empty():
		push_error("cannot read " + args[0])
		quit(1)
		return
	var result: Image = process(image, width, tolerance)
	var error: Error = result.save_png(args[1])
	print("Written %s (%s) %s" % [args[1], result.get_size(), error_string(error)])
	quit(0 if error == OK else 1)


static func process(source: Image, width: int, tolerance: float) -> Image:
	var image: Image = source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	_remove_background(image, tolerance)
	var used: Rect2i = image.get_used_rect()
	if used.size.x == 0 or used.size.y == 0:
		return image
	image = image.get_region(used)
	var height: int = maxi(1, roundi(image.get_height() * (width / float(image.get_width()))))
	image.resize(width, height, Image.INTERPOLATE_LANCZOS)
	return image


## Flood fill from every corner. Pixels close to the color of the corner they start from
## become transparent. Only background connected to a corner is removed, so a white detail
## inside the picture stays.
static func _remove_background(image: Image, tolerance: float) -> void:
	var size: Vector2i = image.get_size()
	var corners: Array[Vector2i] = [Vector2i(0, 0), Vector2i(size.x - 1, 0), Vector2i(0, size.y - 1), Vector2i(size.x - 1, size.y - 1)]
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(size.x * size.y)
	for corner: Vector2i in corners:
		var reference: Color = image.get_pixelv(corner)
		if reference.a < 0.05:
			continue
		var stack: Array[Vector2i] = [corner]
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			if p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y:
				continue
			var index: int = p.y * size.x + p.x
			if visited[index] == 1:
				continue
			var color: Color = image.get_pixelv(p)
			if _distance(color, reference) > tolerance:
				continue
			visited[index] = 1
			image.set_pixelv(p, Color(color.r, color.g, color.b, 0.0))
			stack.append(Vector2i(p.x + 1, p.y))
			stack.append(Vector2i(p.x - 1, p.y))
			stack.append(Vector2i(p.x, p.y + 1))
			stack.append(Vector2i(p.x, p.y - 1))


static func _distance(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b))
