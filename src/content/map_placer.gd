class_name MapPlacer
extends RefCounted
## Decides which picture goes where on a map: trees on tree cells, rocks on rock cells, the
## building in its footprint cut into depth strips, plants and ground patches that join every
## object to the ground, and a soft shadow under the bigger ones. Pure data, no nodes: the
## result is a list of placements that tools/maps/map_dresser.gd turns into scene nodes.
##
## Everything random uses one seeded generator (the map id), so a map is dressed the same
## way every time. Positions are project pixels (a map cell is 128 x 64); sizes of pictures
## are given in picture pixels.
##
## Drawing order: a placement with layer "ground" lies flat on the ground (patches, shadows)
## and is drawn under everything else; "objects" are sorted with the hero by their `position.y`.

const LAYER_GROUND: String = "ground"
const LAYER_OBJECTS: String = "objects"
const SHADOW_SUFFIX: String = "_shadow.png"
## How a picture hangs on its position: feet are the bottom centre, centre is the middle.
const ORIGIN_FEET: Vector2 = Vector2(0.5, 1.0)
const ORIGIN_CENTRE: Vector2 = Vector2(0.5, 0.5)
## Rock pictures include some grass at their base, so their feet sit higher in the picture.
const ORIGIN_ROCK: Vector2 = Vector2(0.5, 0.9)
## Plants are skipped when a taller part of the building would cut them at a strip edge.
const PLANT_CLEARANCE: float = 3.0


class Placement extends RefCounted:
	var kind: String = ""
	var texture: String = ""
	## The node position in project pixels; for objects its y is also the sorting key.
	var position: Vector2 = Vector2.ZERO
	## Sprite offset in picture pixels, so that the picture hangs correctly on `position`.
	var offset: Vector2 = Vector2.ZERO
	var scale: float = 1.0
	var flip_h: bool = false
	## Part of the picture to show (a strip of the building); empty means the whole picture.
	var region: Rect2i = Rect2i()
	var layer: String = LAYER_OBJECTS


## `building_pictures` maps a grid symbol to the path of its picture; `sizes` maps every
## picture path (kit pieces, shadows and buildings) to its size in pixels. Missing sizes
## (a missing shadow picture) just leave that piece out.
static func build(spec: MapSpec, kit: MapKit, building_pictures: Dictionary, sizes: Dictionary) -> Array[Placement]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = spec.id.hash()
	var placements: Array[Placement] = []
	var strips: Array[Placement] = []
	for symbol: String in building_pictures:
		strips.append_array(_building(spec, symbol, building_pictures[symbol] as String, sizes, placements))
	for row: int in spec.rows:
		for col: int in spec.grid[row].length():
			var symbol: String = spec.symbol_at(row, col)
			var feet: Vector2 = MapLayout.pixel_center(row, col)
			if symbol == "T" and not kit.trees.is_empty():
				_tree(kit, feet, rng, sizes, placements, strips)
			elif symbol == "#" and kit.cell_rocks > 0 and kit.rocks.size() > 0:
				_rock(kit, feet, rng, sizes, placements)
	_plants_along_buildings(spec, kit, building_pictures, rng, sizes, placements, strips)
	placements.append_array(strips)
	return placements


static func _picture(kind: String, path: String, sizes: Dictionary, width: float, origin: Vector2) -> Placement:
	var size: Vector2i = sizes.get(path, Vector2i.ZERO)
	if size.x <= 0:
		return null
	var placement: Placement = Placement.new()
	placement.kind = kind
	placement.texture = path
	placement.scale = width / size.x
	placement.offset = -Vector2(size) * origin
	return placement


static func _random_width(range: Vector2, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(range.x, range.y)


static func _tree(kit: MapKit, feet: Vector2, rng: RandomNumberGenerator, sizes: Dictionary, placements: Array[Placement], strips: Array[Placement]) -> void:
	var base: Vector2 = feet + Vector2(0.0, 20.0)
	var path: String = kit.trees[rng.randi_range(0, kit.trees.size() - 1)]
	var width: float = _random_width(kit.tree_width, rng)
	var flip: bool = rng.randf() < 0.5
	_patch(kit, base, width * 0.9, rng, sizes, placements)
	var tree: Placement = _picture("tree", path, sizes, width, ORIGIN_FEET)
	if tree != null:
		tree.position = base
		tree.flip_h = flip
		_shadow(path, tree, sizes, placements)
		placements.append(tree)
	for _plant_index: int in kit.plants_per_tree:
		var plant: Placement = _random_plant(kit, rng, sizes)
		var spot: Vector2 = base + Vector2(rng.randf_range(-width * 0.4, width * 0.4), rng.randf_range(-5.0, 12.0))
		if plant != null:
			plant.position = spot
			plant.flip_h = rng.randf() < 0.5
			plants_in_front(plant)
			# Like the plants at the building: a plant that a taller strip would cut is left out.
			if _is_clear(plant, sizes, strips):
				placements.append(plant)


static func _rock(kit: MapKit, feet: Vector2, rng: RandomNumberGenerator, sizes: Dictionary, placements: Array[Placement]) -> void:
	var path: String = kit.rocks[rng.randi_range(0, mini(kit.cell_rocks, kit.rocks.size()) - 1)]
	var rock: Placement = _picture("rock", path, sizes, _random_width(kit.rock_width, rng), ORIGIN_ROCK)
	if rock == null:
		return
	rock.position = feet + Vector2(0.0, 15.0)
	rock.flip_h = rng.randf() < 0.5
	_shadow(path, rock, sizes, placements)
	placements.append(rock)


## A flat patch of soil or moss under an object. It lies on the ground layer.
static func _patch(kit: MapKit, centre: Vector2, width: float, rng: RandomNumberGenerator, sizes: Dictionary, placements: Array[Placement]) -> void:
	if kit.patches.is_empty():
		return
	var patch: Placement = _picture("patch", kit.patches[rng.randi_range(0, kit.patches.size() - 1)], sizes, width, ORIGIN_CENTRE)
	if patch == null:
		return
	patch.position = centre - Vector2(0.0, 12.0)
	patch.flip_h = rng.randf() < 0.5
	patch.layer = LAYER_GROUND
	placements.append(patch)


static func _random_plant(kit: MapKit, rng: RandomNumberGenerator, sizes: Dictionary) -> Placement:
	if kit.plants.is_empty():
		return null
	return _picture("plant", kit.plants[rng.randi_range(0, kit.plants.size() - 1)], sizes, _random_width(kit.plant_width, rng), ORIGIN_FEET)


## Plants sort just in front of their spot, so they stand in front of the trunk.
static func plants_in_front(plant: Placement) -> void:
	plant.position.y += 1.0


## A soft shadow picture lies on the ground to the lower right of the object, if the kit has one.
static func _shadow(path: String, owner_placement: Placement, sizes: Dictionary, placements: Array[Placement]) -> void:
	var shadow_path: String = path.trim_suffix(".png") + SHADOW_SUFFIX
	if not sizes.has(shadow_path):
		return
	var size: Vector2i = sizes[shadow_path]
	var shadow: Placement = Placement.new()
	shadow.kind = "shadow"
	shadow.texture = shadow_path
	shadow.scale = owner_placement.scale
	shadow.offset = -Vector2(size) * ORIGIN_FEET
	shadow.position = owner_placement.position
	shadow.flip_h = owner_placement.flip_h
	shadow.layer = LAYER_GROUND
	placements.append(shadow)


## The building in its footprint: one picture cut into vertical strips, each with its own sort
## key. Returns the strips, so that plants can be checked against them. A shadow of the whole
## building is added to `placements`.
static func _building(spec: MapSpec, symbol: String, path: String, sizes: Dictionary, placements: Array[Placement]) -> Array[Placement]:
	var strips: Array[Placement] = []
	var size: Vector2i = sizes.get(path, Vector2i.ZERO)
	var canvas: Rect2 = MapFootprint.canvas_rect(spec, symbol)
	var cluster: Rect2 = MapFootprint.cluster_rect(spec, symbol)
	if size.x <= 0 or canvas.size == Vector2.ZERO:
		return strips
	var scale: float = canvas.size.x / size.x
	var strip_native: float = MapFootprint.STRIP_WIDTH / scale
	var count: int = ceili(size.x / strip_native)
	for index: int in count:
		var left: int = roundi(index * strip_native)
		var right: int = mini(roundi((index + 1) * strip_native), size.x)
		var centre_x: float = canvas.position.x + (left + right) / 2.0 * scale
		# Strips beyond the footprint (roof overhang) sort like the nearest edge of the footprint.
		var front: float = MapFootprint.front_y_at(spec, symbol, clampf(centre_x, cluster.position.x + 1.0, cluster.end.x - 1.0))
		if front == -INF or right <= left:
			continue
		var strip: Placement = Placement.new()
		strip.kind = "building"
		strip.texture = path
		strip.scale = scale
		strip.region = Rect2i(left, 0, right - left, size.y)
		strip.position = Vector2(canvas.position.x + left * scale, front)
		strip.offset = Vector2(0.0, (canvas.position.y - front) / scale)
		strips.append(strip)
	var shadow_path: String = path.trim_suffix(".png") + SHADOW_SUFFIX
	if sizes.has(shadow_path):
		var shadow_size: Vector2i = sizes[shadow_path]
		var shadow: Placement = Placement.new()
		shadow.kind = "shadow"
		shadow.texture = shadow_path
		shadow.scale = scale
		shadow.offset = -Vector2(shadow_size) * ORIGIN_FEET
		# The building stands on the ground line, one margin above the bottom of its canvas.
		shadow.position = Vector2(canvas.position.x + canvas.size.x / 2.0, canvas.end.y - MapFootprint.CLUSTER_MARGIN)
		shadow.layer = LAYER_GROUND
		placements.append(shadow)
	return strips


## Plants and patches along the front of the building (the lower left and lower right edges of
## every footprint cell). A plant that a taller strip would cut is left out; its patch stays.
static func _plants_along_buildings(spec: MapSpec, kit: MapKit, building_pictures: Dictionary, rng: RandomNumberGenerator, sizes: Dictionary, placements: Array[Placement], strips: Array[Placement]) -> void:
	for symbol: String in building_pictures:
		for centre: Vector2 in MapFootprint.cell_centres(spec, symbol):
			for index: int in 3:
				var t: float = rng.randf()
				var spot: Vector2
				if index % 2 == 0:
					spot = centre + Vector2(-64.0 + 64.0 * t, 32.0 * t)
				else:
					spot = centre + Vector2(64.0 * t, 32.0 - 32.0 * t)
				if rng.randf() < 0.5:
					_patch(kit, spot, rng.randf_range(110.0, 180.0), rng, sizes, placements)
				var plant: Placement = _random_plant(kit, rng, sizes)
				if plant == null or rng.randf() >= 0.7:
					continue
				plant.position = spot
				plant.flip_h = rng.randf() < 0.5
				plants_in_front(plant)
				if _is_clear(plant, sizes, strips):
					placements.append(plant)


## True when no strip of the building that sorts in front of the plant overlaps it.
static func _is_clear(plant: Placement, sizes: Dictionary, strips: Array[Placement]) -> bool:
	var size: Vector2i = sizes.get(plant.texture, Vector2i.ZERO)
	var width: float = size.x * plant.scale
	var height: float = size.y * plant.scale
	for strip: Placement in strips:
		if strip.position.y <= plant.position.y + PLANT_CLEARANCE:
			continue
		var strip_width: float = strip.region.size.x * strip.scale
		var strip_height: float = strip.region.size.y * strip.scale
		var strip_top: float = strip.position.y + strip.offset.y * strip.scale
		var overlaps_x: bool = strip.position.x < plant.position.x + width / 2.0 and strip.position.x + strip_width > plant.position.x - width / 2.0
		var overlaps_y: bool = strip_top < plant.position.y and strip_top + strip_height > plant.position.y - height
		if overlaps_x and overlaps_y:
			return false
	return true
