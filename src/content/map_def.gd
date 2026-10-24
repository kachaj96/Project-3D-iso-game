class_name MapDef
extends Resource
## Static description of one map screen. Pure data: the cell grid used by exploration
## (and later by combat). The painted TileMapLayer must match blocked_cells.

const ID_PATTERN: String = "^map(\\.[a-z0-9_]+)+$"

@export var id: String = ""
@export var region: String = ""
@export var size: Vector2i = Vector2i(12, 12)
## Where a new character appears on this map.
@export var spawn_cell: Vector2i = Vector2i.ZERO
@export var blocked_cells: Array[Vector2i] = []
@export var exits: Array[MapExit] = []
@export var props: Array[MapProp] = []


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


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
	if not is_in_bounds(spawn_cell) or is_blocked(spawn_cell):
		problems.append("%s: spawn_cell %s is outside the map or blocked" % [id, spawn_cell])
	for cell: Vector2i in blocked_cells:
		if not is_in_bounds(cell):
			problems.append("%s: blocked cell %s is outside the map" % [id, cell])
	for exit: MapExit in exits:
		if exit.cells.is_empty():
			problems.append("%s: exit to %s has no cells" % [id, exit.target_map_id])
		for cell: Vector2i in exit.cells:
			if not is_in_bounds(cell) or is_blocked(cell):
				problems.append("%s: exit cell %s is outside the map or blocked" % [id, cell])
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
	return problems


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
