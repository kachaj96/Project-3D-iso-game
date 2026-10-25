class_name MapBuilderTest
extends GdUnitTestSuite

## Map A (column 0, row 0) and map B (column 1, row 0) are neighbours: the right edge of A
## meets the left edge of B at row 2. 4 columns, 4 rows (rows 0 and 2 hold 4 cells, rows 1
## and 3 hold 3).
const MAP_A: String = """
id: map.test.00_00
region: test
size: 4x4
grid:
. . = .
 . # 1
. @ = >
 . S .
heights:
0 0 0 0
 0 0 0
0 0 1 0
 0 0 0
markers:
1 prop sign prop.test.sign sign.test.sign
"""

const MAP_B: String = """
id: map.test.01_00
region: test
size: 4x4
grid:
. . . .
 . = 2
> @ = .
 . . .
heights:
0 0 0 0
 0 0 0
0 0 0 0
 0 0 0
markers:
2 link door map.test.00_00 from_b
entries:
from_a 2 1
"""

const MAP_A_WITH_ENTRY: String = MAP_A + "entries:\nfrom_b 0 1\n"


func _specs(a: String = MAP_A_WITH_ENTRY, b: String = MAP_B) -> Dictionary:
	var specs: Dictionary = {}
	for text: String in [a, b]:
		var spec: MapSpec = MapSpec.parse(text)
		assert_array(spec.errors).is_empty()
		specs[spec.id] = spec
	return specs


func _build(map_id: String, specs: Dictionary) -> MapBuilder:
	return MapBuilder.build(specs[map_id] as MapSpec, specs)


func _has_error(builder: MapBuilder, fragment: String) -> bool:
	for error: String in builder.errors:
		if error.contains(fragment):
			return true
	return false


func test_a_valid_map_builds_without_errors_and_passes_validation() -> void:
	var specs: Dictionary = _specs()
	var a: MapBuilder = _build("map.test.00_00", specs)
	var b: MapBuilder = _build("map.test.01_00", specs)
	assert_array(a.errors).is_empty()
	assert_array(b.errors).is_empty()
	assert_array(MapDef.validate_set({a.map.id: a.map, b.map.id: b.map})).is_empty()


func test_header_size_shape_and_spawn_are_copied() -> void:
	var map: MapDef = _build("map.test.00_00", _specs()).map
	assert_str(map.id).is_equal("map.test.00_00")
	assert_str(map.region).is_equal("test")
	assert_int(map.shape).is_equal(MapDef.Shape.SCREEN)
	assert_vector(map.size).is_equal(Vector2i(4, 4))
	assert_vector(map.spawn_cell).is_equal(MapLayout.cell_from_row_col(2, 1))


func test_solid_symbols_and_props_are_blocked() -> void:
	var map: MapDef = _build("map.test.00_00", _specs()).map
	assert_bool(map.is_blocked(MapLayout.cell_from_row_col(1, 1))).is_true()
	assert_bool(map.is_blocked(MapLayout.cell_from_row_col(1, 2))).is_true()
	assert_bool(map.is_blocked(MapLayout.cell_from_row_col(0, 0))).is_false()
	assert_int(map.props.size()).is_equal(1)
	assert_str(map.props[0].id).is_equal("prop.test.sign")
	assert_vector(map.props[0].cell).is_equal(MapLayout.cell_from_row_col(1, 2))


func test_heights_and_stairs_are_copied() -> void:
	var map: MapDef = _build("map.test.00_00", _specs()).map
	var stairs: Vector2i = MapLayout.cell_from_row_col(3, 1)
	assert_str(map.kind_at(stairs)).is_equal("stairs")
	assert_int(map.height_at(stairs)).is_equal(0)
	assert_int(map.height_at(MapLayout.cell_from_row_col(2, 2))).is_equal(1)
	assert_int(map.heights.size()).is_equal(1)


func test_an_edge_exit_arrives_one_step_inward_from_the_matching_exit() -> void:
	var specs: Dictionary = _specs()
	var a: MapDef = _build("map.test.00_00", specs).map
	var exit: MapExit = a.find_exit_at(MapLayout.cell_from_row_col(2, 3))
	assert_object(exit).is_not_null()
	assert_str(exit.kind).is_equal("edge")
	assert_str(exit.target_map_id).is_equal("map.test.01_00")
	assert_vector(exit.target_entry_cell).is_equal(MapLayout.cell_from_row_col(2, 1))
	var b: MapDef = _build("map.test.01_00", specs).map
	var back: MapExit = b.find_exit_at(MapLayout.cell_from_row_col(2, 0))
	assert_str(back.target_map_id).is_equal("map.test.00_00")
	assert_vector(back.target_entry_cell).is_equal(MapLayout.cell_from_row_col(2, 2))


func test_a_top_and_bottom_exit_pair_up() -> void:
	var top: String = "id: map.test.00_01\nregion: test\nsize: 4x4\ngrid:\n. > . .\n . . .\n. @ . .\n . . .\n"
	var bottom: String = "id: map.test.00_00\nregion: test\nsize: 4x4\ngrid:\n. . . .\n . . .\n. @ . .\n . > .\n"
	# Row 3 has 3 cells and the top row of the other map has 4, so the `>` must line up by column
	# AND exist in the other row: column 1 is in both.
	var specs: Dictionary = {}
	for text: String in [top, bottom]:
		var spec: MapSpec = MapSpec.parse(text)
		assert_array(spec.errors).is_empty()
		specs[spec.id] = spec
	var lower: MapBuilder = MapBuilder.build(specs["map.test.00_00"] as MapSpec, specs)
	assert_array(lower.errors).is_empty()
	assert_vector(lower.map.exits[0].target_entry_cell).is_equal(MapLayout.cell_from_row_col(2, 1))
	var upper: MapBuilder = MapBuilder.build(specs["map.test.00_01"] as MapSpec, specs)
	assert_array(upper.errors).is_empty()
	assert_str(upper.map.exits[0].target_map_id).is_equal("map.test.00_00")
	assert_vector(upper.map.exits[0].target_entry_cell).is_equal(MapLayout.cell_from_row_col(1, 1))


func test_a_link_leads_to_the_named_entry_of_the_other_map() -> void:
	var specs: Dictionary = _specs()
	var b: MapDef = _build("map.test.01_00", specs).map
	var door: MapExit = b.find_exit_at(MapLayout.cell_from_row_col(1, 2))
	assert_str(door.kind).is_equal("door")
	assert_str(door.target_map_id).is_equal("map.test.00_00")
	assert_vector(door.target_entry_cell).is_equal(MapLayout.cell_from_row_col(0, 1))


func test_an_exit_to_a_missing_neighbour_is_reported() -> void:
	var specs: Dictionary = _specs()
	specs.erase("map.test.01_00")
	assert_bool(_has_error(MapBuilder.build(specs["map.test.00_00"] as MapSpec, specs), "does not exist")).is_true()


func test_an_exit_without_a_matching_exit_on_the_other_edge_is_reported() -> void:
	var specs: Dictionary = _specs(MAP_A_WITH_ENTRY, MAP_B.replace("> @ = .", ". @ = ."))
	assert_bool(_has_error(_build("map.test.00_00", specs), "no matching '>'")).is_true()


func test_a_link_to_an_unknown_map_or_entry_is_reported() -> void:
	var unknown_map: Dictionary = _specs(MAP_A_WITH_ENTRY, MAP_B.replace("link door map.test.00_00", "link door map.test.09_09"))
	assert_bool(_has_error(_build("map.test.01_00", unknown_map), "unknown map")).is_true()
	var unknown_entry: Dictionary = _specs(MAP_A_WITH_ENTRY, MAP_B.replace("from_b", "nowhere"))
	assert_bool(_has_error(_build("map.test.01_00", unknown_entry), "unknown entry")).is_true()


func test_an_exit_needs_an_id_with_coordinates() -> void:
	var text: String = MAP_B.replace("map.test.01_00", "map.test.cave")
	var spec: MapSpec = MapSpec.parse(text)
	assert_array(spec.errors).is_empty()
	var builder: MapBuilder = MapBuilder.build(spec, {spec.id: spec})
	assert_bool(_has_error(builder, "needs an id like")).is_true()


func test_a_world_of_coordinates_off_the_map_is_reported() -> void:
	# The left edge of column 0 would lead to column -1.
	var builder: MapBuilder = _build("map.test.00_00", _specs(MAP_A_WITH_ENTRY.replace(". @ = >", "> @ = ."), MAP_B))
	assert_bool(_has_error(builder, "needs an id like")).is_true()


func test_a_low_object_and_walls_are_blocked_cells() -> void:
	var text: String = MAP_A_WITH_ENTRY.replace(". . = .
 . # 1", ". . C W
 V # 1")
	var spec: MapSpec = MapSpec.parse(text)
	assert_array(spec.errors).is_empty()
	var map: MapDef = MapBuilder.build(spec, {spec.id: spec, "map.test.01_00": MapSpec.parse(MAP_B)}).map
	for col: int in [2, 3]:
		assert_bool(map.is_blocked(MapLayout.cell_from_row_col(0, col))).is_true()
