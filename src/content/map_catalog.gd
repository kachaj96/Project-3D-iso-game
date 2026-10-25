class_name MapCatalog
extends Resource
## Every map of the game: its id with where its data and its painted scene live. Written by
## the map generator (tools/maps/generate.gd), never edited by hand. The game loads maps
## through it, so adding a map needs no code change.

## Map id -> path of the MapDef resource.
@export var defs: Dictionary[String, String] = {}
## Map id -> path of the scene with the picture of the map.
@export var scenes: Dictionary[String, String] = {}


## Every map id, sorted.
func ids() -> Array[String]:
	var found: Array[String] = []
	found.assign(defs.keys())
	found.sort()
	return found


## Loads the data of every map: Dictionary of map id -> MapDef.
func load_maps() -> Dictionary:
	var maps: Dictionary = {}
	for map_id: String in defs:
		maps[map_id] = load(defs[map_id])
	return maps
