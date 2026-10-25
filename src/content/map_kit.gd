class_name MapKit
extends Resource
## The pieces a region's maps are dressed with: trees, plants, rocks and ground patches, cut
## from the AI pictures by tools/art/prepare_map_assets.gd. The map placer picks from them with
## a seeded random generator, so a map looks the same every time. Widths are in project pixels
## (the size on screen at zoom 1), not in picture pixels.

@export var region: String = ""
@export var trees: Array[String] = []
@export var plants: Array[String] = []
## Big rocks stand on rock cells, small stones join objects to the ground.
@export var rocks: Array[String] = []
@export var patches: Array[String] = []

@export var tree_width: Vector2 = Vector2(155.0, 265.0)
@export var plant_width: Vector2 = Vector2(45.0, 95.0)
@export var rock_width: Vector2 = Vector2(125.0, 165.0)
@export var patch_width: Vector2 = Vector2(110.0, 180.0)
## Plants placed in front of the trunk of each tree.
@export var plants_per_tree: int = 2
## The first N rocks are big enough to stand on rock cells; the rest (small stones, a stump,
## a log) are used as decoration around objects.
@export var cell_rocks: int = 4
