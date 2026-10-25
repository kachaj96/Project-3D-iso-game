class_name MapLayout
extends RefCounted
## The shape of a screen-shaped map (decision D-020) and the conversion between its rows and
## columns (how a map is written in a text file) and the diamond cells (x, y) the game uses.
##
## A map has `rows` rows of cells. Even rows (0, 2, 4...) hold `columns` cells. Odd rows hold
## `columns - 1` cells and sit half a cell further right, so the map is exactly
## columns * 128 px wide and rows * 32 + 32 px high (10 x 20 cells is 1280 x 672 px).
## Row 0 is the top of the screen, column 0 the left.

const MAX_COLUMNS: int = 64
const MAX_ROWS: int = 128


## How many cells a row holds.
static func row_length(columns: int, row: int) -> int:
	return columns if row % 2 == 0 else columns - 1


## The number of cells of the whole map.
static func cell_count(columns: int, rows: int) -> int:
	var total: int = 0
	for row: int in rows:
		total += row_length(columns, row)
	return total


## The isometric cell (x, y) of a row and column. Some cells have a negative y.
static func cell_from_row_col(row: int, col: int) -> Vector2i:
	var odd: int = row % 2
	@warning_ignore("integer_division")
	return Vector2i((row + 2 * col + odd) / 2, (row - 2 * col - odd) / 2)


## The inverse: x is the row, y is the column of the returned vector (row, col).
static func row_col_from_cell(cell: Vector2i) -> Vector2i:
	var row: int = cell.x + cell.y
	var odd: int = posmod(row, 2)
	@warning_ignore("integer_division")
	return Vector2i(row, (cell.x - cell.y - odd) / 2)


## True when the row and column exist in a map of this size.
static func has_row_col(columns: int, rows: int, row: int, col: int) -> bool:
	return row >= 0 and row < rows and col >= 0 and col < row_length(columns, row)


## True when the isometric cell belongs to a map of this size.
static func contains(columns: int, rows: int, cell: Vector2i) -> bool:
	var row_col: Vector2i = row_col_from_cell(cell)
	return has_row_col(columns, rows, row_col.x, row_col.y)


## Every cell of the map, row by row from the top left.
static func all_cells(columns: int, rows: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row: int in rows:
		for col: int in row_length(columns, row):
			cells.append(cell_from_row_col(row, col))
	return cells


## Pixel position of the centre of a cell, with the map's top left corner at (0, 0).
static func pixel_center(row: int, col: int) -> Vector2:
	return Vector2(
		col * GridMath.DEFAULT_TILE_WIDTH + GridMath.DEFAULT_TILE_WIDTH / 2.0 + (row % 2) * GridMath.DEFAULT_TILE_WIDTH / 2.0,
		row * GridMath.DEFAULT_TILE_HEIGHT / 2.0 + GridMath.DEFAULT_TILE_HEIGHT / 2.0
	)


## Size of the whole map picture in pixels.
static func pixel_size(columns: int, rows: int) -> Vector2:
	return Vector2(
		columns * GridMath.DEFAULT_TILE_WIDTH,
		rows * GridMath.DEFAULT_TILE_HEIGHT / 2.0 + GridMath.DEFAULT_TILE_HEIGHT / 2.0
	)


## The screen edges a cell touches: any of "top", "bottom", "left", "right". A cell in a
## corner touches two. Exits to neighbouring maps may only sit on one edge.
static func edges_of(columns: int, rows: int, row: int, col: int) -> Array[String]:
	var edges: Array[String] = []
	if row == 0:
		edges.append("top")
	if row == rows - 1:
		edges.append("bottom")
	if col == 0:
		edges.append("left")
	if col == row_length(columns, row) - 1:
		edges.append("right")
	return edges
