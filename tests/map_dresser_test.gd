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
