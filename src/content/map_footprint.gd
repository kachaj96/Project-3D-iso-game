class_name MapFootprint
extends RefCounted
## Where a building stands on the map picture. All sizes are project pixels (the size on screen
## at zoom 1; a map cell is 128 x 64). Pure geometry from the map file, no pictures.
##
## A building is the cells of one grid symbol (for example "B"). Its picture is painted on a canvas
## that is the footprint rectangle plus room around it: CLUSTER_MARGIN on the sides and below and
## CLUSTER_HEADROOM above for the roof. A tall object is drawn in vertical strips (STRIP_WIDTH wide),
## each sorted by the front edge of the footprint below it, so something standing in a gap in front
## of a recessed wall is drawn in front of that wall but behind the wings.

const CLUSTER_MARGIN: float = 32.0
const CLUSTER_HEADROOM: float = 120.0
const STRIP_WIDTH: float = 64.0
## Height of a building block, from MapBlockout.OBSTACLE_HEIGHT.
const BUILDING_HEIGHT: float = 160.0


## Ground centres of every cell of a symbol, in project pixels.
static func cell_centres(spec: MapSpec, symbol: String) -> Array[Vector2]:
	var centres: Array[Vector2] = []
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			if spec.symbol_at(row, col) == symbol:
				centres.append(MapLayout.pixel_center(row, col))
	return centres


## The rectangle that holds the footprint blocks of a symbol (walls up to BUILDING_HEIGHT).
## Empty rectangle when the symbol is not on the map.
static func cluster_rect(spec: MapSpec, symbol: String) -> Rect2:
	var centres: Array[Vector2] = cell_centres(spec, symbol)
	if centres.is_empty():
		return Rect2()
	var low: Vector2 = Vector2(INF, INF)
	var high: Vector2 = Vector2(-INF, -INF)
	for centre: Vector2 in centres:
		low = Vector2(minf(low.x, centre.x - 64.0), minf(low.y, centre.y - BUILDING_HEIGHT - 32.0))
		high = Vector2(maxf(high.x, centre.x + 64.0), maxf(high.y, centre.y + 32.0))
	return Rect2(low, high - low)


## The canvas the building picture is painted on: the cluster plus room for the roof.
static func canvas_rect(spec: MapSpec, symbol: String) -> Rect2:
	var cluster: Rect2 = cluster_rect(spec, symbol)
	if cluster.size == Vector2.ZERO:
		return cluster
	return Rect2(
		cluster.position - Vector2(CLUSTER_MARGIN, CLUSTER_HEADROOM),
		cluster.size + Vector2(2.0 * CLUSTER_MARGIN, CLUSTER_HEADROOM + CLUSTER_MARGIN)
	)


## The y of the front edge of the footprint at a given x: the lowest point of any cell of the
## symbol whose diamond covers that x. Negative infinity when no cell covers it.
static func front_y_at(spec: MapSpec, symbol: String, x: float) -> float:
	var front: float = -INF
	for centre: Vector2 in cell_centres(spec, symbol):
		var dx: float = absf(x - centre.x)
		if dx <= 64.0:
			front = maxf(front, centre.y + 32.0 - dx / 2.0)
	return front
