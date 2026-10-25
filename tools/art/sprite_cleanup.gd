class_name SpriteCleanup
extends RefCounted
## Clean-up steps for pictures made by the image AI (see docs/ART_PIPELINE.md). Pure image
## maths, no files. A picture with a real alpha channel still needs three things before the
## game can use it:
##   solidify       faint pixels become fully transparent and nearly opaque ones fully opaque
##                  (the AI leaves a haze around objects and makes objects slightly see-through)
##   bleed_colours  the colour of the pixels under the transparent and half transparent edge
##                  is replaced by the colour of the nearest solid pixel, so no coloured halo
##                  or red and yellow fringe shows when the game scales the picture
##   trim / split   cut the empty border, or cut a sheet into its separate items

const FAINT_ALPHA: float = 0.25
const SOLID_ALPHA: float = 0.9
const BLEED_PASSES: int = 8
## Sheets are analysed on a copy reduced by this factor.
const ANALYSIS_STEP: int = 6


## Faint pixels (alpha below FAINT_ALPHA) become fully transparent, nearly opaque ones
## (alpha from SOLID_ALPHA up) fully opaque. Works on the image itself.
static func solidify(image: Image) -> void:
	_to_rgba8(image)
	var data: PackedByteArray = image.get_data()
	var low: int = roundi(FAINT_ALPHA * 255.0)
	var high: int = roundi(SOLID_ALPHA * 255.0)
	for index: int in range(3, data.size(), 4):
		var alpha: int = data[index]
		if alpha < low:
			data[index] = 0
		elif alpha >= high:
			data[index] = 255
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)


## Replaces the colour of every pixel that is not solid (alpha below SOLID_ALPHA) by the colour
## of its nearest solid pixel, up to BLEED_PASSES pixels away. Alpha is not changed. Run it
## after solidify.
static func bleed_colours(image: Image) -> void:
	_to_rgba8(image)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var data: PackedByteArray = image.get_data()
	var solid_alpha: int = roundi(SOLID_ALPHA * 255.0)
	var known: PackedByteArray = PackedByteArray()
	known.resize(width * height)
	for index: int in width * height:
		known[index] = 1 if data[index * 4 + 3] >= solid_alpha else 0
	for pass_number: int in BLEED_PASSES:
		var learned: PackedInt32Array = PackedInt32Array()
		for y: int in height:
			for x: int in width:
				var index: int = y * width + x
				if known[index] == 1:
					continue
				var red: int = 0
				var green: int = 0
				var blue: int = 0
				var count: int = 0
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + offset.x
					var ny: int = y + offset.y
					if nx >= 0 and ny >= 0 and nx < width and ny < height and known[ny * width + nx] == 1:
						var other: int = (ny * width + nx) * 4
						red += data[other]
						green += data[other + 1]
						blue += data[other + 2]
						count += 1
				if count > 0:
					data[index * 4] = red / count
					data[index * 4 + 1] = green / count
					data[index * 4 + 2] = blue / count
					learned.append(index)
		if learned.is_empty():
			break
		for index: int in learned:
			known[index] = 1
	image.set_data(width, height, false, Image.FORMAT_RGBA8, data)


## The smallest rectangle that holds every pixel that is not fully transparent. Empty
## rectangle when the picture is empty.
static func content_rect(image: Image) -> Rect2i:
	_to_rgba8(image)
	var width: int = image.get_width()
	var data: PackedByteArray = image.get_data()
	var low: Vector2i = Vector2i(width, image.get_height())
	var high: Vector2i = Vector2i(-1, -1)
	for index: int in range(0, data.size() / 4):
		if data[index * 4 + 3] > 0:
			var x: int = index % width
			var y: int = index / width
			low = Vector2i(mini(low.x, x), mini(low.y, y))
			high = Vector2i(maxi(high.x, x), maxi(high.y, y))
	if high.x < 0:
		return Rect2i()
	return Rect2i(low, high - low + Vector2i.ONE)


## A copy without the empty border.
static func trimmed(image: Image) -> Image:
	var rect: Rect2i = content_rect(image)
	if rect.size == Vector2i.ZERO:
		return image.duplicate()
	return image.get_region(rect)


## The separate items of a sheet, each as the rectangle that holds it, in reading order
## (rows from the top, left to right within a row). Pieces closer than `merge` pixels count
## as one item, and pieces smaller than `min_size` are specks and are ignored.
static func split_items(sheet: Image, merge: int = 18, min_size: Vector2i = Vector2i(40, 30)) -> Array[Rect2i]:
	_to_rgba8(sheet)
	var step: int = ANALYSIS_STEP
	var width: int = sheet.get_width() / step
	var height: int = sheet.get_height() / step
	var data: PackedByteArray = sheet.get_data()
	var reach: int = maxi(merge / step, 1)
	var solid: PackedByteArray = PackedByteArray()
	solid.resize(width * height)
	for y: int in height:
		for x: int in width:
			if data[((y * step) * sheet.get_width() + x * step) * 4 + 3] > 76:
				solid[y * width + x] = 1
	var merged: PackedByteArray = solid.duplicate()
	for y: int in height:
		for x: int in width:
			if solid[y * width + x] == 1:
				for dy: int in range(-reach, reach + 1):
					for dx: int in range(-reach, reach + 1):
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and ny >= 0 and nx < width and ny < height:
							merged[ny * width + nx] = 1
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(width * height)
	var rects: Array[Rect2i] = []
	for y: int in height:
		for x: int in width:
			if merged[y * width + x] == 0 or seen[y * width + x] == 1:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * width + x] = 1
			var low: Vector2i = Vector2i(x, y)
			var high: Vector2i = Vector2i(x, y)
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				low = Vector2i(mini(low.x, point.x), mini(low.y, point.y))
				high = Vector2i(maxi(high.x, point.x), maxi(high.y, point.y))
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var next: Vector2i = point + offset
					if next.x >= 0 and next.y >= 0 and next.x < width and next.y < height and merged[next.y * width + next.x] == 1 and seen[next.y * width + next.x] == 0:
						seen[next.y * width + next.x] = 1
						stack.append(next)
			var rough: Rect2i = Rect2i(low * step, (high - low + Vector2i.ONE) * step).intersection(Rect2i(Vector2i.ZERO, sheet.get_size()))
			var tight: Rect2i = content_rect(sheet.get_region(rough))
			if tight.size.x >= min_size.x and tight.size.y >= min_size.y:
				rects.append(Rect2i(rough.position + tight.position, tight.size))
	var band: int = maxi(sheet.get_height() / 6, 1)
	rects.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		var row_a: int = (a.position.y + a.size.y / 2) / band
		var row_b: int = (b.position.y + b.size.y / 2) / band
		return row_a < row_b or (row_a == row_b and a.position.x < b.position.x))
	return rects


## A grayscale picture (white on black) becomes a one-colour picture whose opacity is the
## brightness. For mist and light shafts, which the AI paints on black.
static func luminance_to_alpha(image: Image, tint: Color) -> Image:
	_to_rgba8(image)
	var source: PackedByteArray = image.get_data()
	var data: PackedByteArray = PackedByteArray()
	data.resize(source.size())
	var red: int = roundi(tint.r * 255.0)
	var green: int = roundi(tint.g * 255.0)
	var blue: int = roundi(tint.b * 255.0)
	for index: int in range(0, source.size(), 4):
		data[index] = red
		data[index + 1] = green
		data[index + 2] = blue
		data[index + 3] = maxi(source[index], maxi(source[index + 1], source[index + 2]))
	return Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)


static func _to_rgba8(image: Image) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)


## A soft ground shadow for an object picture: the silhouette flattened to about a eighth of
## its height, slanted toward the lower right (the key light is at the top left), blurred. The
## result is dark with partial opacity, wider than the object so the slant has room, and hangs
## on the bottom centre like the object (so it scales and flips with it).
static func make_shadow(image: Image, strength: float = 0.45) -> Image:
	_to_rgba8(image)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var flat: int = maxi(int(height * 0.12), 6)
	var pad: int = int(width * 0.3)
	var slant: float = 0.3
	var source: PackedByteArray = image.get_data()
	var out_width: int = width + 2 * pad
	var data: PackedByteArray = PackedByteArray()
	data.resize(out_width * flat * 4)
	for y: int in flat:
		var shift: int = int((flat - y) * slant * (float(height) / flat) * 0.25)
		var source_row: int = mini(int(float(y) * height / flat), height - 1)
		for x: int in width:
			var alpha: int = source[(source_row * width + x) * 4 + 3]
			var target: int = pad + x + shift
			if alpha > 25 and target < out_width:
				var index: int = (y * out_width + target) * 4
				data[index] = 14
				data[index + 1] = 18
				data[index + 2] = 26
				data[index + 3] = roundi(255.0 * strength)
	var shadow: Image = Image.create_from_data(out_width, flat, false, Image.FORMAT_RGBA8, data)
	var small: Image = shadow.duplicate()
	small.resize(maxi(out_width / 10, 1), maxi(flat / 3, 1), Image.INTERPOLATE_BILINEAR)
	small.resize(out_width, flat, Image.INTERPOLATE_BILINEAR)
	return small


## The rectangle that holds everything brighter than `threshold` (0 to 1) in at least `min_pixels`
## pixels of its row and of its column. Used to find the lit floor of a room in a dark picture, so
## that single bright specks do not count. Looks at every `step`-th pixel.
static func bright_bounds(image: Image, threshold: float = 0.07, min_pixels: int = 6, step: int = 3) -> Rect2i:
	_to_rgba8(image)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var data: PackedByteArray = image.get_data()
	var limit: int = roundi(threshold * 255.0)
	var rows: PackedInt32Array = PackedInt32Array()
	rows.resize(height)
	var columns: PackedInt32Array = PackedInt32Array()
	columns.resize(width)
	for y: int in range(0, height, step):
		for x: int in range(0, width, step):
			var index: int = (y * width + x) * 4
			if maxi(data[index], maxi(data[index + 1], data[index + 2])) > limit:
				rows[y] += 1
				columns[x] += 1
	var low: Vector2i = Vector2i(width, height)
	var high: Vector2i = Vector2i(-1, -1)
	for y: int in range(0, height, step):
		if rows[y] >= min_pixels:
			low.y = mini(low.y, y)
			high.y = maxi(high.y, y)
	for x: int in range(0, width, step):
		if columns[x] >= min_pixels:
			low.x = mini(low.x, x)
			high.x = maxi(high.x, x)
	if high.x < 0 or high.y < 0:
		return Rect2i()
	return Rect2i(low, high - low + Vector2i.ONE)


## The centres of the lit window panes of a wall picture: blobs of bright, bluish pixels. Panes
## whose centres are closer than `merge` pixels in x count as one. Sorted from left to right.
static func glass_centres(image: Image, merge: int = 60) -> Array[Vector2]:
	_to_rgba8(image)
	var width: int = image.get_width()
	var data: PackedByteArray = image.get_data()
	var points: Array[Vector2] = []
	for y: int in range(0, image.get_height(), 2):
		for x: int in range(0, width, 2):
			var index: int = (y * width + x) * 4
			var red: int = data[index]
			var blue: int = data[index + 2]
			if data[index + 3] > 200 and blue > 190 and blue > red + 25:
				points.append(Vector2(x, y))
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var groups: Array[Array] = []
	for point: Vector2 in points:
		if groups.is_empty() or point.x - (groups.back() as Array).back().x > merge:
			groups.append([])
		groups.back().append(point)
	var centres: Array[Vector2] = []
	for group: Array in groups:
		if group.size() < 12:
			continue
		var sum: Vector2 = Vector2.ZERO
		for point: Vector2 in group:
			sum += point
		centres.append(sum / group.size())
	return centres
