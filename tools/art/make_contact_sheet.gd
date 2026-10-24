extends SceneTree
## Dev tool: puts every PNG of a folder side by side on one grey sheet, with a 128 x 64
## diamond drawn under each frame's anchor point, to check size, facing and grid fit.
##
## Run: godot --headless --path . --script res://tools/art/make_contact_sheet.gd -- <folder> <out.png> [columns] [anchor_y_fraction]
## Files are placed in this order when present: S SW W NW N NE E SE, then the rest by name.

const DIRECTION_ORDER: Array[String] = ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
const BACKGROUND: Color = Color(0.45, 0.50, 0.40, 1.0)
const DIAMOND: Color = Color(1.0, 1.0, 1.0, 0.55)


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <folder> <out.png> [columns] [anchor_y_fraction]")
		quit(1)
		return
	var folder: String = args[0]
	var columns: int = int(args[2]) if args.size() > 2 else 4
	var anchor: float = float(args[3]) if args.size() > 3 else 0.75
	var files: Array[String] = _sorted_files(folder)
	if files.is_empty():
		push_error("no PNG files in " + folder)
		quit(1)
		return
	var first: Image = Image.load_from_file(files[0])
	var cell: Vector2i = first.get_size()
	var rows: int = ceili(files.size() / float(columns))
	var sheet: Image = Image.create_empty(cell.x * columns, cell.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKGROUND)
	for i: int in files.size():
		var origin: Vector2i = Vector2i((i % columns) * cell.x, (i / columns) * cell.y)
		var centre: Vector2i = origin + Vector2i(cell.x / 2, roundi(cell.y * anchor))
		_draw_diamond(sheet, centre)
		var frame: Image = Image.load_from_file(files[i])
		frame.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(frame, Rect2i(Vector2i.ZERO, cell), origin)
	var error: Error = sheet.save_png(args[1])
	print("Sheet written: %s (%d frames, cell %s) %s" % [args[1], files.size(), cell, error_string(error)])
	quit(0 if error == OK else 1)


func _sorted_files(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension().to_lower() == "png":
			found.append(folder.path_join(file))
	found.sort_custom(func(a: String, b: String) -> bool: return _rank(a) < _rank(b))
	return found


func _rank(path: String) -> String:
	var parts: PackedStringArray = path.get_file().get_basename().split("_")
	var index: int = DIRECTION_ORDER.find(parts[1]) if parts.size() > 2 else -1
	return "%02d_%s" % [index if index >= 0 else 99, path]


## Outline of a 128 x 64 ground diamond centred on a point.
func _draw_diamond(image: Image, centre: Vector2i) -> void:
	for step: int in range(0, 65):
		var dy: int = 32 - step / 2
		for sign_x: int in [-1, 1]:
			for sign_y: int in [-1, 1]:
				var p: Vector2i = centre + Vector2i(sign_x * step, sign_y * dy)
				if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
					image.set_pixelv(p, DIAMOND)
