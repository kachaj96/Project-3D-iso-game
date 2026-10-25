class_name SpriteCleanupTest
extends GdUnitTestSuite


func _blank(width: int, height: int) -> Image:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


func _square(image: Image, rect: Rect2i, colour: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			image.set_pixel(x, y, colour)


func test_solidify_clears_haze_and_closes_nearly_opaque_pixels() -> void:
	var image: Image = _blank(4, 1)
	image.set_pixel(0, 0, Color(0.2, 0.4, 0.2, 0.1))
	image.set_pixel(1, 0, Color(0.2, 0.4, 0.2, 0.5))
	image.set_pixel(2, 0, Color(0.2, 0.4, 0.2, 0.93))
	image.set_pixel(3, 0, Color(0.2, 0.4, 0.2, 1.0))
	SpriteCleanup.solidify(image)
	assert_float(image.get_pixel(0, 0).a).is_equal(0.0)
	assert_float(image.get_pixel(1, 0).a).is_equal_approx(0.5, 0.01)
	assert_float(image.get_pixel(2, 0).a).is_equal(1.0)
	assert_float(image.get_pixel(3, 0).a).is_equal(1.0)


func test_bleed_gives_edge_pixels_the_colour_of_the_solid_neighbour() -> void:
	var image: Image = _blank(5, 1)
	image.set_pixel(0, 0, Color(0.1, 0.6, 0.1, 1.0))
	# A half transparent pixel with a pink fringe, then a hazy pixel with an unrelated colour.
	image.set_pixel(1, 0, Color(1.0, 0.0, 1.0, 0.5))
	image.set_pixel(2, 0, Color(0.9, 0.9, 0.0, 0.0))
	SpriteCleanup.bleed_colours(image)
	var fixed: Color = image.get_pixel(1, 0)
	assert_float(fixed.r).is_equal_approx(0.1, 0.02)
	assert_float(fixed.g).is_equal_approx(0.6, 0.02)
	assert_float(fixed.a).is_equal_approx(0.5, 0.01)
	var far: Color = image.get_pixel(2, 0)
	assert_float(far.g).is_equal_approx(0.6, 0.02)
	assert_float(far.a).is_equal(0.0)


func test_bleed_does_not_touch_solid_pixels() -> void:
	var image: Image = _blank(3, 1)
	image.set_pixel(0, 0, Color(0.2, 0.3, 0.4, 1.0))
	image.set_pixel(1, 0, Color(0.8, 0.1, 0.1, 1.0))
	SpriteCleanup.bleed_colours(image)
	assert_float(image.get_pixel(0, 0).r).is_equal_approx(0.2, 0.01)
	assert_float(image.get_pixel(1, 0).r).is_equal_approx(0.8, 0.01)


func test_content_rect_and_trim_remove_the_empty_border() -> void:
	var image: Image = _blank(20, 12)
	_square(image, Rect2i(5, 3, 6, 4), Color.RED)
	assert_object(SpriteCleanup.content_rect(image)).is_equal(Rect2i(5, 3, 6, 4))
	var cut: Image = SpriteCleanup.trimmed(image)
	assert_int(cut.get_width()).is_equal(6)
	assert_int(cut.get_height()).is_equal(4)
	assert_object(SpriteCleanup.content_rect(_blank(8, 8))).is_equal(Rect2i())


func test_split_items_finds_each_item_in_reading_order() -> void:
	var sheet: Image = _blank(600, 400)
	_square(sheet, Rect2i(40, 30, 100, 90), Color.GREEN)
	_square(sheet, Rect2i(300, 40, 120, 80), Color.GREEN)
	_square(sheet, Rect2i(60, 250, 90, 100), Color.GREEN)
	_square(sheet, Rect2i(450, 260, 110, 90), Color.GREEN)
	var rects: Array[Rect2i] = SpriteCleanup.split_items(sheet)
	assert_int(rects.size()).is_equal(4)
	assert_object(rects[0]).is_equal(Rect2i(40, 30, 100, 90))
	assert_object(rects[1]).is_equal(Rect2i(300, 40, 120, 80))
	assert_object(rects[2]).is_equal(Rect2i(60, 250, 90, 100))
	assert_object(rects[3]).is_equal(Rect2i(450, 260, 110, 90))


func test_split_items_keeps_close_pieces_together_and_ignores_specks() -> void:
	var sheet: Image = _blank(600, 300)
	# One item made of two pieces 10 px apart (a mushroom cap and its stem).
	_square(sheet, Rect2i(100, 50, 80, 60), Color.RED)
	_square(sheet, Rect2i(190, 70, 50, 120), Color.RED)
	_square(sheet, Rect2i(500, 250, 6, 6), Color.RED)
	var rects: Array[Rect2i] = SpriteCleanup.split_items(sheet)
	assert_int(rects.size()).is_equal(1)
	assert_int(rects[0].size.x).is_greater_equal(140)


func test_luminance_becomes_opacity_in_one_colour() -> void:
	var image: Image = _blank(3, 1)
	image.set_pixel(0, 0, Color(0, 0, 0, 1))
	image.set_pixel(1, 0, Color(0.5, 0.5, 0.5, 1))
	image.set_pixel(2, 0, Color(1, 1, 1, 1))
	var mist: Image = SpriteCleanup.luminance_to_alpha(image, Color(0.6, 0.7, 0.8))
	assert_float(mist.get_pixel(0, 0).a).is_equal(0.0)
	assert_float(mist.get_pixel(1, 0).a).is_equal_approx(0.5, 0.01)
	assert_float(mist.get_pixel(2, 0).a).is_equal(1.0)
	assert_float(mist.get_pixel(2, 0).g).is_equal_approx(0.7, 0.01)
