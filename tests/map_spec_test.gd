class_name MapSpecTest
extends GdUnitTestSuite

## A small valid map: 4 columns, 4 rows (rows 0 and 2 hold 4 cells, rows 1 and 3 hold 3).
const VALID: String = """
// A comment line.
id: map.hollow.04_07
region: hollow
title_key: map.hollow.04_07.title
size: 4x4
grid:
. . = .
 . = 1
. @ = >
 . 2 .
heights:
0 0 1 1
 0 1 2
0 0 1 1
 0 0 0
markers:
1 prop sign prop.hollow.04_07.sign sign.hollow.04_07.sign
2 link door map.hollow.04_07.in01 front_door
entries:
from_inside 3 1
"""


func _without(text: String, part: String) -> String:
	return text.replace(part, "")


func _replaced(old: String, new: String) -> MapSpec:
	return MapSpec.parse(VALID.replace(old, new))


func _has_error(spec: MapSpec, fragment: String) -> bool:
	for error: String in spec.errors:
		if error.contains(fragment):
			return true
	return false


func test_a_valid_file_parses_without_errors() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_array(spec.errors).is_empty()
	assert_bool(spec.is_valid()).is_true()


func test_header_values_are_read() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_str(spec.id).is_equal("map.hollow.04_07")
	assert_str(spec.region).is_equal("hollow")
	assert_str(spec.title_key).is_equal("map.hollow.04_07.title")
	assert_int(spec.columns).is_equal(4)
	assert_int(spec.rows).is_equal(4)


func test_spaces_and_indentation_in_rows_are_ignored() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_int(spec.grid.size()).is_equal(4)
	assert_str(spec.grid[0]).is_equal("..=.")
	assert_str(spec.grid[1]).is_equal(".=1")
	assert_str(spec.grid[2]).is_equal(".@=>")
	assert_str(spec.grid[3]).is_equal(".2.")
	assert_str(spec.symbol_at(2, 3)).is_equal(">")
	assert_str(spec.symbol_at(1, 2)).is_equal("1")


func test_heights_are_read_and_default_to_zero_without_a_section() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_int(spec.height_at(0, 2)).is_equal(1)
	assert_int(spec.height_at(1, 2)).is_equal(2)
	var flat: MapSpec = MapSpec.parse(VALID.substr(0, VALID.find("heights:")) + VALID.substr(VALID.find("markers:")))
	assert_array(flat.errors).is_empty()
	assert_int(flat.height_at(1, 2)).is_equal(0)


func test_markers_and_entries_are_read() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_int(spec.props.size()).is_equal(1)
	assert_str(spec.props[0]["id"]).is_equal("prop.hollow.04_07.sign")
	assert_str(spec.props[0]["text_key"]).is_equal("sign.hollow.04_07.sign")
	assert_int(spec.links.size()).is_equal(1)
	assert_str(spec.links[0]["target_map_id"]).is_equal("map.hollow.04_07.in01")
	assert_str(spec.links[0]["entry"]).is_equal("front_door")
	assert_int(spec.entries.size()).is_equal(1)
	assert_int(spec.entries[0]["row"]).is_equal(3)


func test_walkable_cells_include_doors_but_not_props_or_rocks() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_bool(spec.is_walkable(0, 0)).is_true()
	assert_bool(spec.is_walkable(1, 2)).is_false()
	assert_bool(spec.is_walkable(3, 1)).is_true()
	assert_bool(spec.is_walkable(0, 3)).is_true()


func test_find_symbol_lists_row_and_column() -> void:
	var spec: MapSpec = MapSpec.parse(VALID)
	assert_array(spec.find_symbol("@")).is_equal([Vector2i(2, 1)])


func test_missing_id_is_reported() -> void:
	assert_bool(_has_error(_replaced("id: map.hollow.04_07\n", ""), "missing 'id'")).is_true()


func test_bad_id_is_reported() -> void:
	assert_bool(_has_error(_replaced("id: map.hollow.04_07", "id: Hollow 4"), "invalid map id")).is_true()


func test_bad_size_text_is_reported_with_its_line() -> void:
	var spec: MapSpec = _replaced("size: 4x4", "size: big")
	assert_bool(_has_error(spec, "line ")).is_true()
	assert_bool(_has_error(spec, "size must look like")).is_true()


func test_unknown_header_key_is_reported() -> void:
	assert_bool(_has_error(_replaced("region: hollow", "region: hollow\ncolour: red"), "unknown key 'colour'")).is_true()


func test_wrong_row_length_is_reported() -> void:
	assert_bool(_has_error(_replaced(". @ = >", ". @ ="), "grid row 2 has 3 cells, expected 4")).is_true()


func test_odd_row_with_too_many_cells_is_reported() -> void:
	assert_bool(_has_error(_replaced(" . = 1", " . = 1 ."), "grid row 1 has 4 cells, expected 3")).is_true()


func test_wrong_number_of_rows_is_reported() -> void:
	assert_bool(_has_error(_replaced(" . 2 .\nheights:", "heights:"), "grid has 3 rows")).is_true()


func test_unknown_symbol_is_reported() -> void:
	assert_bool(_has_error(_replaced(". @ = >", ". @ = Z"), "unknown symbol 'Z'")).is_true()


func test_missing_or_double_spawn_is_reported() -> void:
	assert_bool(_has_error(_replaced(". @ = >", ". . = >"), "exactly one spawn")).is_true()
	assert_bool(_has_error(_replaced(". @ = >", "@ @ = >"), "found 2")).is_true()


func test_exit_not_on_an_edge_is_reported() -> void:
	assert_bool(_has_error(_replaced(". @ = >", ". @ > ."), "exactly one screen edge")).is_true()


func test_exit_in_a_corner_is_reported() -> void:
	assert_bool(_has_error(_replaced(". . = .", "> . = ."), "exactly one screen edge")).is_true()


func test_height_above_the_maximum_is_reported() -> void:
	assert_bool(_has_error(_replaced("0 0 1 1\n 0 1 2", "0 0 1 1\n 0 1 8"), "not a level from 0 to 7")).is_true()


func test_heights_with_the_wrong_shape_are_reported() -> void:
	assert_bool(_has_error(_replaced(" 0 0 0\nmarkers:", " 0 0\nmarkers:"), "heights row 3 has 2 cells")).is_true()


func test_marker_in_the_grid_without_a_declaration_is_reported() -> void:
	assert_bool(_has_error(_replaced(". @ = >", ". @ = 3"), "marker 3 is in the grid but not declared")).is_true()


func test_declared_marker_missing_from_the_grid_is_reported() -> void:
	assert_bool(_has_error(_replaced(" . 2 .", " . . ."), "marker 2 is declared but appears 0 times")).is_true()


func test_marker_declared_twice_is_reported() -> void:
	assert_bool(_has_error(_replaced("2 link door", "1 link door"), "marker 1 is declared twice")).is_true()


func test_unknown_prop_kind_and_link_kind_are_reported() -> void:
	assert_bool(_has_error(_replaced("1 prop sign", "1 prop chest"), "unknown prop kind")).is_true()
	assert_bool(_has_error(_replaced("2 link door", "2 link portal"), "unknown link kind")).is_true()


func test_entry_outside_the_map_or_on_a_rock_is_reported() -> void:
	assert_bool(_has_error(_replaced("from_inside 3 1", "from_inside 9 1"), "outside the map")).is_true()
	assert_bool(_has_error(_replaced("from_inside 3 1", "from_inside 1 2"), "walkable cell")).is_true()


func test_bad_marker_line_is_reported() -> void:
	assert_bool(_has_error(_replaced("2 link door map.hollow.04_07.in01 front_door", "2 link door"), "expected '2 prop")).is_true()
	assert_bool(_has_error(_replaced("2 link door", "x link door"), "starts with one digit")).is_true()


func test_windows_line_endings_are_accepted() -> void:
	assert_array(MapSpec.parse(VALID.replace("\n", "\r\n")).errors).is_empty()


func test_a_full_10_by_20_map_parses() -> void:
	var text: String = "id: map.test.00_00\nregion: test\nsize: 10x20\ngrid:\n"
	for row: int in 20:
		var cells: Array[String] = []
		for col: int in MapLayout.row_length(10, row):
			cells.append("@" if row == 5 and col == 4 else ".")
		text += " ".join(cells) + "\n"
	var spec: MapSpec = MapSpec.parse(text)
	assert_array(spec.errors).is_empty()
	assert_int(spec.grid.size()).is_equal(20)
