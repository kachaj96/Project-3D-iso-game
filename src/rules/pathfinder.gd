class_name Pathfinder
extends RefCounted
## Finds paths on a map's cell grid.
##
## One graph point per walkable cell and one connection per allowed step. Which steps are
## allowed is decided by MapDef.can_step (obstacles, corner cutting, levels, stairs and
## ladders), so this class only builds the graph and asks the A* search for the route.
##
## EIGHT_WAY (exploration): steps along the grid and diagonally, but never across the
## corner of an obstacle, so the character does not cut through rocks.
## FOUR_WAY (kept for combat, decided in M3): grid steps only, one movement point per step.
##
## Ladders cost more than stairs (LevelRules.WEIGHT), so a route prefers stairs and takes a
## ladder only when it is much shorter or the only way. The graph is built once from the map,
## which must not change afterwards.

enum Movement { FOUR_WAY, EIGHT_WAY }

const ORTHOGONAL: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
const DIAGONAL: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1)]

var _astar: AStar2D = AStar2D.new()
var _ids: Dictionary[Vector2i, int] = {}


func _init(map: MapDef, movement: Movement = Movement.FOUR_WAY) -> void:
	var cells: Array[Vector2i] = map.all_cells()
	for cell: Vector2i in cells:
		if map.is_blocked(cell):
			continue
		var id: int = _ids.size()
		_ids[cell] = id
		_astar.add_point(id, Vector2(cell), LevelRules.weight(map.kind_at(cell)))
	# Each pair is tested once, looking "forward" from the cell; the connection works both ways.
	var offsets: Array[Vector2i] = ORTHOGONAL.duplicate()
	if movement == Movement.EIGHT_WAY:
		offsets.append_array(DIAGONAL)
	for cell: Vector2i in _ids:
		for offset: Vector2i in offsets:
			var neighbour: Vector2i = cell + offset
			if _ids.has(neighbour) and map.can_step(cell, neighbour):
				_astar.connect_points(_ids[cell], _ids[neighbour], true)


## Cells from start to goal, both included. Empty if either end is outside the map or
## blocked, or if there is no route. A path from a cell to itself is just that cell.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not _ids.has(start) or not _ids.has(goal):
		return []
	if start == goal:
		return [start]
	var path: Array[Vector2i] = []
	for point: Vector2 in _astar.get_point_path(_ids[start], _ids[goal]):
		path.append(Vector2i(point))
	return path
