extends SceneTree
## One-off tool: builds content/tilesets/placeholder_iso.tres from the placeholder atlas.
## Isometric diamond tiles, 128x64 cells, one custom data layer "kind":
##   "ground"   walkable floor
##   "exit"     walkable floor that leads to another map
##   "obstacle" blocks movement (stacked on top of a ground tile)
##
## Run after build_placeholder_atlas.gd and a re-import:
##   godot --headless --path . --script res://tools/build_placeholder_tileset.gd

const ATLAS_PATH: String = "res://assets/art/placeholder/placeholder_atlas.png"
const OUTPUT_PATH: String = "res://content/tilesets/placeholder_iso.tres"
const CELL_SIZE: Vector2i = Vector2i(128, 128)
const DIAMOND_SIZE: Vector2i = Vector2i(128, 64)

## Atlas column -> kind. Keep in sync with build_placeholder_atlas.gd.
const TILE_KINDS: Array[String] = ["ground", "ground", "exit", "obstacle", "obstacle"]


func _init() -> void:
	var texture: Texture2D = load(ATLAS_PATH)
	if texture == null:
		push_error("Atlas not imported yet. Run --import first.")
		quit(1)
		return

	var tile_set: TileSet = TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	tile_set.tile_size = DIAMOND_SIZE
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "kind")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = CELL_SIZE
	# The source must belong to the TileSet before tile data can be edited.
	tile_set.add_source(source, 0)
	for column: int in TILE_KINDS.size():
		source.create_tile(Vector2i(column, 0))
		var data: TileData = source.get_tile_data(Vector2i(column, 0), 0)
		# The image is 128x128 but only its top 64 rows are the floor diamond, so lift
		# the picture by 32 px to put the diamond centre on the cell centre.
		data.texture_origin = Vector2i(0, -32)
		data.set_custom_data("kind", TILE_KINDS[column])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("Cannot save TileSet: %s" % error_string(error))
		quit(1)
		return
	print("TileSet written: %s" % OUTPUT_PATH)
	quit(0)
