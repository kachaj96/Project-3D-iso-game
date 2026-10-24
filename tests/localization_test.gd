class_name LocalizationTest
extends GdUnitTestSuite
## Rule 7 of ARCHITECTURE.md: every text the player sees is a key with an English and a
## Polish translation.

const MAP_PATHS: Array[String] = ["res://content/maps/start_01.tres", "res://content/maps/start_02.tres"]


func after_test() -> void:
	TranslationServer.set_locale("en")


func _msgids(path: String) -> Array[String]:
	var ids: Array[String] = []
	var regex: RegEx = RegEx.create_from_string("(?m)^msgid \"(.+)\"$")
	for found: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
		ids.append(found.get_string(1))
	ids.sort()
	return ids


func test_english_and_polish_have_exactly_the_same_keys() -> void:
	assert_array(_msgids("res://localization/pl.po")).is_equal(_msgids("res://localization/en.po"))


func test_every_text_key_used_by_map_props_is_translated_in_both_languages() -> void:
	for map_path: String in MAP_PATHS:
		for prop: MapProp in (load(map_path) as MapDef).props:
			for locale: String in ["en", "pl"]:
				TranslationServer.set_locale(locale)
				assert_str(tr(prop.text_key)).is_not_equal(prop.text_key)


func test_polish_text_keeps_its_diacritics() -> void:
	TranslationServer.set_locale("pl")
	assert_str(tr("sign.start.welcome")).contains("Ścieżka")
