class_name MapPlacerTest
extends GdUnitTestSuite

## A small map: a building of B cells with a gate gap, a rock cell and a row of trees.
const TEXT: String = """
id: map.test.00_00
region: test
size: 8x16
grid:
T T T T T T T T
 T T T T T T T
T T T T T T T T
 T T T T T T T
T T T T T T T T
 T T T T T T T
T T T T T T T T
 T T T T T T T
. . B B B B . .
 . B B B B B .
. B B = B B . .
 . . . @ . # .
. . . . . . . .
 . . . . . . .
. . . . . . . .
 . . . . . . .
"""

const BUILDING: String = "res://assets/art/maps/test/building_B.png"


func _spec() -> MapSpec:
	var spec: MapSpec = MapSpec.parse(TEXT)
	assert_array(spec.errors).is_empty()
	return spec


func _kit() -> MapKit:
	var kit: MapKit = MapKit.new()
	kit.region = "test"
	kit.trees = ["res://k/tree_01.png", "res://k/tree_02.png"]
	kit.plants = ["res://k/plant_01.png", "res://k/plant_02.png", "res://k/plant_03.png"]
	kit.rocks = ["res://k/rock_01.png", "res://k/rock_02.png", "res://k/rock_03.png"]
	kit.patches = ["res://k/patch_01.png", "res://k/patch_02.png"]
	kit.cell_rocks = 2
	return kit


func _sizes() -> Dictionary:
	return {
		"res://k/tree_01.png": Vector2i(500, 800), "res://k/tree_02.png": Vector2i(400, 700),
		"res://k/tree_01_shadow.png": Vector2i(500, 120), "res://k/tree_02_shadow.png": Vector2i(400, 100),
		"res://k/plant_01.png": Vector2i(200, 150), "res://k/plant_02.png": Vector2i(250, 160), "res://k/plant_03.png": Vector2i(180, 200),
		"res://k/rock_01.png": Vector2i(400, 350), "res://k/rock_02.png": Vector2i(380, 300), "res://k/rock_03.png": Vector2i(150, 120),
		"res://k/patch_01.png": Vector2i(400, 200), "res://k/patch_02.png": Vector2i(350, 180),
		BUILDING: Vector2i(1720, 914), "res://assets/art/maps/test/building_B_shadow.png": Vector2i(1720, 300),
	}


func _build(with_building: bool = true) -> Array[MapPlacer.Placement]:
	var buildings: Dictionary = {"B": BUILDING} if with_building else {}
	return MapPlacer.build(_spec(), _kit(), buildings, _sizes())


func _of_kind(placements: Array[MapPlacer.Placement], kind: String) -> Array[MapPlacer.Placement]:
	var found: Array[MapPlacer.Placement] = []
	for placement: MapPlacer.Placement in placements:
		if placement.kind == kind:
			found.append(placement)
	return found


func test_every_tree_cell_gets_one_tree() -> void:
	var spec: MapSpec = _spec()
	var trees: int = spec.find_symbol("T").size()
	assert_int(_of_kind(_build(), "tree").size()).is_equal(trees)


func test_a_rock_stands_on_each_rock_cell_and_uses_only_the_big_rocks() -> void:
	var rocks: Array[MapPlacer.Placement] = _of_kind(_build(), "rock")
	assert_int(rocks.size()).is_equal(1)
	assert_bool(["res://k/rock_01.png", "res://k/rock_02.png"].has(rocks[0].texture)).is_true()
	var cell: Vector2 = MapLayout.pixel_center(11, 5)
	assert_float(rocks[0].position.x).is_equal_approx(cell.x, 0.01)


func test_the_same_map_is_always_dressed_the_same_way() -> void:
	var first: Array[MapPlacer.Placement] = _build()
	var second: Array[MapPlacer.Placement] = _build()
	assert_int(first.size()).is_equal(second.size())
	for index: int in first.size():
		assert_str(first[index].texture).is_equal(second[index].texture)
		assert_vector(first[index].position).is_equal(second[index].position)
		assert_bool(first[index].flip_h).is_equal(second[index].flip_h)


func test_a_tree_hangs_on_its_feet_and_has_its_width_in_the_kit_range() -> void:
	var kit: MapKit = _kit()
	for tree: MapPlacer.Placement in _of_kind(_build(), "tree"):
		var size: Vector2i = _sizes()[tree.texture]
		var width: float = size.x * tree.scale
		assert_float(width).is_between(kit.tree_width.x - 0.01, kit.tree_width.y + 0.01)
		# The offset puts the bottom centre of the picture on the node position.
		assert_float(tree.offset.x).is_equal_approx(-size.x / 2.0, 0.01)
		assert_float(tree.offset.y).is_equal_approx(-size.y, 0.01)


func test_ground_pieces_lie_under_and_objects_are_sorted_with_the_hero() -> void:
	for placement: MapPlacer.Placement in _build():
		if placement.kind == "patch" or placement.kind == "shadow":
			assert_str(placement.layer).is_equal(MapPlacer.LAYER_GROUND)
		else:
			assert_str(placement.layer).is_equal(MapPlacer.LAYER_OBJECTS)


func test_trees_with_a_shadow_picture_get_a_shadow_on_the_ground() -> void:
	var placements: Array[MapPlacer.Placement] = _build()
	var shadows: Array[MapPlacer.Placement] = _of_kind(placements, "shadow")
	var trees: Array[MapPlacer.Placement] = _of_kind(placements, "tree")
	var tree_shadows: int = 0
	for shadow: MapPlacer.Placement in shadows:
		if shadow.texture.contains("tree_"):
			tree_shadows += 1
	assert_int(tree_shadows).is_equal(trees.size())


func test_the_building_is_cut_into_strips_that_cover_its_whole_picture() -> void:
	var strips: Array[MapPlacer.Placement] = _of_kind(_build(), "building")
	assert_bool(strips.size() > 4).is_true()
	var covered: int = 0
	var previous_end: int = 0
	for strip: MapPlacer.Placement in strips:
		assert_str(strip.texture).is_equal(BUILDING)
		covered += strip.region.size.x
		assert_int(strip.region.size.y).is_equal(914)
	# Strips next to each other leave no gap and no overlap in the picture.
	var starts: Array[int] = []
	for strip: MapPlacer.Placement in strips:
		starts.append(strip.region.position.x)
	starts.sort()
	for index: int in range(1, starts.size()):
		assert_int(starts[index]).is_greater(starts[index - 1])
	assert_int(previous_end).is_equal(0)
	assert_int(covered).is_less_equal(1720)
	assert_int(covered).is_equal(1720)


func test_the_strips_in_front_of_the_gate_gap_sort_behind_the_wings() -> void:
	var strips: Array[MapPlacer.Placement] = _of_kind(_build(), "building")
	var gate_x: float = MapLayout.pixel_center(10, 3).x
	var wing_x: float = MapLayout.pixel_center(10, 1).x
	var gate_key: float = INF
	var wing_key: float = -INF
	for strip: MapPlacer.Placement in strips:
		var centre_x: float = strip.position.x + strip.region.size.x * strip.scale / 2.0
		if absf(centre_x - gate_x) < 20.0:
			gate_key = minf(gate_key, strip.position.y)
		if absf(centre_x - wing_x) < 20.0:
			wing_key = maxf(wing_key, strip.position.y)
	assert_float(gate_key).is_less(wing_key)


func test_a_strip_hangs_its_picture_at_the_top_of_the_canvas() -> void:
	var cluster: Rect2 = MapFootprint.cluster_rect(_spec(), "B")
	var scale: float = cluster.size.x / 1720.0
	var expected_top: float = cluster.end.y - 914.0 * scale
	for strip: MapPlacer.Placement in _of_kind(_build(), "building"):
		var top: float = strip.position.y + strip.offset.y * strip.scale
		assert_float(top).is_equal_approx(expected_top, 0.05)


func test_no_plant_near_the_building_is_cut_by_a_taller_strip() -> void:
	var placements: Array[MapPlacer.Placement] = _build()
	var strips: Array[MapPlacer.Placement] = _of_kind(placements, "building")
	var cluster: Rect2 = MapFootprint.cluster_rect(_spec(), "B")
	var checked: int = 0
	for plant: MapPlacer.Placement in _of_kind(placements, "plant"):
		# Plants along the front of the building (trees behind it are meant to be hidden by it).
		if plant.position.y > cluster.end.y - 70.0 and plant.position.y < cluster.end.y + 45.0 and plant.position.x > cluster.position.x - 40.0 and plant.position.x < cluster.end.x + 40.0:
			checked += 1
			assert_bool(MapPlacer._is_clear(plant, _sizes(), strips)).is_true()
	assert_int(checked).is_greater(0)


func test_a_missing_picture_size_leaves_that_piece_out_instead_of_failing() -> void:
	var sizes: Dictionary = _sizes()
	sizes.erase("res://k/tree_01.png")
	sizes.erase("res://k/tree_02.png")
	var placements: Array[MapPlacer.Placement] = MapPlacer.build(_spec(), _kit(), {}, sizes)
	assert_int(_of_kind(placements, "tree").size()).is_equal(0)


func test_a_map_without_a_building_has_no_strips() -> void:
	assert_int(_of_kind(_build(false), "building").size()).is_equal(0)


func test_plants_of_trees_beside_the_building_are_not_cut_by_a_taller_strip() -> void:
	# Trees right next to both wings: their plants overlap the building strips.
	var text: String = TEXT.replace(". . B B B B . .\n . B B B B B .\n. B B = B B . .", "T T B B B B T T\n T B B B B B T\n. B B = B B T T")
	var spec: MapSpec = MapSpec.parse(text)
	assert_array(spec.errors).is_empty()
	var placements: Array[MapPlacer.Placement] = MapPlacer.build(spec, _kit(), {"B": BUILDING}, _sizes())
	var strips: Array[MapPlacer.Placement] = _of_kind(placements, "building")
	var plants: Array[MapPlacer.Placement] = _of_kind(placements, "plant")
	assert_bool(plants.is_empty()).is_false()
	for plant: MapPlacer.Placement in plants:
		assert_bool(MapPlacer._is_clear(plant, _sizes(), strips)).is_true()
