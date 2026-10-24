class_name Pathfinder
extends RefCounted
## Finds paths on a map's cell grid.
##
## EIGHT_WAY (exploration): steps along the grid and diagonally, but never across the
## corner of an obstacle, so the character does not cut through rocks.
## FOUR_WAY (kept for combat, decided in M3): grid steps only, one movement point per step.

enum Movement { FOUR_WAY, EIGHT_WAY }

var _astar: AStarGrid2D = AStarGrid2D.new()
var _bounds: Rect2i


func _init(map: MapDef, movement: Movement = Movement.FOUR_WAY) -> void:
	_bounds = Rect2i(Vector2i.ZERO, map.size)
	_astar.region = _bounds
	_astar.cell_size = Vector2.ONE
	if movement == Movement.EIGHT_WAY:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	else:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	for cell: Vector2i in map.blocked_cells:
		if _bounds.has_point(cell):
			_astar.set_point_solid(cell, true)


## Cells from start to goal, both included. Empty if either end is outside the map or
## blocked, or if there is no route. A path from a cell to itself is just that cell.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not _is_free(start) or not _is_free(goal):
		return []
	if start == goal:
		return [start]
	return _astar.get_id_path(start, goal)


func _is_free(cell: Vector2i) -> bool:
	return _bounds.has_point(cell) and not _astar.is_point_solid(cell)
