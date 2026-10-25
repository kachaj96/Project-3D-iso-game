class_name MapBlockoutTest
extends GdUnitTestSuite
## Blockout picture and prompt of the map generator.

## 4 columns, 6 rows. Row 5 (the bottom row) is drawn last, so nothing covers it.
const TEXT: String = """
id: map.test.01_01
region: test
size: 4x6
grid:
. . . .
 . . .
. @ = .
 > . .
. . . .
 . # 1
heights:
0 0 0 0
 0 0 0
0 0 0 0
 0 0 0
0 0 0 0
 0 0 0
markers:
1 prop sign prop.test.sign sign.test.sign
"""

func _spec(text: String = TEXT) -> MapSpec:
	var spec: MapSpec = MapSpec.parse(text)
	assert_array(spec.errors).is_empty()
	return spec


## Colour of the picture at the centre of a cell, `dx` and `dy` pixels away from it.
func _pixel(image: Image, row: int, col: int, dx: int = 0, dy: int = 0) -> Color:
	var centre: Vector2 = MapLayout.pixel_center(row, col) * MapBlockout.SCALE
	return image.get_pixel(int(centre.x) + dx, int(centre.y) + dy)


func test_the_picture_has_the_final_backdrop_size() -> void:
	var text: String = "id: map.test.00_00\nregion: test\nsize: 10x20\ngrid:\n"
	for row: int in 20:
		var cells: Array[String] = []
		for col: int in MapLayout.row_length(10, row):
			cells.append("@" if row == 5 and col == 4 else ".")
		text += " ".join(cells) + "\n"
	var image: Image = MapBlockout.render(_spec(text))
	assert_int(image.get_width()).is_equal(2560)
	assert_int(image.get_height()).is_equal(1344)


func test_ground_and_path_cells_have_their_colours() -> void:
	var image: Image = MapBlockout.render(_spec())
	assert_bool(_same(_pixel(image, 4, 0), MapBlockout.GROUND)).is_true()
	assert_bool(_same(_pixel(image, 2, 2), MapBlockout.PATH)).is_true()


func test_an_exit_is_blue_off_its_letter() -> void:
	var image: Image = MapBlockout.render(_spec())
	assert_bool(_same(_pixel(image, 3, 0, 60, 0), MapBlockout.EXIT)).is_true()


func test_a_rock_is_drawn_as_a_raised_grey_block() -> void:
	var image: Image = MapBlockout.render(_spec())
	var obstacle_top: int = -MapBlockout.OBSTACLE_HEIGHT["#"] * MapBlockout.SCALE
	assert_bool(_same(_pixel(image, 5, 1, 0, obstacle_top), MapBlockout.ROCK)).is_true()


func test_a_prop_is_pink_and_a_higher_cell_is_drawn_higher() -> void:
	var image: Image = MapBlockout.render(_spec())
	assert_bool(_same(_pixel(image, 5, 2, 0, -MapBlockout.PROP_HEIGHT * MapBlockout.SCALE), MapBlockout.PROP)).is_true()
	var raised: MapSpec = _spec(TEXT.replace("0 0 0 0\n 0 0 0\n0 0 0 0\n 0 0 0\n0 0 0 0\n 0 0 0\nmarkers", "0 0 0 0\n 0 0 0\n0 0 0 0\n 0 0 0\n0 0 0 0\n 0 2 0\nmarkers"))
	var image_raised: Image = MapBlockout.render(raised)
	var lift: int = -2 * GridMath.LEVEL_HEIGHT * MapBlockout.SCALE - MapBlockout.OBSTACLE_HEIGHT["#"] * MapBlockout.SCALE
	assert_bool(_same(_pixel(image_raised, 5, 1, 0, lift), MapBlockout.ROCK)).is_true()


func test_the_spawn_is_a_white_dot() -> void:
	var image: Image = MapBlockout.render(_spec())
	assert_bool(_same(_pixel(image, 2, 1), MapBlockout.SPAWN_DOT)).is_true()


func test_the_prompt_names_the_map_size_edges_and_contents() -> void:
	var spec: MapSpec = _spec()
	var text: String = MapPrompt.build(spec, {spec.id: spec})
	assert_str(text).contains("map.test.01_01")
	assert_str(text).contains("1024 x 448")
	assert_str(text).contains("A sign at row 5, column 2")
	assert_str(text).contains("Rocks or walls: 1 cells")
	assert_str(text).contains("Left edge: leads to map.test.00_01 (not made yet)")
	assert_str(text).contains("at 60% of the edge")
	assert_str(text).contains("Top edge: no exit")
	assert_str(text).contains("Style")


func test_the_prompt_knows_when_the_neighbour_exists() -> void:
	var spec: MapSpec = _spec()
	var neighbour: MapSpec = MapSpec.new()
	neighbour.id = "map.test.00_01"
	var text: String = MapPrompt.build(spec, {spec.id: spec, neighbour.id: neighbour})
	assert_str(text).contains("Left edge: leads to map.test.00_01.")


## Pictures store 8 bits per colour, so compare with a small tolerance.
func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01
