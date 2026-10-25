class_name MapDresserTest
extends GdUnitTestSuite
## Dresses a stub scene with real kit pictures (run `godot --headless --import` once after
## new pictures were written, so that they can be loaded).

const MAP_ID: String = "map.gluchobor.02_02"
const SPEC: String = "res://content/map_specs/gluchobor/02_02.txt"
const ASSETS: String = "res://assets/art/maps/map.gluchobor.02_02/"


func _spec() -> MapSpec:
	var spec: MapSpec = MapSpec.parse(FileAccess.get_file_as_string(SPEC))
	assert_array(spec.errors).is_empty()
	return spec


func _stub(spec: MapSpec) -> Node2D:
	var builder: MapBuilder = MapBuilder.build(spec, {spec.id: spec})
	var tile_set: TileSet = load(MapSceneStub.TILE_SET_PATH)
	return auto_free(MapSceneStub.build(builder.map, MapGenerator.def_path(spec.id), tile_set))


func _placement(kind: String, layer: String, x: float) -> MapPlacer.Placement:
	var placement: MapPlacer.Placement = MapPlacer.Placement.new()
	placement.kind = kind
	placement.texture = "res://assets/art/kits/gluchobor/plants/plant_01.png"
	placement.position = Vector2(x, 100.0)
	placement.scale = 0.1
	placement.layer = layer
	return placement


func test_dressing_fills_the_backdrop_and_hides_the_placeholders() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress(root, spec, [], ASSETS)
	var backdrop: Sprite2D = root.get_node("Backdrop")
	assert_object(backdrop.texture).is_not_null()
	# The picture is scaled to the map width: 10 cells of 128 px.
	assert_float(backdrop.texture.get_width() * backdrop.scale.x).is_equal_approx(1280.0, 0.01)
	assert_bool((root.get_node("Ground") as CanvasItem).visible).is_false()
	assert_bool((root.get_node("Objects") as CanvasItem).visible).is_false()


func test_ground_pieces_go_to_the_decor_and_objects_to_the_sorted_dressing() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress(root, spec, [_placement("patch", MapPlacer.LAYER_GROUND, 10.0), _placement("plant", MapPlacer.LAYER_OBJECTS, 20.0), _placement("plant", MapPlacer.LAYER_OBJECTS, 30.0)], ASSETS)
	assert_int(root.get_node(MapDresser.GROUND_DECOR).get_child_count()).is_equal(1)
	assert_int(root.get_node(MapDresser.DRESSING).get_child_count()).is_equal(2)
	assert_bool((root.get_node(MapDresser.DRESSING) as Node2D).y_sort_enabled).is_true()
	assert_bool((root.get_node(MapDresser.GROUND_DECOR) as Node2D).y_sort_enabled).is_false()
	assert_int((root.get_node(MapDresser.GROUND_DECOR) as Node2D).z_index).is_equal(-1)
	var plant: Sprite2D = root.get_node("%s/plant_002" % MapDresser.DRESSING)
	assert_vector(plant.position).is_equal(Vector2(30.0, 100.0))
	assert_float(plant.scale.x).is_equal_approx(0.1, 0.0001)
	assert_bool(plant.centered).is_false()
	assert_bool(plant.is_in_group(MapDresser.GENERATED_GROUP)).is_true()
	assert_object(plant.owner).is_same(root)


func test_a_building_strip_shows_only_its_part_of_the_picture() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	var strip: MapPlacer.Placement = _placement("building", MapPlacer.LAYER_OBJECTS, 0.0)
	strip.region = Rect2i(100, 0, 64, 90)
	MapDresser.dress(root, spec, [strip], ASSETS)
	var sprite: Sprite2D = root.get_node("%s/building_001" % MapDresser.DRESSING)
	assert_bool(sprite.region_enabled).is_true()
	assert_object(sprite.region_rect).is_equal(Rect2(100, 0, 64, 90))


func test_mist_and_light_lie_above_everything_and_the_light_adds_up() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress(root, spec, [], ASSETS)
	var mist: Sprite2D = root.get_node("Effects/%s" % MapDresser.MIST)
	var light: Sprite2D = root.get_node("Lights/%s" % MapDresser.LIGHT)
	assert_int((root.get_node("Effects") as Node2D).z_index).is_equal(MapDresser.EFFECT_Z)
	assert_float(mist.modulate.a).is_equal_approx(MapDresser.MIST_OPACITY, 0.001)
	assert_int((light.material as CanvasItemMaterial).blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_ADD)
	assert_object(mist.material).is_null()


func test_dressing_again_replaces_generated_nodes_but_keeps_yours() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress(root, spec, [_placement("plant", MapPlacer.LAYER_OBJECTS, 20.0)], ASSETS)
	# A hand-made sprite in the dressing, and a generated one you decided to keep by leaving the group.
	var mine: Sprite2D = Sprite2D.new()
	mine.name = "my_lamp"
	root.get_node(MapDresser.DRESSING).add_child(mine)
	mine.owner = root
	var kept: Sprite2D = root.get_node("%s/plant_001" % MapDresser.DRESSING)
	kept.remove_from_group(MapDresser.GENERATED_GROUP)
	MapDresser.dress(root, spec, [_placement("plant", MapPlacer.LAYER_OBJECTS, 40.0)], ASSETS)
	var dressing: Node = root.get_node(MapDresser.DRESSING)
	assert_object(dressing.get_node_or_null("my_lamp")).is_not_null()
	assert_object(dressing.get_node_or_null("plant_001")).is_not_null()
	# Kept one plus the new generated one: the new one got the next free name.
	var plants: int = 0
	for child: Node in dressing.get_children():
		if child.name.begins_with("plant_"):
			plants += 1
	assert_int(plants).is_equal(2)
	# Exactly one mist and one light after dressing twice.
	assert_int(root.get_node("Effects").get_child_count()).is_equal(1)
	assert_int(root.get_node("Lights").get_child_count()).is_equal(1)


func test_a_dressed_scene_can_be_saved_and_loaded_with_its_generated_group() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress(root, spec, [_placement("plant", MapPlacer.LAYER_OBJECTS, 20.0)], ASSETS)
	var packed: PackedScene = PackedScene.new()
	assert_int(packed.pack(root)).is_equal(OK)
	var copy: Node2D = auto_free(packed.instantiate())
	var plant: Sprite2D = copy.get_node("%s/plant_001" % MapDresser.DRESSING)
	assert_bool(plant.is_in_group(MapDresser.GENERATED_GROUP)).is_true()
	assert_vector(plant.position).is_equal(Vector2(20.0, 100.0))


const CHAMBER_SPEC: String = "res://content/map_specs/gluchobor/02_02.in01.txt"


func _chamber() -> MapSpec:
	var spec: MapSpec = MapSpec.parse(FileAccess.get_file_as_string(CHAMBER_SPEC))
	assert_array(spec.errors).is_empty()
	return spec


func test_torch_positions_come_from_the_lights_section_above_the_wall_cell() -> void:
	var spec: MapSpec = _chamber()
	var positions: Array[Vector2] = MapPlacer.torch_positions(spec)
	assert_int(positions.size()).is_equal(4)
	var first: Dictionary = spec.lights[0]
	var expected: Vector2 = MapLayout.pixel_center(first["row"] as int, first["col"] as int) + Vector2(0.0, MapPlacer.TORCH_HEIGHT)
	assert_vector(positions[0]).is_equal(expected)


func test_a_dark_room_gets_darkness_and_flickering_torches() -> void:
	var spec: MapSpec = _chamber()
	var root: Node2D = _stub(spec)
	MapDresser.dress_mood(root, spec.theme, MapPlacer.torch_positions(spec))
	var darkness: CanvasModulate = root.get_node("Darkness")
	assert_object(darkness.color).is_equal(MapTheme.darkness(MapTheme.DARK_INTERIOR))
	var torches: Array[Node] = root.get_node("Lights").get_children().filter(func(node: Node) -> bool: return node is TorchFlicker)
	assert_int(torches.size()).is_equal(4)
	var torch: TorchFlicker = torches[0]
	assert_bool(torch.is_in_group(MapDresser.GENERATED_GROUP)).is_true()
	assert_float(torch.color.r).is_greater(torch.color.b)
	# The radius on screen is the radius of the theme.
	assert_float(torch.texture.get_width() / 2.0 * torch.texture_scale).is_equal_approx(MapTheme.torch_radius(), 0.5)


func test_the_mood_is_replaced_not_doubled_when_dressed_again() -> void:
	var spec: MapSpec = _chamber()
	var root: Node2D = _stub(spec)
	for round_number: int in 2:
		MapDresser.dress_mood(root, spec.theme, MapPlacer.torch_positions(spec))
	var darkness_nodes: int = 0
	for node: Node in root.get_children():
		if node is CanvasModulate:
			darkness_nodes += 1
	assert_int(darkness_nodes).is_equal(1)
	assert_int(root.get_node("Lights").get_child_count()).is_equal(4)


func test_a_forest_map_gets_no_darkness_and_loses_an_old_one() -> void:
	var spec: MapSpec = _spec()
	var root: Node2D = _stub(spec)
	MapDresser.dress_mood(root, MapTheme.DARK_INTERIOR, [Vector2(10.0, 10.0)])
	assert_object(root.get_node_or_null("Darkness")).is_not_null()
	MapDresser.dress_mood(root, MapTheme.FOREST, [])
	assert_object(root.get_node_or_null("Darkness")).is_null()
	assert_int(root.get_node("Lights").get_child_count()).is_equal(0)


func test_a_torch_flickers_between_its_base_and_a_dimmer_light() -> void:
	var torch: TorchFlicker = auto_free(TorchFlicker.new())
	torch.base_energy = 1.0
	torch.flicker = 0.3
	add_child(torch)
	var lowest: float = 10.0
	var highest: float = 0.0
	for step: int in 400:
		torch._process(0.02)
		lowest = minf(lowest, torch.energy)
		highest = maxf(highest, torch.energy)
	assert_float(highest).is_less_equal(1.0)
	assert_float(lowest).is_greater_equal(0.69)
	assert_float(highest - lowest).is_greater(0.1)


func test_window_positions_follow_the_wall_picture_fitted_to_its_footprint() -> void:
	var spec: MapSpec = _chamber()
	var cluster: Rect2 = MapFootprint.cluster_rect(spec, "W")
	var panes: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1000.0, 500.0)]
	var positions: Array[Vector2] = MapPlacer.window_positions(spec, "W", Vector2i(1000, 500), panes)
	var scale: float = cluster.size.x / 1000.0
	assert_vector(positions[0]).is_equal(Vector2(cluster.position.x, cluster.end.y - 500.0 * scale))
	assert_vector(positions[1]).is_equal(Vector2(cluster.end.x, cluster.end.y))


func test_each_window_gets_a_shaft_of_light_that_is_replaced_when_dressed_again() -> void:
	var spec: MapSpec = _chamber()
	var root: Node2D = _stub(spec)
	var windows: Array[Vector2] = [Vector2(100.0, 100.0), Vector2(300.0, 140.0), Vector2(500.0, 180.0)]
	for round_number: int in 2:
		MapDresser.dress_mood(root, spec.theme, [], windows)
	var beams: Array[Node] = root.get_node("Effects").get_children().filter(func(node: Node) -> bool: return node.name.begins_with("Beam_"))
	assert_int(beams.size()).is_equal(3)
	var beam: Sprite2D = beams[1]
	assert_vector(beam.position).is_equal(Vector2(300.0, 140.0))
	assert_float(beam.rotation_degrees).is_equal_approx(MapTheme.beam_turn(), 0.01)
	assert_int((beam.material as CanvasItemMaterial).blend_mode).is_equal(CanvasItemMaterial.BLEND_MODE_ADD)
