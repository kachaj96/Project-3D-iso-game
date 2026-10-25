extends SceneTree
## The map generator. Reads every map file in content/map_specs, checks the whole set and
## writes the game data. Run it after changing a map file:
##
##   godot --headless --path . --script res://tools/maps/generate.gd
##
## Writes (always): content/maps/<region>/<cc>_<rr>.tres for every map and content/maps/catalog.tres.
## Writes (always): art_source/maps/<id>/blockout.png and prompt.md for the image AI.
## Writes (only when missing): scenes/world/maps/<region>/<cc>_<rr>.tscn, the scene you edit by
## hand. An existing scene is never touched.
## When the kit and the pictures exist (see tools/art/prepare_map_assets.gd) the scene is also dressed:
## backdrop, ground decals, objects, mist and light are put in once; add -- --redress to replace the
## generated nodes (group "generated") again. Your own nodes are never touched. The pictures must
## be imported first (godot --headless --import).
## With errors nothing is written and the exit code is 1.

const SPECS_DIR: String = "res://content/map_specs"
const CATALOG_PATH: String = "res://content/maps/catalog.tres"
const LANGUAGES: Array[String] = ["en", "pl"]
const ART_DIR: String = "res://art_source/maps/"


func _init() -> void:
	var texts: Dictionary = {}
	for path: String in _find_files(SPECS_DIR, ".txt"):
		texts[path.trim_prefix(SPECS_DIR + "/")] = FileAccess.get_file_as_string(path)
	if texts.is_empty():
		push_error("No map files found in " + SPECS_DIR)
		quit(1)
		return
	var generator: MapGenerator = MapGenerator.run(texts, _translation_keys())
	for warning: String in generator.warnings:
		print("WARNING: " + warning)
	if not generator.is_valid():
		for error: String in generator.errors:
			printerr("ERROR: " + error)
		printerr("%d error(s). Nothing was written." % generator.errors.size())
		quit(1)
		return
	var tile_set: TileSet = load(MapSceneStub.TILE_SET_PATH)
	for map_id: String in generator.maps:
		var map: MapDef = generator.maps[map_id]
		if not _save(map, MapGenerator.def_path(map_id)):
			return
		var scene_path: String = MapGenerator.scene_path(map_id)
		if FileAccess.file_exists(scene_path):
			print("kept your scene: " + scene_path)
		elif not _write_scene(map, tile_set, scene_path):
			return
		if not _write_art_helpers(generator.specs[map_id] as MapSpec, generator.specs):
			return
		if not _dress(generator.specs[map_id] as MapSpec, scene_path, "--redress" in OS.get_cmdline_user_args()):
			return
	if not _save(generator.build_catalog(), CATALOG_PATH):
		return
	print("Generated %d map(s)." % generator.maps.size())
	quit(0)


func _save(resource: Resource, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error: Error = ResourceSaver.save(resource, path)
	if error != OK:
		printerr("Cannot save %s: %s" % [path, error_string(error)])
		quit(1)
		return false
	print("wrote " + path)
	return true


## The blockout picture and the prompt for the image AI. Always rewritten: they come only from
## the map file.
func _write_art_helpers(spec: MapSpec, specs: Dictionary) -> bool:
	var directory: String = ART_DIR + spec.id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var error: Error = MapBlockout.render(spec).save_png(ProjectSettings.globalize_path(directory + "/blockout.png"))
	if error != OK:
		printerr("Cannot save the blockout of %s: %s" % [spec.id, error_string(error)])
		quit(1)
		return false
	var prompt: FileAccess = FileAccess.open(directory + "/prompt.md", FileAccess.WRITE)
	if prompt == null:
		printerr("Cannot save the prompt of %s" % spec.id)
		quit(1)
		return false
	prompt.store_string(MapPrompt.build(spec, specs))
	prompt.close()
	if not _write_layered(spec, directory + "/layered"):
		return false
	print("wrote " + directory + "/blockout.png and prompt.md")
	return true


## The layered experiment: ground and objects as separate pictures (see MapPrompt.build_layered).
func _write_layered(spec: MapSpec, directory: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var pictures: Dictionary = {
		"ground_blockout.png": MapBlockout.render_ground(spec),
		"objects_B_blockout.png": MapBlockout.render_cluster(spec, "B"),
	}
	for file_name: String in pictures:
		var error: Error = (pictures[file_name] as Image).save_png(ProjectSettings.globalize_path(directory + "/" + file_name))
		if error != OK:
			printerr("Cannot save %s: %s" % [file_name, error_string(error)])
			quit(1)
			return false
	var prompt: FileAccess = FileAccess.open(directory + "/layered_prompt.md", FileAccess.WRITE)
	if prompt == null:
		printerr("Cannot save the layered prompt of %s" % spec.id)
		quit(1)
		return false
	prompt.store_string(MapPrompt.build_layered(spec))
	prompt.close()
	print("wrote " + directory)
	return true


func _write_scene(map: MapDef, tile_set: TileSet, scene_path: String) -> bool:
	var root: Node2D = MapSceneStub.build(map, MapGenerator.def_path(map.id), tile_set)
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	root.free()
	return _save(packed, scene_path)


## Every file with this ending under a directory, sorted.
func _find_files(directory: String, ending: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		return found
	for entry: String in dir.get_directories():
		found.append_array(_find_files(directory + "/" + entry, ending))
	for file: String in dir.get_files():
		if file.ends_with(ending):
			found.append(directory + "/" + file)
	found.sort()
	return found


## Language -> translation keys, from the .po files in localization/.
func _translation_keys() -> Dictionary:
	var keys: Dictionary = {}
	var regex: RegEx = RegEx.create_from_string("(?m)^msgid \"(.+)\"$")
	for language: String in LANGUAGES:
		var found: Array[String] = []
		for match_found: RegExMatch in regex.search_all(FileAccess.get_file_as_string("res://localization/%s.po" % language)):
			found.append(match_found.get_string(1))
		keys[language] = found
	return keys


## Dresses the scene of a map with its pictures (see MapDresser). Done once; `force` dresses again.
func _dress(spec: MapSpec, scene_path: String, force: bool) -> bool:
	var region: String = spec.id.split(".")[1]
	var kit_path: String = "res://content/kits/%s.tres" % region
	var assets_dir: String = "res://assets/art/maps/%s/" % spec.id
	if not ResourceLoader.exists(kit_path) or not FileAccess.file_exists(assets_dir + "ground.png"):
		print("no pictures yet for %s: left undressed" % spec.id)
		return true
	var packed: PackedScene = load(scene_path)
	var root: Node2D = packed.instantiate()
	if root.has_node(MapDresser.DRESSING) and not force:
		print("already dressed (use -- --redress to dress again): " + scene_path)
		root.free()
		return true
	var kit: MapKit = load(kit_path)
	var buildings: Dictionary = {}
	for symbol: String in "B":
		if FileAccess.file_exists("%sbuilding_%s.png" % [assets_dir, symbol]) and not spec.find_symbol(symbol).is_empty():
			buildings[symbol] = "%sbuilding_%s.png" % [assets_dir, symbol]
	var placements: Array[MapPlacer.Placement] = MapPlacer.build(spec, kit, buildings, _picture_sizes(kit, buildings))
	MapDresser.dress(root, spec, placements, assets_dir)
	var result: PackedScene = PackedScene.new()
	result.pack(root)
	root.free()
	print("dressed %s with %d pieces" % [scene_path, placements.size()])
	return _save(result, scene_path)


## Picture path -> size, for every kit piece, shadow and building picture that exists.
func _picture_sizes(kit: MapKit, buildings: Dictionary) -> Dictionary:
	var sizes: Dictionary = {}
	var paths: Array[String] = []
	for list: Array[String] in [kit.trees, kit.plants, kit.rocks, kit.patches]:
		paths.append_array(list)
	for symbol: String in buildings:
		paths.append(buildings[symbol] as String)
	for path: String in paths:
		for candidate: String in [path, path.trim_suffix(".png") + MapPlacer.SHADOW_SUFFIX]:
			if FileAccess.file_exists(candidate):
				var image: Image = Image.load_from_file(ProjectSettings.globalize_path(candidate))
				if image != null:
					sizes[candidate] = Vector2i(image.get_width(), image.get_height())
	return sizes
