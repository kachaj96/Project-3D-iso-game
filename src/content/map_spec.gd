class_name MapSpec
extends RefCounted
## One map as written by a person in a text file (format in docs/MAP_FORMAT.md). Parsing only
## reads and checks the file; it never builds game data. Check `errors` after `parse`.
##
## Example (shortened, spaces inside rows are ignored so odd rows can be indented):
##   id: map.hollow.04_07
##   region: hollow
##   title_key: map.hollow.04_07.title
##   size: 4x3
##   grid:
##   . . = .
##    . = T
##   . > = .
##   markers:
##   1 prop sign prop.hollow.04_07.sign sign.hollow.04_07.sign
##   2 link door map.hollow.04_07.in01 front_door
##   entries:
##   from_inside 1 1

## X is void: solid and invisible (the black outside an interior room).
## C is a low object (a coffin, an altar), W and V are tall wall pieces. All three are solid and get their own picture (see MapFootprint).
const GROUND_SYMBOLS: String = ".,=@>#TB~SLCWVX"
const WALKABLE_SYMBOLS: String = ".,=@>SL"
const MAX_HEIGHT: int = 7
const ID_PATTERN: String = "^map(\\.[a-z0-9_]+)+$"
const PROP_ID_PATTERN: String = "^prop(\\.[a-z0-9_]+)+$"
const NAME_PATTERN: String = "^[a-z][a-z0-9_]*$"
const LINK_KINDS: Array[String] = ["door", "stairs", "ladder"]
const SECTIONS: Array[String] = ["grid:", "heights:", "markers:", "entries:", "lights:"]
## The mood of a map: the prompts and the darkness of the scene follow it.
const THEMES: Array[String] = ["forest", "dark_interior"]
const LIGHT_KINDS: Array[String] = ["torch"]

var id: String = ""
var region: String = ""
var title_key: String = ""
## "forest" (default) or "dark_interior".
var theme: String = "forest"
var columns: int = 0
var rows: int = 0
## One string per row, spaces removed.
var grid: Array[String] = []
## One string of digits 0 to 7 per row. Empty when the file has no heights section.
var heights: Array[String] = []
## {"marker", "kind", "id", "text_key"}
var props: Array[Dictionary] = []
## {"marker", "kind", "target_map_id", "entry"}
var links: Array[Dictionary] = []
## {"name", "row", "col"}: where a character appears when it arrives from another map
var entries: Array[Dictionary] = []
## {"kind", "row", "col"}: lights that stand on or beside a cell (a torch on a wall)
var lights: Array[Dictionary] = []
var errors: Array[String] = []


static func parse(text: String) -> MapSpec:
	var spec: MapSpec = MapSpec.new()
	spec._read(text)
	if spec.errors.is_empty():
		spec._check()
	return spec


func is_valid() -> bool:
	return errors.is_empty()


## The symbol of a cell: one of GROUND_SYMBOLS or a marker digit "1" to "9".
func symbol_at(row: int, col: int) -> String:
	return grid[row][col]


## Height level of a cell, 0 when the file has no heights.
func height_at(row: int, col: int) -> int:
	if heights.is_empty():
		return 0
	return int(heights[row][col])


func is_walkable(row: int, col: int) -> bool:
	var symbol: String = symbol_at(row, col)
	if WALKABLE_SYMBOLS.contains(symbol):
		return true
	return symbol.is_valid_int() and not links.filter(func(link: Dictionary) -> bool: return link["marker"] == symbol).is_empty()


## Every (row, col) that holds this symbol, as Vector2i(row, col), row by row.
func find_symbol(symbol: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for row: int in grid.size():
		for col: int in grid[row].length():
			if grid[row][col] == symbol:
				found.append(Vector2i(row, col))
	return found


func _error(line_number: int, message: String) -> void:
	errors.append("line %d: %s" % [line_number, message] if line_number > 0 else message)


func _read(text: String) -> void:
	var section: String = "header"
	var line_number: int = 0
	for raw: String in text.split("\n"):
		line_number += 1
		var line: String = raw.strip_edges()
		if line.is_empty() or line.begins_with("//"):
			continue
		if SECTIONS.has(line):
			section = line.trim_suffix(":")
			continue
		match section:
			"header":
				_read_header(line, line_number)
			"grid":
				grid.append(line.replace(" ", "").replace("\t", ""))
			"heights":
				heights.append(line.replace(" ", "").replace("\t", ""))
			"markers":
				_read_marker(line, line_number)
			"entries":
				_read_entry(line, line_number)
			"lights":
				_read_light(line, line_number)


func _read_header(line: String, line_number: int) -> void:
	var colon: int = line.find(":")
	if colon < 0:
		_error(line_number, "expected 'key: value' or a section name, got '%s'" % line)
		return
	var key: String = line.substr(0, colon).strip_edges()
	var value: String = line.substr(colon + 1).strip_edges()
	match key:
		"id":
			id = value
		"region":
			region = value
		"title_key":
			title_key = value
		"theme":
			theme = value
		"size":
			var parts: PackedStringArray = value.split("x")
			if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				_error(line_number, "size must look like 10x20 (columns x rows), got '%s'" % value)
			else:
				columns = int(parts[0])
				rows = int(parts[1])
		_:
			_error(line_number, "unknown key '%s'" % key)


func _read_marker(line: String, line_number: int) -> void:
	var tokens: PackedStringArray = line.split(" ", false)
	if tokens.size() < 2 or tokens[0].length() != 1 or not "123456789".contains(tokens[0]):
		_error(line_number, "a marker line starts with one digit from 1 to 9, got '%s'" % line)
		return
	var marker: String = tokens[0]
	if _marker_declared(marker):
		_error(line_number, "marker %s is declared twice" % marker)
		return
	if tokens[1] == "prop" and tokens.size() == 5:
		props.append({"marker": marker, "kind": tokens[2], "id": tokens[3], "text_key": tokens[4]})
	elif tokens[1] == "link" and tokens.size() == 5:
		links.append({"marker": marker, "kind": tokens[2], "target_map_id": tokens[3], "entry": tokens[4]})
	else:
		_error(line_number, "expected '%s prop <kind> <prop id> <text key>' or '%s link <kind> <target map id> <entry name>'" % [marker, marker])


func _read_entry(line: String, line_number: int) -> void:
	var tokens: PackedStringArray = line.split(" ", false)
	if tokens.size() != 3 or not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
		_error(line_number, "an entry line looks like '<name> <row> <column>', got '%s'" % line)
		return
	entries.append({"name": tokens[0], "row": int(tokens[1]), "col": int(tokens[2])})


func _read_light(line: String, line_number: int) -> void:
	var tokens: PackedStringArray = line.split(" ", false)
	if tokens.size() != 3 or not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
		_error(line_number, "a light line looks like '<kind> <row> <column>', got '%s'" % line)
		return
	lights.append({"kind": tokens[0], "row": int(tokens[1]), "col": int(tokens[2])})


func _marker_declared(marker: String) -> bool:
	for prop: Dictionary in props:
		if prop["marker"] == marker:
			return true
	for link: Dictionary in links:
		if link["marker"] == marker:
			return true
	return false


func _check() -> void:
	var id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)
	if id.is_empty():
		_error(0, "missing 'id'")
	elif id_regex.search(id) == null:
		_error(0, "invalid map id '%s'" % id)
	if region.is_empty():
		_error(0, "missing 'region'")
	elif RegEx.create_from_string(NAME_PATTERN).search(region) == null:
		_error(0, "invalid region '%s'" % region)
	if columns < 2 or columns > MapLayout.MAX_COLUMNS or rows < 1 or rows > MapLayout.MAX_ROWS:
		_error(0, "size must be 2 to %d columns and 1 to %d rows" % [MapLayout.MAX_COLUMNS, MapLayout.MAX_ROWS])
		return
	if not _check_shape(grid, "grid"):
		return
	if not heights.is_empty() and not _check_shape(heights, "heights"):
		return
	_check_symbols()
	_check_heights()
	_check_markers()
	_check_entries()
	_check_theme_and_lights()


## Number of rows and the length of every row.
func _check_shape(lines: Array[String], name: String) -> bool:
	if lines.size() != rows:
		_error(0, "%s has %d rows, size says %d" % [name, lines.size(), rows])
		return false
	var ok: bool = true
	for row: int in rows:
		var wanted: int = MapLayout.row_length(columns, row)
		if lines[row].length() != wanted:
			_error(0, "%s row %d has %d cells, expected %d" % [name, row, lines[row].length(), wanted])
			ok = false
	return ok


func _check_symbols() -> void:
	for row: int in rows:
		for col: int in grid[row].length():
			var symbol: String = grid[row][col]
			if not GROUND_SYMBOLS.contains(symbol) and not "123456789".contains(symbol):
				_error(0, "grid row %d column %d: unknown symbol '%s'" % [row, col, symbol])
	var spawns: int = find_symbol("@").size()
	if spawns != 1:
		_error(0, "the map needs exactly one spawn '@', found %d" % spawns)
	for cell: Vector2i in find_symbol(">"):
		var edges: Array[String] = MapLayout.edges_of(columns, rows, cell.x, cell.y)
		if edges.size() != 1:
			_error(0, "exit '>' at row %d column %d must sit on exactly one screen edge, it touches %d" % [cell.x, cell.y, edges.size()])


func _check_heights() -> void:
	for row: int in heights.size():
		for col: int in heights[row].length():
			var character: String = heights[row][col]
			if not character.is_valid_int() or int(character) > MAX_HEIGHT:
				_error(0, "heights row %d column %d: '%s' is not a level from 0 to %d" % [row, col, character, MAX_HEIGHT])


func _check_markers() -> void:
	var prop_id_regex: RegEx = RegEx.create_from_string(PROP_ID_PATTERN)
	var map_id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)
	var seen_prop_ids: Array[String] = []
	for prop: Dictionary in props:
		if not MapProp.KINDS.has(prop["kind"]):
			_error(0, "marker %s: unknown prop kind '%s'" % [prop["marker"], prop["kind"]])
		if prop_id_regex.search(prop["id"]) == null:
			_error(0, "marker %s: invalid prop id '%s'" % [prop["marker"], prop["id"]])
		if seen_prop_ids.has(prop["id"]):
			_error(0, "prop id '%s' is used twice" % prop["id"])
		seen_prop_ids.append(prop["id"])
	for link: Dictionary in links:
		if not LINK_KINDS.has(link["kind"]):
			_error(0, "marker %s: unknown link kind '%s'" % [link["marker"], link["kind"]])
		if map_id_regex.search(link["target_map_id"]) == null:
			_error(0, "marker %s: invalid target map id '%s'" % [link["marker"], link["target_map_id"]])
		if RegEx.create_from_string(NAME_PATTERN).search(link["entry"]) == null:
			_error(0, "marker %s: invalid entry name '%s'" % [link["marker"], link["entry"]])
	for digit: String in "123456789":
		var used: int = find_symbol(digit).size()
		if _marker_declared(digit) and used != 1:
			_error(0, "marker %s is declared but appears %d times in the grid, it must appear once" % [digit, used])
		elif not _marker_declared(digit) and used > 0:
			_error(0, "marker %s is in the grid but not declared under 'markers:'" % digit)


func _check_entries() -> void:
	var names: Array[String] = []
	for entry: Dictionary in entries:
		if RegEx.create_from_string(NAME_PATTERN).search(entry["name"]) == null:
			_error(0, "invalid entry name '%s'" % entry["name"])
		if names.has(entry["name"]):
			_error(0, "entry '%s' is declared twice" % entry["name"])
		names.append(entry["name"])
		if not MapLayout.has_row_col(columns, rows, entry["row"], entry["col"]):
			_error(0, "entry '%s' at row %d column %d is outside the map" % [entry["name"], entry["row"], entry["col"]])
		elif not is_walkable(entry["row"], entry["col"]):
			_error(0, "entry '%s' must stand on a walkable cell" % entry["name"])


func _check_theme_and_lights() -> void:
	if not THEMES.has(theme):
		_error(0, "unknown theme '%s', allowed: %s" % [theme, ", ".join(THEMES)])
	for light: Dictionary in lights:
		if not LIGHT_KINDS.has(light["kind"]):
			_error(0, "unknown light kind '%s'" % light["kind"])
		if not MapLayout.has_row_col(columns, rows, light["row"] as int, light["col"] as int):
			_error(0, "light '%s' at row %d column %d is outside the map" % [light["kind"], light["row"], light["col"]])
