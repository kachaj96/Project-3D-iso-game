class_name MapFootprintTest
extends GdUnitTestSuite

## A building of B cells with a gate gap (the "=" cell) in its front row.
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
T . B B B B . T
 T B B B B B T
T B B = B B . T
 . . . @ . . .
. . . . . . . .
 . . . . . . .
. . . . . . . .
 . . . . . . .
"""


func _spec() -> MapSpec:
	var spec: MapSpec = MapSpec.parse(TEXT)
	assert_array(spec.errors).is_empty()
	return spec


func test_the_cluster_rectangle_holds_every_footprint_block() -> void:
	var spec: MapSpec = _spec()
	var rect: Rect2 = MapFootprint.cluster_rect(spec, "B")
	for centre: Vector2 in MapFootprint.cell_centres(spec, "B"):
		assert_bool(rect.has_point(centre)).is_true()
		assert_bool(rect.has_point(centre + Vector2(0.0, 31.0))).is_true()
		assert_bool(rect.has_point(centre - Vector2(0.0, MapFootprint.BUILDING_HEIGHT))).is_true()
	assert_object(MapFootprint.cluster_rect(spec, "Z")).is_equal(Rect2())


func test_the_canvas_adds_headroom_for_the_roof_and_margins() -> void:
	var spec: MapSpec = _spec()
	var cluster: Rect2 = MapFootprint.cluster_rect(spec, "B")
	var canvas: Rect2 = MapFootprint.canvas_rect(spec, "B")
	assert_float(cluster.position.y - canvas.position.y).is_equal(MapFootprint.CLUSTER_HEADROOM)
	assert_float(cluster.position.x - canvas.position.x).is_equal(MapFootprint.CLUSTER_MARGIN)
	assert_float(canvas.end.y - cluster.end.y).is_equal(MapFootprint.CLUSTER_MARGIN)
	assert_float(canvas.end.x - cluster.end.x).is_equal(MapFootprint.CLUSTER_MARGIN)


func test_it_matches_the_rectangle_found_in_the_blockout_picture() -> void:
	var spec: MapSpec = _spec()
	var cluster: Rect2 = MapFootprint.cluster_rect(spec, "B")
	var found: Rect2i = MapBlockout.cluster_rect(MapBlockout.render_in_place(spec, "B"))
	assert_float(absf(found.position.x - cluster.position.x * MapBlockout.SCALE)).is_less(3.0)
	assert_float(absf(found.position.y - cluster.position.y * MapBlockout.SCALE)).is_less(3.0)
	assert_float(absf(found.size.x - cluster.size.x * MapBlockout.SCALE)).is_less(3.0)
	assert_float(absf(found.size.y - cluster.size.y * MapBlockout.SCALE)).is_less(3.0)


func test_the_front_of_the_gate_gap_is_further_back_than_the_wings() -> void:
	var spec: MapSpec = _spec()
	var gate: Vector2 = MapLayout.pixel_center(10, 3)
	var wing: Vector2 = MapLayout.pixel_center(10, 1)
	assert_float(MapFootprint.front_y_at(spec, "B", gate.x)).is_less(MapFootprint.front_y_at(spec, "B", wing.x))
	assert_float(MapFootprint.front_y_at(spec, "B", -1000.0)).is_equal(-INF)
