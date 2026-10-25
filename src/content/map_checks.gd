class_name MapChecks
extends RefCounted
## Checks on finished maps that the parser and the builder cannot do alone (D-020, MAP_FORMAT
## 2.6). Errors stop the generator. Warnings are shown but do not stop it. Pure logic.

## The platform walls are sampled every this many pixels when looking for hidden cells.
const SAMPLE_STEP: int = 4


## Errors for one map: every walkable cell must be reachable from the spawn (the same way
## the character walks: eight directions, levels, stairs and ladders).
static func unreachable_cells(map: MapDef) -> Array[String]:
	var errors: Array[String] = []
	var finder: Pathfinder = Pathfinder.new(map, Pathfinder.Movement.EIGHT_WAY)
	for cell: Vector2i in map.all_cells():
		if not map.is_blocked(cell) and finder.find_path(map.spawn_cell, cell).is_empty():
			var row_col: Vector2i = MapLayout.row_col_from_cell(cell)
			errors.append("%s: the walkable cell at row %d column %d cannot be reached from the spawn" % [map.id, row_col.x, row_col.y])
	return errors


## Errors for one map: every text key must exist in every given language. `keys_by_language`
## maps a language to the keys it has. `keys` are the keys the map uses.
static func missing_translations(map_id: String, keys: Array[String], keys_by_language: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key: String in keys:
		for language: String in keys_by_language:
			if not (keys_by_language[language] as Array).has(key):
				errors.append("%s: the text key '%s' is missing in '%s'" % [map_id, key, language])
	return errors


## Warnings for one map: walkable cells that a higher platform in front of them hides on
## screen. A hidden place needs the platform to fade out or an occluder (MAP_FORMAT 2.3).
static func hidden_cells(map: MapDef) -> Array[String]:
	var warnings: Array[String] = []
	var grid: GridMath = GridMath.new()
	var platforms: Array[Vector2i] = []
	for cell: Vector2i in map.heights:
		if map.height_at(cell) > 0 and map.is_in_bounds(cell):
			platforms.append(cell)
	for cell: Vector2i in map.all_cells():
		if map.is_blocked(cell):
			continue
		var centre: Vector2 = grid.cell_to_pixel(cell) - Vector2(0.0, grid.level_lift(map.height_at(cell)))
		for platform: Vector2i in platforms:
			if _hides(grid, map, platform, cell, centre):
				var row_col: Vector2i = MapLayout.row_col_from_cell(cell)
				warnings.append("%s: the walkable cell at row %d column %d is hidden behind the platform at %s" % [map.id, row_col.x, row_col.y, platform])
				break
	return warnings


## Every problem of a set of maps (Dictionary of id -> MapDef): each map valid and reachable,
## every exit leads somewhere real.
static func check_set(maps: Dictionary) -> Array[String]:
	var errors: Array[String] = MapDef.validate_set(maps)
	for map_id: String in maps:
		errors.append_array(unreachable_cells(maps[map_id] as MapDef))
	return errors


## True when the wall of `platform` (a prism from the ground up to its level) is drawn in
## front of the point `centre` and covers it.
static func _hides(grid: GridMath, map: MapDef, platform: Vector2i, cell: Vector2i, centre: Vector2) -> bool:
	if map.height_at(platform) <= map.height_at(cell) or platform == cell:
		return false
	var ground: Vector2 = grid.cell_to_pixel(platform)
	if ground.y <= grid.cell_to_pixel(cell).y:
		return false
	for lift: int in range(0, map.height_at(platform) * GridMath.LEVEL_HEIGHT + 1, SAMPLE_STEP):
		if grid.pixel_to_cell(centre + Vector2(0.0, lift)) == platform:
			return true
	return false
