class_name MapDef
extends Resource
## Static description of one map screen. Pure data: the cell grid used by exploration
## (and later by combat). The painted TileMapLayer must match blocked_cells.
##
## The data must not change while the game runs: anything that changes (a bridge repaired)
## lives in WorldState. The path finder and the Authority keep what they computed from it.

const ID_PATTERN: String = "^map(\\.[a-z0-9_]+)+$"

## DIAMOND: a diamond of size.x by size.y cells (x 0..size.x-1, y 0..size.y-1), the first
## maps of Milestone 1. SCREEN: a screen-shaped rectangle of size.x columns by size.y rows
## (see MapLayout). DIAMOND goes away when the start maps are rewritten as text files.
enum Shape { DIAMOND, SCREEN }

const EXIT_KINDS: Array[String] = ["edge", "door", "stairs", "ladder"]

@export var id: String = ""
@export var region: String = ""
## The mood of the map ("forest", "dark_interior"), from the map file. The scene darkens itself by it.
@export var theme: String = "forest"
@export var shape: Shape = Shape.DIAMOND
@export var size: Vector2i = Vector2i(12, 12)
## Where a new character appears on this map.
@export var spawn_cell: Vector2i = Vector2i.ZERO
@export var blocked_cells: Array[Vector2i] = []
## Level of a cell, 0 to 7 (32 px each). Cells that are not listed have level 0.
@export var heights: Dictionary[Vector2i, int] = {}
## "stairs" or "ladder" for the cells that climb. A climbing cell has the level of its lower end.
@export var cell_kinds: Dictionary[Vector2i, String] = {}
@export var exits: Array[MapExit] = []
@export var props: Array[MapProp] = []


func is_in_bounds(cell: Vector2i) -> bool:
	if shape == Shape.SCREEN:
		return MapLayout.contains(size.x, size.y, cell)
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


## Inside the map and not an obstacle.
func is_walkable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not is_blocked(cell)


## Every cell of the map. For SCREEN maps row by row from the top left.
func all_cells() -> Array[Vector2i]:
	if shape == Shape.SCREEN:
		return MapLayout.all_cells(size.x, size.y)
	var cells: Array[Vector2i] = []
	for x: int in size.x:
		for y: int in size.y:
			cells.append(Vector2i(x, y))
	return cells


func height_at(cell: Vector2i) -> int:
	return heights.get(cell, 0)


## "", "stairs" or "ladder".
func kind_at(cell: Vector2i) -> String:
	return cell_kinds.get(cell, "")


## True when a character may step from a cell to a neighbouring cell (including the diagonal
## neighbours). Both cells must be walkable. A diagonal step may not cut the corner of an
## obstacle or of a higher cell (the wall of a platform): both cells beside the step must
## be free and no higher than the step. A lower cell beside the step (the edge of a drop) is
## fine, and a cell outside the map does not count, because on a screen-shaped map a step
## along the top or bottom row is a diagonal step too. Changes of level follow LevelRules.
func can_step(from: Vector2i, to: Vector2i) -> bool:
	if not is_walkable(from) or not is_walkable(to):
		return false
	var diagonal: bool = from.x != to.x and from.y != to.y
	if diagonal and (_blocks_corner(Vector2i(from.x, to.y), from) or _blocks_corner(Vector2i(to.x, from.y), from)):
		return false
	return LevelRules.can_step(height_at(from), kind_at(from), height_at(to), kind_at(to), diagonal)


## A cell beside a diagonal step blocks it when it is an obstacle or stands higher than the
## step. A diagonal step never changes level, so `from` gives the level of the whole step.
func _blocks_corner(side: Vector2i, from: Vector2i) -> bool:
	return is_blocked(side) or height_at(side) > height_at(from)


## The exit that contains this cell, or null.
func find_exit_at(cell: Vector2i) -> MapExit:
	for exit: MapExit in exits:
		if exit.cells.has(cell):
			return exit
	return null


## The prop standing on this cell, or null.
func find_prop_at(cell: Vector2i) -> MapProp:
	for prop: MapProp in props:
		if prop.cell == cell:
			return prop
	return null


## Problems found in this map alone. Empty array means valid.
func validate() -> Array[String]:
	var problems: Array[String] = []
	var regex: RegEx = RegEx.create_from_string(ID_PATTERN)
	if regex.search(id) == null:
		problems.append("invalid map id '%s'" % id)
	if size.x <= 0 or size.y <= 0:
		problems.append("%s: size must be positive" % id)
	elif shape == Shape.SCREEN and (size.x < 2 or size.x > MapLayout.MAX_COLUMNS or size.y > MapLayout.MAX_ROWS):
		problems.append("%s: a screen map has 2 to %d columns and at most %d rows" % [id, MapLayout.MAX_COLUMNS, MapLayout.MAX_ROWS])
	if not is_in_bounds(spawn_cell) or is_blocked(spawn_cell):
		problems.append("%s: spawn_cell %s is outside the map or blocked" % [id, spawn_cell])
	for cell: Vector2i in blocked_cells:
		if not is_in_bounds(cell):
			problems.append("%s: blocked cell %s is outside the map" % [id, cell])
	for exit: MapExit in exits:
		if exit.cells.is_empty():
			problems.append("%s: exit to %s has no cells" % [id, exit.target_map_id])
		if not EXIT_KINDS.has(exit.kind):
			problems.append("%s: exit to %s has unknown kind '%s'" % [id, exit.target_map_id, exit.kind])
		for cell: Vector2i in exit.cells:
			if not is_in_bounds(cell) or is_blocked(cell):
				problems.append("%s: exit cell %s is outside the map or blocked" % [id, cell])
	_validate_props(problems)
	_validate_levels(problems)
	return problems


func _validate_props(problems: Array[String]) -> void:
	var prop_regex: RegEx = RegEx.create_from_string(MapProp.ID_PATTERN)
	var seen_prop_ids: Array[String] = []
	for prop: MapProp in props:
		if prop_regex.search(prop.id) == null:
			problems.append("%s: invalid prop id '%s'" % [id, prop.id])
		if seen_prop_ids.has(prop.id):
			problems.append("%s: prop id '%s' is used twice" % [id, prop.id])
		seen_prop_ids.append(prop.id)
		if not is_in_bounds(prop.cell) or not is_blocked(prop.cell):
			problems.append("%s: prop %s must stand on a blocked cell inside the map" % [id, prop.id])
		if find_exit_at(prop.cell) != null:
			problems.append("%s: prop %s stands on an exit cell" % [id, prop.id])
		if not MapProp.KINDS.has(prop.kind):
			problems.append("%s: prop %s has unknown kind '%s'" % [id, prop.id, prop.kind])
		if prop.text_key.is_empty():
			problems.append("%s: prop %s has no text key" % [id, prop.id])


## Levels, stairs and ladders: every level is 0 to 7 and inside the map, and every stairs or
## ladder cell leads up to exactly one neighbour (one of the four cells beside it, because a
## diagonal step never changes level).
func _validate_levels(problems: Array[String]) -> void:
	for cell: Vector2i in heights:
		if not is_in_bounds(cell):
			problems.append("%s: height given for cell %s outside the map" % [id, cell])
		if heights[cell] < 0 or heights[cell] > LevelRules.MAX_LEVEL:
			problems.append("%s: cell %s has level %d, allowed 0 to %d" % [id, cell, heights[cell], LevelRules.MAX_LEVEL])
	for cell: Vector2i in cell_kinds:
		var kind: String = cell_kinds[cell]
		if not LevelRules.is_climbing_kind(kind):
			problems.append("%s: cell %s has unknown kind '%s'" % [id, cell, kind])
			continue
		if not is_walkable(cell):
			problems.append("%s: %s at %s is outside the map or blocked" % [id, kind, cell])
			continue
		var leads_up: int = 0
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbour: Vector2i = cell + offset
			var rise: int = height_at(neighbour) - height_at(cell)
			if is_walkable(neighbour) and rise >= 1 and rise <= LevelRules.max_rise(kind):
				leads_up += 1
		if leads_up != 1:
			problems.append("%s: %s at %s must lead up to exactly one neighbour, it leads to %d" % [id, kind, cell, leads_up])


## Problems across a set of maps (Dictionary of map id -> MapDef): every map is valid,
## every exit leads to an existing map and to a free cell inside it.
static func validate_set(maps: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for map_id: String in maps:
		var map: MapDef = maps[map_id]
		if map.id != map_id:
			problems.append("map registered as '%s' has id '%s'" % [map_id, map.id])
		problems.append_array(map.validate())
		for exit: MapExit in map.exits:
			if not maps.has(exit.target_map_id):
				problems.append("%s: exit leads to unknown map '%s'" % [map_id, exit.target_map_id])
				continue
			var target: MapDef = maps[exit.target_map_id]
			if not target.is_in_bounds(exit.target_entry_cell) or target.is_blocked(exit.target_entry_cell):
				problems.append("%s: entry cell %s in %s is outside the map or blocked" % [map_id, exit.target_entry_cell, target.id])
	return problems
