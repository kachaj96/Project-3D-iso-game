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


## The cell that contains a pixel position. Points exactly on a border belong to the
## cell with the higher coordinates.
func pixel_to_cell(pixel: Vector2) -> Vector2i:
	var a: float = pixel.x / (tile_width / 2.0) - 1.0
	var b: float = pixel.y / (tile_height / 2.0) - 1.0
	return Vector2i(floori((a + b) / 2.0 + 0.5), floori((b - a) / 2.0 + 0.5))
