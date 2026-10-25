class_name MapKitTest
extends GdUnitTestSuite

const KIT_PATH: String = "res://content/kits/gluchobor.tres"


func test_the_region_kit_lists_pieces_that_exist() -> void:
	var kit: MapKit = load(KIT_PATH)
	assert_object(kit).is_not_null()
	assert_str(kit.region).is_equal("gluchobor")
	for list: Array[String] in [kit.trees, kit.plants, kit.rocks, kit.patches]:
		assert_bool(list.is_empty()).is_false()
		for path: String in list:
			assert_bool(FileAccess.file_exists(path)).is_true()


func test_the_kit_has_enough_variety_to_dress_a_map() -> void:
	var kit: MapKit = load(KIT_PATH)
	assert_int(kit.trees.size()).is_greater_equal(3)
	assert_int(kit.plants.size()).is_greater_equal(8)
	assert_int(kit.patches.size()).is_greater_equal(6)
	assert_int(kit.cell_rocks).is_between(1, kit.rocks.size())


func test_kit_pieces_are_cleaned_pictures_with_real_transparency() -> void:
	var kit: MapKit = load(KIT_PATH)
	for path: String in [kit.trees[0], kit.plants[0], kit.rocks[0], kit.patches[0]]:
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_object(image).is_not_null()
		image.convert(Image.FORMAT_RGBA8)
		# Trimmed: the picture touches all four sides, so no empty border is left.
		var rect: Rect2i = SpriteCleanup.content_rect(image)
		assert_object(rect).is_equal(Rect2i(Vector2i.ZERO, image.get_size()))
		# Cleaned: no hazy pixels left.
		var faint: int = 0
		for y: int in image.get_height():
			for x: int in image.get_width():
				var alpha: float = image.get_pixel(x, y).a
				if alpha > 0.0 and alpha < SpriteCleanup.FAINT_ALPHA - 0.01:
					faint += 1
		assert_int(faint).is_equal(0)
