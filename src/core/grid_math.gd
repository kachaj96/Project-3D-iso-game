class_name GridMath
extends RefCounted
## Converts between isometric cell coordinates and pixel positions (2:1 diamond grid).
## Game logic uses cells only. Pixels exist only for presentation and input.
##
## Matches Godot's isometric "diamond down" TileMapLayer exactly (checked by a test): the
## top vertex of cell (0, 0) is at pixel (0, 0), so its centre is at (tile_width / 2,
## tile_height / 2). Cell (1, 0) is down-right of it, cell (0, 1) is down-left.

const DEFAULT_TILE_WIDTH: int = 128
const DEFAULT_TILE_HEIGHT: int = 64

## One level of a map is this many pixels high on screen (D-020).
const LEVEL_HEIGHT: int = 32

var tile_width: int
var tile_height: int


func _init(width: int = DEFAULT_TILE_WIDTH, height: int = DEFAULT_TILE_HEIGHT) -> void:
	assert(width > 0 and height > 0, "tile size must be positive")
	tile_width = width
	tile_height = height


## Pixel position of the centre of a cell.
func cell_to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y + 1) * tile_width / 2.0,
		(cell.x + cell.y + 1) * tile_height / 2.0
	)


## The rectangle in pixels that holds the whole diamond-shaped map of the given size in
## cells: from the top vertex of cell (0, 0) to the bottom vertex of the last cell.
func map_pixel_bounds(map_size: Vector2i) -> Rect2:
	return Rect2(
		-(map_size.y - 1) * tile_width / 2.0,
		0.0,
		(map_size.x + map_size.y) * tile_width / 2.0,
		(map_size.x + map_size.y) * tile_height / 2.0
	)


## The cell that contains a pixel position. Points exactly on a border belong to the
## cell with the higher coordinates.
func pixel_to_cell(pixel: Vector2) -> Vector2i:
	var a: float = pixel.x / (tile_width / 2.0) - 1.0
	var b: float = pixel.y / (tile_height / 2.0) - 1.0
	return Vector2i(floori((a + b) / 2.0 + 0.5), floori((b - a) / 2.0 + 0.5))


## How many pixels a cell on this level is drawn above the ground.
func level_lift(level: int) -> float:
	return float(level * LEVEL_HEIGHT)


## The cell a tap hits on a map with levels. The surface of a higher cell is drawn higher
## up, so the tap is tried from the highest level down and the first cell whose own level
## matches wins. A tap that hits no raised surface counts as a tap on the ground.
func pick_cell(pixel: Vector2, map: MapDef) -> Vector2i:
	var top_level: int = 0
	for level: int in map.heights.values():
		top_level = maxi(top_level, level)
	for level: int in range(top_level, 0, -1):
		var candidate: Vector2i = pixel_to_cell(pixel + Vector2(0.0, level_lift(level)))
		if map.is_in_bounds(candidate) and map.height_at(candidate) == level:
			return candidate
	return pixel_to_cell(pixel)
