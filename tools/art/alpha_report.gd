extends SceneTree
## Reports whether a picture has a real alpha channel and how it is used. Changes nothing.
##
##   godot --headless --path . --script res://tools/art/alpha_report.gd -- <picture.png>
##
## Tells you: size and format, how many pixels are fully transparent, half transparent
## (edges), and opaque; how many pixels are the magenta key colour (#FF00FF, within a small
## tolerance); and whether the top left corner looks like a painted checkerboard (many
## alternating light and dark grey pixels) instead of real transparency.

const MAGENTA_TOLERANCE: float = 0.08


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: -- <picture.png>")
		quit(1)
		return
	var image: Image = Image.load_from_file(args[0])
	if image == null:
		printerr("Cannot read " + args[0])
		quit(1)
		return
	var had_alpha: bool = image.detect_alpha() != Image.ALPHA_NONE or image.get_format() == Image.FORMAT_RGBA8
	var original_format: String = str(image.get_format())
	image.convert(Image.FORMAT_RGBA8)
	var total: int = image.get_width() * image.get_height()
	var clear: int = 0
	var partial: int = 0
	var magenta: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var colour: Color = image.get_pixel(x, y)
			if colour.a < 0.01:
				clear += 1
			elif colour.a < 0.99:
				partial += 1
			elif colour.r > 1.0 - MAGENTA_TOLERANCE and colour.b > 1.0 - MAGENTA_TOLERANCE and colour.g < MAGENTA_TOLERANCE:
				magenta += 1
	print("File: %s" % args[0])
	print("Size: %d x %d, Godot format id %s, alpha channel present: %s" % [image.get_width(), image.get_height(), original_format, had_alpha])
	print("Fully transparent: %.1f%%   Half transparent (edges): %.1f%%   Magenta key colour: %.1f%%" % [100.0 * clear / total, 100.0 * partial / total, 100.0 * magenta / total])
	print("Checkerboard painted in the corner: %s" % ("LOOKS LIKE YES" if _looks_like_checkerboard(image) else "no"))
	if clear > 0:
		print("Verdict: real transparency, the background can be used as it is.")
	elif magenta > 0:
		print("Verdict: no transparency, but a magenta key background: use the key colour cleanup.")
	else:
		print("Verdict: opaque picture, no usable transparency and no key colour.")
	quit(0)


## A painted checkerboard has two grey tones alternating in small squares.
func _looks_like_checkerboard(image: Image) -> bool:
	var sample: int = mini(64, mini(image.get_width(), image.get_height()))
	var light: int = 0
	var dark: int = 0
	for y: int in sample:
		for x: int in sample:
			var colour: Color = image.get_pixel(x, y)
			var grey: bool = absf(colour.r - colour.g) < 0.03 and absf(colour.g - colour.b) < 0.03
			if grey and colour.a > 0.99:
				if colour.r > 0.85:
					light += 1
				elif colour.r > 0.5 and colour.r < 0.85:
					dark += 1
	return light > sample * sample / 4 and dark > sample * sample / 4
