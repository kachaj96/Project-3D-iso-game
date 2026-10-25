class_name MapDresser
extends RefCounted
## Puts the pictures of a map into its scene: the backdrop, the ground decals (patches and
## shadows), the objects (trees, rocks, plants and the building strips), the mist and the light.
## What goes where comes from MapPlacer; this class only turns placements into nodes.
##
## Everything it creates is in the group "generated". Dressing again removes exactly those nodes
## and nothing else, so what you added, moved or deleted by hand in the editor is never touched
## (a node you want to keep through a redress: remove it from the group "generated" in the
## Node tab of the editor). Textures are referenced by their res:// path, so they must be
## imported before (run the editor once, or godot --headless --import).
##
## Scene nodes (the world scene looks for Ground and Objects by name):
##   Backdrop       the ground picture, behind everything
##   GroundDecor    patches and shadows lying flat on the ground
##   Dressing       the objects, sorted by their feet together with the hero
##   Effects, Lights  mist and light shafts, drawn above everything

const GENERATED_GROUP: String = "generated"
const GROUND_DECOR: String = "GroundDecor"
const DRESSING: String = "Dressing"
const MIST: String = "Mist"
const LIGHT: String = "Light"
## How strong the mist and the light shafts are drawn (can be changed per map in the scene).
const MIST_OPACITY: float = 0.4  # the forest default, see MapTheme
const LIGHT_OPACITY: float = 0.45
## Mist and light are drawn above the hero.
const EFFECT_Z: int = 50


## Dresses the scene `root` (made by MapSceneStub) with the pictures of `map_id`.
## `assets_dir` is the folder with ground.png, mist.png and light.png of the map.
static func dress(root: Node2D, spec: MapSpec, placements: Array[MapPlacer.Placement], assets_dir: String) -> void:
	_remove_generated(root)
	var canvas_width: float = MapLayout.pixel_size(spec.columns, spec.rows).x
	_backdrop(root, assets_dir + "ground.png", canvas_width)
	_hide_placeholders(root)
	var decor: Node2D = _container(root, GROUND_DECOR, false)
	decor.z_index = -1
	var dressing: Node2D = _container(root, DRESSING, true)
	var counts: Dictionary = {}
	for placement: MapPlacer.Placement in placements:
		var parent: Node2D = decor if placement.layer == MapPlacer.LAYER_GROUND else dressing
		var index: int = counts.get(placement.kind, 0) + 1
		# Names stay unique: pieces you kept from an earlier dressing keep their names.
		while parent.has_node("%s_%03d" % [placement.kind, index]):
			index += 1
		counts[placement.kind] = index
		_sprite(root, parent, "%s_%03d" % [placement.kind, index], placement)
	_effect(root, "Effects", MIST, assets_dir + "mist.png", canvas_width, MapTheme.mist_opacity(spec.theme), false)
	if FileAccess.file_exists(assets_dir + "light.png"):
		_effect(root, "Lights", LIGHT, assets_dir + "light.png", canvas_width, MapTheme.light_opacity(spec.theme), true)


## Removes every node of the group "generated" from the scene (and only those).
static func _remove_generated(root: Node) -> void:
	for node: Node in root.get_children():
		_remove_generated(node)
	for node: Node in root.get_children():
		if node.is_in_group(GENERATED_GROUP):
			root.remove_child(node)
			node.free()


static func _backdrop(root: Node2D, texture_path: String, canvas_width: float) -> void:
	var backdrop: Sprite2D = root.get_node_or_null("Backdrop")
	if backdrop == null:
		backdrop = Sprite2D.new()
		backdrop.name = "Backdrop"
		backdrop.centered = false
		backdrop.z_index = -2
		root.add_child(backdrop)
		backdrop.owner = root
	var texture: Texture2D = load(texture_path)
	backdrop.texture = texture
	backdrop.centered = false
	var factor: float = canvas_width / texture.get_width()
	backdrop.scale = Vector2(factor, factor)


## The placeholder tiles of the stub are only a stand-in until the real picture is there.
static func _hide_placeholders(root: Node2D) -> void:
	for node_name: String in ["Ground", "Objects"]:
		var layer: CanvasItem = root.get_node_or_null(node_name)
		if layer != null:
			layer.visible = false


## A container node for generated sprites. Kept when it already exists (it belongs to the scene).
static func _container(root: Node2D, container_name: String, sorted: bool) -> Node2D:
	var container: Node2D = root.get_node_or_null(container_name)
	if container == null:
		container = Node2D.new()
		container.name = container_name
		root.add_child(container)
		container.owner = root
	container.y_sort_enabled = sorted
	return container


static func _sprite(root: Node2D, parent: Node2D, node_name: String, placement: MapPlacer.Placement) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(placement.texture)
	sprite.centered = false
	sprite.position = placement.position
	sprite.offset = placement.offset
	sprite.scale = Vector2(placement.scale, placement.scale)
	sprite.flip_h = placement.flip_h
	if placement.region.size.x > 0:
		sprite.region_enabled = true
		sprite.region_rect = Rect2(placement.region)
	sprite.add_to_group(GENERATED_GROUP, true)
	parent.add_child(sprite)
	sprite.owner = root


## Mist or light: one picture over the whole map.
static func _effect(root: Node2D, layer_name: String, node_name: String, texture_path: String, canvas_width: float, opacity: float, additive: bool) -> void:
	var layer: Node2D = root.get_node_or_null(layer_name)
	if layer == null:
		return
	layer.z_index = EFFECT_Z
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = node_name
	var texture: Texture2D = load(texture_path)
	sprite.texture = texture
	sprite.centered = false
	var factor: float = canvas_width / texture.get_width()
	sprite.scale = Vector2(factor, factor)
	sprite.modulate = Color(1.0, 1.0, 1.0, opacity)
	if additive:
		var material: CanvasItemMaterial = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = material
	sprite.add_to_group(GENERATED_GROUP, true)
	layer.add_child(sprite)
	sprite.owner = root


## The mood of the scene: darkness over everything and the flickering torches. Done once, also when the
## pictures are not there yet, so that the placeholder room is already dark. Everything is in the group
## "generated". `torches` are positions in project pixels (see MapPlacer.torch_positions).
static func dress_mood(root: Node2D, theme: String, torches: Array[Vector2], windows: Array[Vector2] = []) -> void:
	_remove_beams(root)
	for node: Node in root.get_children():
		if node.is_in_group(GENERATED_GROUP) and (node is CanvasModulate):
			root.remove_child(node)
			node.free()
	var lights_layer: Node2D = root.get_node_or_null("Lights")
	if lights_layer != null:
		for node: Node in lights_layer.get_children():
			if node.is_in_group(GENERATED_GROUP) and node is TorchFlicker:
				lights_layer.remove_child(node)
				node.free()
	if MapTheme.darkness(theme) == Color.WHITE:
		return
	var darkness: CanvasModulate = CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = MapTheme.darkness(theme)
	darkness.add_to_group(GENERATED_GROUP, true)
	root.add_child(darkness)
	darkness.owner = root
	_beams(root, windows)
	if lights_layer == null:
		return
	var index: int = 0
	for position: Vector2 in torches:
		index += 1
		var torch: TorchFlicker = TorchFlicker.new()
		torch.name = "Torch_%02d" % index
		torch.texture = LightTextures.radial()
		torch.texture_scale = LightTextures.scale_for_radius(MapTheme.torch_radius())
		torch.color = MapTheme.torch_color()
		torch.base_energy = MapTheme.torch_energy()
		torch.position = position
		torch.add_to_group(GENERATED_GROUP, true)
		lights_layer.add_child(torch)
		torch.owner = root


## A shaft of window light under each window, falling to the lower right. In the group "generated".
static func _beams(root: Node2D, windows: Array[Vector2]) -> void:
	var layer: Node2D = root.get_node_or_null("Effects")
	if layer == null:
		return
	var texture: Texture2D = LightTextures.beam()
	var size: Vector2 = MapTheme.beam_size()
	var index: int = 0
	for window: Vector2 in windows:
		index += 1
		var beam: Sprite2D = Sprite2D.new()
		beam.name = "Beam_%02d" % index
		beam.texture = texture
		beam.centered = false
		beam.offset = Vector2(-texture.get_width() / 2.0, 0.0)
		beam.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
		beam.rotation_degrees = MapTheme.beam_turn()
		beam.position = window
		beam.modulate = Color(MapTheme.beam_color(), MapTheme.beam_opacity())
		var material: CanvasItemMaterial = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		beam.material = material
		beam.add_to_group(GENERATED_GROUP, true)
		layer.add_child(beam)
		beam.owner = root


static func _remove_beams(root: Node2D) -> void:
	var layer: Node2D = root.get_node_or_null("Effects")
	if layer == null:
		return
	for node: Node in layer.get_children():
		if node.is_in_group(GENERATED_GROUP) and node.name.begins_with("Beam_"):
			layer.remove_child(node)
			node.free()
