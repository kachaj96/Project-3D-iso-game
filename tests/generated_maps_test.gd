class_name GeneratedMapsTest
extends GdUnitTestSuite
## Keeps the generated files honest: every map file in content/map_specs must be valid, the
## committed data (.tres), the catalog and the scene must match it. If this fails after you
## edited a map file, run tools/maps/generate.gd (see docs/MAP_FORMAT.md, section 5).

const SPECS_DIR: String = "res://content/map_specs"
const CATALOG_PATH: String = "res://content/maps/catalog.tres"


func _find_files(directory: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		return found
	for entry: String in dir.get_directories():
		found.append_array(_find_files(directory + "/" + entry))
	for file: String in dir.get_files():
		if file.ends_with(".txt"):
			found.append(directory + "/" + file)
	found.sort()
	return found


func _keys(language: String) -> Array[String]:
	var ids: Array[String] = []
	var regex: RegEx = RegEx.create_from_string("(?m)^msgid \"(.+)\"$")
	for found: RegExMatch in regex.search_all(FileAccess.get_file_as_string("res://localization/%s.po" % language)):
		ids.append(found.get_string(1))
	return ids


func _generate() -> MapGenerator:
	var texts: Dictionary = {}
	for path: String in _find_files(SPECS_DIR):
		texts[path] = FileAccess.get_file_as_string(path)
	return MapGenerator.run(texts, {"en": _keys("en"), "pl": _keys("pl")})


func _sorted(cells: Array[Vector2i]) -> Array[Vector2i]:
	var copy: Array[Vector2i] = cells.duplicate()
	copy.sort()
	return copy


func test_every_map_file_is_valid() -> void:
	var generator: MapGenerator = _generate()
	assert_array(generator.errors).is_empty()


func test_the_committed_map_data_matches_the_map_files() -> void:
	var generator: MapGenerator = _generate()
	for map_id: String in generator.maps:
		var wanted: MapDef = generator.maps[map_id]
		assert_bool(ResourceLoader.exists(MapGenerator.def_path(map_id))).is_true()
		var saved: MapDef = load(MapGenerator.def_path(map_id))
		assert_str(saved.id).is_equal(wanted.id)
		assert_vector(saved.size).is_equal(wanted.size)
		assert_int(saved.shape).is_equal(wanted.shape)
		assert_vector(saved.spawn_cell).is_equal(wanted.spawn_cell)
		assert_array(_sorted(saved.blocked_cells)).is_equal(_sorted(wanted.blocked_cells))
		assert_dict(saved.heights).is_equal(wanted.heights)
		assert_dict(saved.cell_kinds).is_equal(wanted.cell_kinds)
		assert_int(saved.exits.size()).is_equal(wanted.exits.size())
		assert_int(saved.props.size()).is_equal(wanted.props.size())


func test_the_catalog_lists_exactly_the_maps_of_the_files() -> void:
	var generator: MapGenerator = _generate()
	var catalog: MapCatalog = load(CATALOG_PATH)
	var wanted: Array[String] = []
	wanted.assign(generator.maps.keys())
	wanted.sort()
	assert_array(catalog.ids()).is_equal(wanted)
	assert_array(MapDef.validate_set(catalog.load_maps())).is_empty()


func test_every_scene_covers_exactly_the_cells_of_its_map() -> void:
	var catalog: MapCatalog = load(CATALOG_PATH)
	for map_id: String in catalog.ids():
		var map: MapDef = load(catalog.defs[map_id])
		var scene: Node2D = auto_free((load(catalog.scenes[map_id]) as PackedScene).instantiate())
		var ground: TileMapLayer = scene.get_node("Ground")
		assert_int(ground.get_used_cells().size()).is_equal(map.all_cells().size())
		var obstacles: TileMapLayer = scene.get_node("Objects")
		assert_array(_sorted(obstacles.get_used_cells())).is_equal(_sorted(map.blocked_cells))
