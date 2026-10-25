class_name MapGenerator
extends RefCounted
## The map generator's brain: from the texts of all map files to checked game data. No files
## are read or written here (tools/maps/generate.gd does that), so tests can run it on texts.
##
## Check `errors` first. With errors nothing may be written. `warnings` are shown only.

const DEF_ROOT: String = "res://content/maps/"
const SCENE_ROOT: String = "res://scenes/world/maps/"

## Map id -> MapDef.
var maps: Dictionary = {}
## Map id -> MapSpec.
var specs: Dictionary = {}
var errors: Array[String] = []
var warnings: Array[String] = []


## `texts` maps a label (the file name, used in messages) to the text of one map file.
## `keys_by_language` maps a language to the translation keys it has.
static func run(texts: Dictionary, keys_by_language: Dictionary) -> MapGenerator:
	var generator: MapGenerator = MapGenerator.new()
	generator._run(texts, keys_by_language)
	return generator


func is_valid() -> bool:
	return errors.is_empty()


## "map.hollow.04_07" -> "hollow/04_07", "map.hollow.04_07.in01" -> "hollow/04_07.in01".
static func relative_path(map_id: String) -> String:
	var parts: PackedStringArray = map_id.split(".")
	return "%s/%s" % [parts[1], ".".join(parts.slice(2))]


static func def_path(map_id: String) -> String:
	return DEF_ROOT + relative_path(map_id) + ".tres"


static func scene_path(map_id: String) -> String:
	return SCENE_ROOT + relative_path(map_id) + ".tscn"


## The catalog of all generated maps.
func build_catalog() -> MapCatalog:
	var catalog: MapCatalog = MapCatalog.new()
	for map_id: String in maps:
		catalog.defs[map_id] = def_path(map_id)
		catalog.scenes[map_id] = scene_path(map_id)
	return catalog


func _run(texts: Dictionary, keys_by_language: Dictionary) -> void:
	for label: String in texts:
		var spec: MapSpec = MapSpec.parse(texts[label] as String)
		for error: String in spec.errors:
			errors.append("%s: %s" % [label, error])
		if spec.is_valid():
			if specs.has(spec.id):
				errors.append("%s: map id %s is already used by another file" % [label, spec.id])
			specs[spec.id] = spec
	if not errors.is_empty():
		return
	for map_id: String in specs:
		var builder: MapBuilder = MapBuilder.build(specs[map_id] as MapSpec, specs)
		errors.append_array(builder.errors)
		maps[map_id] = builder.map
	if not errors.is_empty():
		return
	errors.append_array(MapChecks.check_set(maps))
	for map_id: String in specs:
		errors.append_array(MapChecks.missing_translations(map_id, _keys_used(specs[map_id] as MapSpec), keys_by_language))
		warnings.append_array(MapChecks.hidden_cells(maps[map_id] as MapDef))


func _keys_used(spec: MapSpec) -> Array[String]:
	var keys: Array[String] = []
	if not spec.title_key.is_empty():
		keys.append(spec.title_key)
	for prop: Dictionary in spec.props:
		keys.append(prop["text_key"] as String)
	return keys
