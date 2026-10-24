class_name MapExit
extends Resource
## A group of cells that leads to another map. Stepping on any of them moves the
## character to target_entry_cell on target_map_id.

@export var cells: Array[Vector2i] = []
@export var target_map_id: String = ""
@export var target_entry_cell: Vector2i = Vector2i.ZERO
