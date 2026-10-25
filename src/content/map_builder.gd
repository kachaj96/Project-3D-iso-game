class_name MapBuilder
extends RefCounted
## Turns a parsed map file (MapSpec) into game data (MapDef). Pure logic, no files and no
## nodes. Exits to other maps need the other maps' files, so `build` gets all specs of the
## world, keyed by map id. Check `errors` after `build`; `map` is only usable without errors.
##
## What the text symbols become:
##   # T B ~            blocked cells
##   S, L               stairs and ladder cells (the level is the lower end, from `heights:`)
##   digit with a prop  a prop on a blocked cell
##   digit with a link  a door, stairs or ladder exit to another map
##   >                  an edge exit, one exit per cell. It leads to the neighbouring map named
##                      by the coordinates in the id (D-019): the left edge to column - 1, the
##                      right edge to column + 1, the top edge to row - 1, the bottom edge to
##                      row + 1, in the same region. It arrives one step inward from the `>` on
##                      the opposite edge of the neighbour, at the same row (left and right
##                      edges) or the same column (top and bottom edges).

const BLOCKING_SYMBOLS: String = "#TB~CWVX"
const COORDINATE_ID_PATTERN: String = "^map\\.([a-z0-9_]+)\\.(\\d{2})_(\\d{2})$"

var map: MapDef
var errors: Array[String] = []


static func build(spec: MapSpec, specs: Dictionary) -> MapBuilder:
	var builder: MapBuilder = MapBuilder.new()
	builder._build(spec, specs)
	return builder


func is_valid() -> bool:
	return errors.is_empty()


func _build(spec: MapSpec, specs: Dictionary) -> void:
	map = MapDef.new()
	map.id = spec.id
	map.region = spec.region
	map.theme = spec.theme
	map.shape = MapDef.Shape.SCREEN
	map.size = Vector2i(spec.columns, spec.rows)
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			_read_cell(spec, row, col)
	_add_props(spec)
	_add_links(spec, specs)
	_add_edge_exits(spec, specs)


func _read_cell(spec: MapSpec, row: int, col: int) -> void:
	var cell: Vector2i = MapLayout.cell_from_row_col(row, col)
	var symbol: String = spec.symbol_at(row, col)
	if symbol == "@":
		map.spawn_cell = cell
	elif BLOCKING_SYMBOLS.contains(symbol):
		map.blocked_cells.append(cell)
	elif symbol == "S":
		map.cell_kinds[cell] = LevelRules.KIND_STAIRS
	elif symbol == "L":
		map.cell_kinds[cell] = LevelRules.KIND_LADDER
	var level: int = spec.height_at(row, col)
	if level != 0:
		map.heights[cell] = level


func _add_props(spec: MapSpec) -> void:
	for declared: Dictionary in spec.props:
		var where: Array[Vector2i] = spec.find_symbol(declared["marker"] as String)
		var prop: MapProp = MapProp.new()
		prop.id = declared["id"]
		prop.kind = declared["kind"]
		prop.cell = MapLayout.cell_from_row_col(where[0].x, where[0].y)
		prop.text_key = declared["text_key"]
		map.props.append(prop)
		map.blocked_cells.append(prop.cell)


func _add_links(spec: MapSpec, specs: Dictionary) -> void:
	for link: Dictionary in spec.links:
		var where: Array[Vector2i] = spec.find_symbol(link["marker"] as String)
		var target: MapSpec = specs.get(link["target_map_id"])
		if target == null:
			errors.append("%s: link %s leads to unknown map '%s'" % [spec.id, link["marker"], link["target_map_id"]])
			continue
		var entry: Variant = _entry_cell(target, link["entry"] as String)
		if entry == null:
			errors.append("%s: link %s leads to unknown entry '%s' in %s" % [spec.id, link["marker"], link["entry"], target.id])
			continue
		var exit: MapExit = MapExit.new()
		exit.kind = link["kind"]
		exit.cells = [MapLayout.cell_from_row_col(where[0].x, where[0].y)]
		exit.target_map_id = target.id
		exit.target_entry_cell = entry
		map.exits.append(exit)


func _add_edge_exits(spec: MapSpec, specs: Dictionary) -> void:
	for where: Vector2i in spec.find_symbol(">"):
		var edge: String = MapLayout.edges_of(spec.columns, spec.rows, where.x, where.y)[0]
		var target_id: String = neighbour_id(spec.id, edge)
		if target_id.is_empty():
			errors.append("%s: the exit at row %d column %d needs an id like map.region.04_07 to find its neighbour" % [spec.id, where.x, where.y])
			continue
		var target: MapSpec = specs.get(target_id)
		if target == null:
			errors.append("%s: the %s edge leads to %s, which does not exist (use '.' for edges that lead nowhere yet)" % [spec.id, edge, target_id])
			continue
		var entry: Variant = _edge_entry(target, edge, where)
		if entry == null:
			errors.append("%s: the exit at row %d column %d has no matching '>' on the opposite edge of %s" % [spec.id, where.x, where.y, target_id])
			continue
		var exit: MapExit = MapExit.new()
		exit.kind = "edge"
		exit.cells = [MapLayout.cell_from_row_col(where.x, where.y)]
		exit.target_map_id = target_id
		exit.target_entry_cell = entry
		map.exits.append(exit)


## The cell of a named entry of a map, or null.
func _entry_cell(spec: MapSpec, entry_name: String) -> Variant:
	for entry: Dictionary in spec.entries:
		if entry["name"] == entry_name:
			return MapLayout.cell_from_row_col(entry["row"] as int, entry["col"] as int)
	return null


## The id of the neighbouring map across an edge, or "" when the id has no coordinates.
static func neighbour_id(map_id: String, edge: String) -> String:
	var found: RegExMatch = RegEx.create_from_string(COORDINATE_ID_PATTERN).search(map_id)
	if found == null:
		return ""
	var column: int = int(found.get_string(2))
	var row: int = int(found.get_string(3))
	match edge:
		"left":
			column -= 1
		"right":
			column += 1
		"top":
			row -= 1
		"bottom":
			row += 1
	if column < 0 or row < 0:
		return ""
	return "map.%s.%02d_%02d" % [found.get_string(1), column, row]


## Where a character arrives in `target` after leaving `spec` through the `>` at `where`
## (row, column) on `edge`: one step inward from the matching `>` on the opposite edge.
## Null when there is no such `>` or no walkable cell inward from it.
static func _edge_entry(target: MapSpec, edge: String, where: Vector2i) -> Variant:
	var opposite: Vector2i
	var inward: Vector2i
	match edge:
		"left":
			opposite = Vector2i(where.x, MapLayout.row_length(target.columns, where.x) - 1)
			inward = Vector2i(opposite.x, opposite.y - 1)
		"right":
			opposite = Vector2i(where.x, 0)
			inward = Vector2i(opposite.x, 1)
		"top":
			opposite = Vector2i(target.rows - 1, where.y)
			inward = Vector2i(opposite.x - 2, opposite.y)
		_:
			opposite = Vector2i(0, where.y)
			inward = Vector2i(2, opposite.y)
	if not MapLayout.has_row_col(target.columns, target.rows, opposite.x, opposite.y):
		return null
	if target.symbol_at(opposite.x, opposite.y) != ">":
		return null
	if not MapLayout.has_row_col(target.columns, target.rows, inward.x, inward.y) or not target.is_walkable(inward.x, inward.y) or target.symbol_at(inward.x, inward.y) == ">":
		return null
	return MapLayout.cell_from_row_col(inward.x, inward.y)
