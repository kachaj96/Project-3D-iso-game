extends SceneTree
## One-off tool: creates a starting map scene for each MapDef, painted from its data.
## Ground = checkerboard of two grass tiles, exit cells = dirt, blocked cells = stone/log
## stacked one block high on a second layer.
##
## WARNING: overwrites the scene files. Once you paint a map by hand in the editor,
## do not run this tool for that map again.
##
## Run after build_placeholder_tileset.gd:
##   godot --headless --path . --script res://tools/build_map_scenes.gd

const TILE_SET_PATH: String = "res://content/tilesets/placeholder_iso.tres"
const BLOCK_HEIGHT: int = 64

## Atlas columns, see build_placeholder_atlas.gd.
const GRASS_DIRT: Vector2i = Vector2i(0, 0)
const GRASS_PLAIN: Vector2i = Vector2i(1, 0)
const DIRT_EXIT: Vector2i = Vector2i(2, 0)
const STONE: Vector2i = Vector2i(3, 0)
const LOG: Vector2i = Vector2i(4, 0)

const MAPS: Dictionary = {
	"res://content/maps/start_01.tres": "res://scenes/world/map_start_01.tscn",
	"res://content/maps/start_02.tres": "res://scenes/world/map_start_02.tscn",
}


func _init() -> void:
	var tile_set: TileSet = load(TILE_SET_PATH)
	if tile_set == null:
		push_error("TileSet missing: " + TILE_SET_PATH)
		quit(1)
		return
	for map_path: String in MAPS:
		var map: MapDef = load(map_path)
		var error: Error = _build_scene(map, tile_set, MAPS[map_path])
		if error != OK:
			push_error("Cannot save %s: %s" % [MAPS[map_path], error_string(error)])
			quit(1)
			return
		print("Scene written: %s" % MAPS[map_path])
	quit(0)


func _build_scene(map: MapDef, tile_set: TileSet, scene_path: String) -> Error:
	var root: Node2D = Node2D.new()
	root.name = scene_path.get_file().get_basename().to_pascal_case()

	var ground: TileMapLayer = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	root.add_child(ground)
	ground.owner = root

	var objects: TileMapLayer = TileMapLayer.new()
	objects.name = "Objects"
	objects.tile_set = tile_set
	# One block higher than the ground, so obstacles stand on top of it.
	objects.position = Vector2(0, -BLOCK_HEIGHT)
	root.add_child(objects)
	objects.owner = root

	for x: int in map.size.x:
		for y: int in map.size.y:
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = GRASS_DIRT if (x + y) % 2 == 0 else GRASS_PLAIN
			if map.find_exit_at(cell) != null:
				tile = DIRT_EXIT
			ground.set_cell(cell, 0, tile)
			if map.is_blocked(cell):
				objects.set_cell(cell, 0, STONE if x % 2 == 0 else LOG)

	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scene_path.get_base_dir()))
	var result: Error = ResourceSaver.save(packed, scene_path)
	root.free()
	return result
