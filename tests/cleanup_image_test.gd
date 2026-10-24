class_name CleanupImageTest
extends GdUnitTestSuite

const Cleanup: GDScript = preload("res://tools/art/cleanup_image.gd")


## A 100 x 80 grey background with a red 40 x 20 block and a white 4 x 4 spot inside the block.
func _make_image() -> Image:
	var image: Image = Image.create_empty(100, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.8, 0.8, 1.0))
	image.fill_rect(Rect2i(30, 30, 40, 20), Color(0.8, 0.1, 0.1, 1.0))
	image.fill_rect(Rect2i(40, 35, 4, 4), Color(0.8, 0.8, 0.8, 1.0))
	return image


func test_background_is_removed_and_the_border_is_cut_away() -> void:
	var result: Image = Cleanup.process(_make_image(), 40, 0.12)
	assert_vector(result.get_size()).is_equal(Vector2i(40, 20))
	assert_float(result.get_pixel(0, 0).a).is_greater(0.9)


func test_the_width_matches_the_target_and_the_shape_is_kept() -> void:
	var result: Image = Cleanup.process(_make_image(), 128, 0.12)
	assert_int(result.get_width()).is_equal(128)
	assert_int(result.get_height()).is_equal(64)


func test_a_light_spot_inside_the_picture_is_not_removed() -> void:
	var result: Image = Cleanup.process(_make_image(), 40, 0.12)
	assert_float(result.get_pixel(11, 6).a).is_greater(0.9)


func test_corners_of_the_original_become_transparent() -> void:
	var image: Image = _make_image()
	Cleanup._remove_background(image, 0.12)
	assert_float(image.get_pixel(0, 0).a).is_equal(0.0)
	assert_float(image.get_pixel(99, 79).a).is_equal(0.0)
	assert_float(image.get_pixel(50, 40).a).is_equal(1.0)
