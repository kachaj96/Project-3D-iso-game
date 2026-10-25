class_name MapSceneStub
extends RefCounted
## Builds the starting scene of a generated map (written once, then yours to edit).
##
## Layers, from back to front:
##   Backdrop    the picture of the map (empty until you give it a texture), drawn at half size
##               because backdrops are rendered at scale 2
##   Ground      placeholder tiles for every cell, behind everything
##   Objects     placeholder obstacles, sorted by their feet
##   Occluders   put pieces of the picture here that the character walks behind
##   Effects     particles, fog
##   Lights      lights and the daylight tint
##   CellOverlay switchable cell check, hidden by default
## The world scene (scenes/world/world.gd) looks for "Ground" and "Objects" by name.

const TILE_SET_PATH: String = "res://content/tilesets/placeholder_iso.tres"
const BLOCK_HEIGHT: int = 64
const BACKDROP_SCALE: float = 0.5

## Atlas columns, see tools/build_placeholder_atlas.gd.
const GRASS_DIRT: Vector2i = Vector2i(0, 0)
const GRASS_PLAIN: Vector2i = Vector2i(1, 0)
const DIRT_EXIT: Vector2i = Vector2i(2, 0)
const STONE: Vector2i = Vector2i(3, 0)
const LOG: Vector2i = Vector2i(4, 0)


## The scene root, ready to be packed. The caller frees it.
static func build(map: MapDef, def_path: String, tile_set: TileSet) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Map"

	var backdrop: Sprite2D = Sprite2D.new()
	backdrop.name = "Backdrop"
	backdrop.centered = false
	backdrop.scale = Vector2(BACKDROP_SCALE, BACKDROP_SCALE)
	backdrop.z_index = -2
	_add(root, backdrop)

	var ground: TileMapLayer = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	_add(root, ground)

	var objects: TileMapLayer = TileMapLayer.new()
	objects.name = "Objects"
	objects.tile_set = tile_set
	# One block higher than the ground, so obstacles stand on top of it.
	objects.position = Vector2(0.0, -BLOCK_HEIGHT)
	_add(root, objects)

	for node_name: String in ["Occluders", "Effects", "Lights"]:
		var layer: Node2D = Node2D.new()
		layer.name = node_name
		_add(root, layer)

	var overlay: CellOverlay = CellOverlay.new()
	overlay.name = "CellOverlay"
	overlay.map_path = def_path
	overlay.visible = false
	overlay.z_index = 100
	_add(root, overlay)

	for cell: Vector2i in map.all_cells():
		var tile: Vector2i = GRASS_DIRT if posmod(cell.x + cell.y, 2) == 0 else GRASS_PLAIN
		if map.find_exit_at(cell) != null:
			tile = DIRT_EXIT
		ground.set_cell(cell, 0, tile)
		if map.is_blocked(cell):
			objects.set_cell(cell, 0, STONE if posmod(cell.x, 2) == 0 else LOG)
	return root


static func _add(root: Node2D, node: Node) -> void:
	root.add_child(node)
	node.owner = root
