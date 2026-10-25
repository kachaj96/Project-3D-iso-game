extends SceneTree
## Turns the AI pictures of one map into game assets. Reads the manifest
## art_source/maps/<id>/layered/assets_manifest.json (which picture file is the ground, the crypt
## and so on), cleans every picture (see SpriteCleanup) and writes:
##
##   assets/art/maps/<id>/ground.png, building_B.png, building_B_shadow.png, mist.png, light.png
##   content/kits/<region>.tres (a MapKit that lists the kit pieces)
##   assets/art/kits/<region>/trees|plants|rocks|patches/<kind>_<nn>.png
##
## The building (symbol B) keeps the size of its picture (it is placed by the map footprint, so its empty
## border matters). Kit pieces are cut out of their sheets and trimmed. Mist and light are
## one-colour pictures whose opacity is the brightness of the AI picture.
##
##   godot --headless --path . --script res://tools/art/prepare_map_assets.gd -- <map id>

const MIST_TINT: Color = Color(0.62, 0.72, 0.78)
const LIGHT_TINT: Color = Color(1.0, 0.86, 0.55)
## Sheets and the kit folder and name they become.
const SHEETS: Dictionary = {"trees": "tree", "plants": "plant", "rocks": "rock", "patches": "patch"}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: -- <map id>")
		quit(1)
		return
	var map_id: String = args[0]
	var region: String = map_id.split(".")[1]
	var source_dir: String = "res://art_source/maps/%s/layered/" % map_id
	var manifest_text: String = FileAccess.get_file_as_string(source_dir + "assets_manifest.json")
	var manifest: Variant = JSON.parse_string(manifest_text)
	if manifest == null or not manifest is Dictionary:
		printerr("Cannot read the manifest " + source_dir + "assets_manifest.json")
		quit(1)
		return
	var map_dir: String = "res://assets/art/maps/%s/" % map_id
	var kit_dir: String = "res://assets/art/kits/%s/" % region
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(map_dir))
	var ok: bool = true
	ok = ok and _write(_load(source_dir + manifest["ground"]), map_dir + "ground.png")
	var building: Image = _cleaned(_load(source_dir + manifest["building_B"]))
	ok = ok and _write(building, map_dir + "building_B.png")
	ok = ok and _write(SpriteCleanup.make_shadow(building), map_dir + "building_B_shadow.png")
	ok = ok and _write(SpriteCleanup.luminance_to_alpha(_load(source_dir + manifest["mist"]), MIST_TINT), map_dir + "mist.png")
	ok = ok and _write(SpriteCleanup.luminance_to_alpha(_load(source_dir + manifest["light"]), LIGHT_TINT), map_dir + "light.png")
	var kit: MapKit = MapKit.new()
	kit.region = region
	for sheet_key: String in SHEETS:
		var sheet: Image = _cleaned(_load(source_dir + manifest[sheet_key]))
		var rects: Array[Rect2i] = SpriteCleanup.split_items(sheet)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(kit_dir + sheet_key))
		var paths: Array[String] = []
		for index: int in rects.size():
			var path: String = "%s%s/%s_%02d.png" % [kit_dir, sheet_key, SHEETS[sheet_key], index + 1]
			var piece: Image = sheet.get_region(rects[index])
			ok = ok and _write(piece, path)
			# Trees and the big rocks cast a shadow on the ground.
			if sheet_key == "trees" or (sheet_key == "rocks" and index < MapKit.new().cell_rocks):
				ok = ok and _write(SpriteCleanup.make_shadow(piece), path.trim_suffix(".png") + "_shadow.png")
			paths.append(path)
		print("%s: %d pieces" % [sheet_key, rects.size()])
		kit.set(sheet_key, paths)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://content/kits"))
	var save_error: Error = ResourceSaver.save(kit, "res://content/kits/%s.tres" % region)
	if save_error != OK:
		printerr("Cannot save the kit: " + error_string(save_error))
		ok = false
	quit(0 if ok else 1)


func _load(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		printerr("Cannot read " + path)
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _cleaned(image: Image) -> Image:
	SpriteCleanup.solidify(image)
	SpriteCleanup.bleed_colours(image)
	return image


func _write(image: Image, path: String) -> bool:
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		printerr("Cannot save %s: %s" % [path, error_string(error)])
		return false
	print("wrote " + path)
	return true
