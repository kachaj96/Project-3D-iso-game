class_name MapThemeTest
extends GdUnitTestSuite


func test_the_forest_is_not_darkened_and_the_crypt_is_much_darker() -> void:
	assert_object(MapTheme.darkness(MapTheme.FOREST)).is_equal(Color.WHITE)
	var dark: Color = MapTheme.darkness(MapTheme.DARK_INTERIOR)
	assert_float(dark.r).is_less(0.35)
	assert_float(dark.g).is_less(0.35)
	assert_float(dark.b).is_less(0.4)


func test_an_interior_has_stronger_mist_and_a_colder_light() -> void:
	assert_float(MapTheme.mist_opacity(MapTheme.DARK_INTERIOR)).is_greater(MapTheme.mist_opacity(MapTheme.FOREST))
	assert_float(MapTheme.light_tint(MapTheme.DARK_INTERIOR).b).is_greater(MapTheme.light_tint(MapTheme.DARK_INTERIOR).r)
	assert_float(MapTheme.light_tint(MapTheme.FOREST).r).is_greater(MapTheme.light_tint(MapTheme.FOREST).b)


func test_a_kit_is_named_after_its_region_and_mood() -> void:
	assert_str(MapKit.name_for("gluchobor", MapTheme.FOREST)).is_equal("gluchobor")
	assert_str(MapKit.name_for("gluchobor", MapTheme.DARK_INTERIOR)).is_equal("gluchobor_dark_interior")


func test_every_map_theme_of_the_format_is_known_to_the_scene() -> void:
	for theme: String in MapSpec.THEMES:
		assert_float(MapTheme.darkness(theme).r).is_between(0.0, 1.0)
