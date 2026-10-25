extends SceneTree
## One-off tool: paints every MapProp of each map onto the "Objects" layer of the map's
## existing scene. Safe to run again, and it keeps everything else you painted by hand.
##
## Run after build_placeholder_tileset.gd and a re-import:
##   godot --headless --path . --script res://tools/paint_props.gd

## Prop kind -> tile in the placeholder atlas (see build_placeholder_atlas.gd).
const PROP_TILES: Dictionary = {
	"sign": Vector2i(5, 0),
}

const MAPS: Dictionary = {
	"res://tests/fixtures/maps/start_01.tres": "res://tests/fixtures/maps/map_start_01.tscn",
	"res://tests/fixtures/maps/start_02.tres": "res://tests/fixtures/maps/map_start_02.tscn",
}


func _init() -> void:
	for map_path: String in MAPS:
		var map: MapDef = load(map_path)
		if map.props.is_empty():
			continue
		var scene_path: String = MAPS[map_path]
		var root: Node = (load(scene_path) as PackedScene).instantiate()
		var objects: TileMapLayer = root.get_node("Objects")
		for prop: MapProp in map.props:
			objects.set_cell(prop.cell, 0, PROP_TILES[prop.kind])
		var packed: PackedScene = PackedScene.new()
		packed.pack(root)
		var error: Error = ResourceSaver.save(packed, scene_path)
		root.free()
		if error != OK:
			push_error("Cannot save %s: %s" % [scene_path, error_string(error)])
			quit(1)
			return
		print("Painted %d prop(s) into %s" % [map.props.size(), scene_path])
	quit(0)
