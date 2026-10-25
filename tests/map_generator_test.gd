class_name MapGeneratorTest
extends GdUnitTestSuite

const MAP_A: String = """
id: map.test.00_00
region: test
title_key: map.test.00_00.title
size: 4x4
grid:
. . = .
 . . .
. @ = >
 . # 1
markers:
1 prop sign prop.test.sign sign.test.sign
entries:
from_b 0 1
"""

const MAP_B: String = """
id: map.test.01_00
region: test
size: 4x4
grid:
. . . .
 . = 2
> @ = .
 . . .
markers:
2 link door map.test.00_00 from_b
entries:
from_a 2 1
"""

const KEYS: Dictionary = {
	"en": ["map.test.00_00.title", "sign.test.sign"],
	"pl": ["map.test.00_00.title", "sign.test.sign"],
}


func _run(a: String = MAP_A, b: String = MAP_B, keys: Dictionary = KEYS) -> MapGenerator:
	return MapGenerator.run({"test/00_00.txt": a, "test/01_00.txt": b}, keys)


func _has(messages: Array[String], fragment: String) -> bool:
	for message: String in messages:
		if message.contains(fragment):
			return true
	return false


func test_two_good_maps_generate_without_errors() -> void:
	var generator: MapGenerator = _run()
	assert_array(generator.errors).is_empty()
	assert_int(generator.maps.size()).is_equal(2)
	assert_bool(generator.is_valid()).is_true()


func test_a_syntax_error_names_the_file() -> void:
	var generator: MapGenerator = _run(MAP_A.replace("size: 4x4", "size: big"))
	assert_bool(_has(generator.errors, "test/00_00.txt: line ")).is_true()
	assert_int(generator.maps.size()).is_equal(0)


func test_two_files_with_the_same_id_are_reported() -> void:
	var generator: MapGenerator = _run(MAP_A, MAP_B.replace("map.test.01_00", "map.test.00_00"))
	assert_bool(_has(generator.errors, "already used")).is_true()


func test_errors_from_the_builder_are_reported() -> void:
	var generator: MapGenerator = _run(MAP_A, MAP_B.replace("> @ = .", ". @ = ."))
	assert_bool(_has(generator.errors, "no matching '>'")).is_true()


func test_a_walled_off_cell_is_reported() -> void:
	# A row of rocks cuts the top row off from the spawn.
	var walled: String = MAP_A.replace(" . . .\n. @", " # # #\n. @")
	var generator: MapGenerator = _run(walled)
	assert_bool(_has(generator.errors, "cannot be reached")).is_true()


func test_missing_translations_are_reported_for_title_and_props() -> void:
	var keys: Dictionary = {"en": ["map.test.00_00.title"], "pl": ["sign.test.sign"]}
	var generator: MapGenerator = _run(MAP_A, MAP_B, keys)
	assert_bool(_has(generator.errors, "'sign.test.sign' is missing in 'en'")).is_true()
	assert_bool(_has(generator.errors, "'map.test.00_00.title' is missing in 'pl'")).is_true()


func test_paths_follow_the_map_id() -> void:
	assert_str(MapGenerator.def_path("map.hollow.04_07")).is_equal("res://content/maps/hollow/04_07.tres")
	assert_str(MapGenerator.def_path("map.hollow.04_07.in01")).is_equal("res://content/maps/hollow/04_07.in01.tres")
	assert_str(MapGenerator.scene_path("map.hollow.04_07")).is_equal("res://scenes/world/maps/hollow/04_07.tscn")


func test_the_catalog_lists_every_map_with_its_paths() -> void:
	var catalog: MapCatalog = _run().build_catalog()
	assert_array(catalog.ids()).is_equal(["map.test.00_00", "map.test.01_00"])
	assert_str(catalog.defs["map.test.01_00"]).is_equal("res://content/maps/test/01_00.tres")
	assert_str(catalog.scenes["map.test.00_00"]).is_equal("res://scenes/world/maps/test/00_00.tscn")


func test_the_scene_stub_has_every_layer_and_matches_the_map() -> void:
	var map: MapDef = _run().maps["map.test.00_00"]
	var tile_set: TileSet = load(MapSceneStub.TILE_SET_PATH)
	var root: Node2D = auto_free(MapSceneStub.build(map, "res://content/maps/test/00_00.tres", tile_set))
	for layer: String in ["Backdrop", "Ground", "Objects", "Occluders", "Effects", "Lights", "CellOverlay"]:
		assert_object(root.get_node_or_null(layer)).is_not_null()
	assert_bool((root.get_node("CellOverlay") as Node2D).visible).is_false()
	var ground: TileMapLayer = root.get_node("Ground")
	assert_int(ground.get_used_cells().size()).is_equal(MapLayout.cell_count(4, 4))
	var objects: TileMapLayer = root.get_node("Objects")
	var painted: Array[Vector2i] = objects.get_used_cells()
	painted.sort()
	var expected: Array[Vector2i] = map.blocked_cells.duplicate()
	expected.sort()
	assert_array(painted).is_equal(expected)
