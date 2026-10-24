extends SceneTree
## One-off tool: builds assets/art/placeholder/placeholder_atlas.png from Kenney
## "Isometric Blocks" (CC0). Each source tile (111x128) is scaled to 128x128 so the top
## diamond is exactly 128x64 (2:1), matching GridMath and decision D-008.
##
## Run: godot --headless --path . --script res://tools/build_placeholder_atlas.gd
## Then re-import (godot --headless --path . --import --quit) before building the TileSet.

const SOURCE_DIR: String = "res://assets/art/placeholder/kenney_isometric_blocks/PNG/Voxel tiles/"
const OUTPUT_PATH: String = "res://assets/art/placeholder/placeholder_atlas.png"
const CELL_SIZE: Vector2i = Vector2i(128, 128)

## Order = atlas column. Keep in sync with build_placeholder_tileset.gd.
const SOURCE_FILES: Array[String] = [
	"voxelTile_55.png", # grass_dirt
	"voxelTile_03.png", # grass_dark (second shade so the grid is visible)
	"voxelTile_53.png", # dirt (exit marker)
	"voxelTile_09.png", # stone (obstacle)
	"voxelTile_14.png", # log (obstacle)
	"voxelTile_18.png", # signpost stand-in (obstacle that can be read)
]


func _init() -> void:
	var atlas: Image = Image.create_empty(CELL_SIZE.x * SOURCE_FILES.size(), CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	for i: int in SOURCE_FILES.size():
		var path: String = ProjectSettings.globalize_path(SOURCE_DIR + SOURCE_FILES[i])
		var tile: Image = Image.load_from_file(path)
		if tile == null:
			push_error("Cannot load " + path)
			quit(1)
			return
		tile.convert(Image.FORMAT_RGBA8)
		tile.resize(CELL_SIZE.x, CELL_SIZE.y, Image.INTERPOLATE_LANCZOS)
		atlas.blit_rect(tile, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(i * CELL_SIZE.x, 0))
	var error: Error = atlas.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Cannot save atlas: %s" % error_string(error))
		quit(1)
		return
	print("Atlas written: %s (%d tiles)" % [OUTPUT_PATH, SOURCE_FILES.size()])
	quit(0)
