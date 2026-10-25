class_name PlayerActor
extends Node2D
## Visual stand-in for the player's character. Only plays movement; it never decides
## where the character is. The Authority does that, this node just walks there.
##
## The node itself sits on the GROUND position of the cell, so drawing order (Y-sort) uses
## the feet on the ground. The picture is the child "Visual", which is raised by the level
## of the cell (32 px per level) and is what the camera follows.

signal walk_finished

## Pixels per second.
var speed: float = 360.0

var _tween: Tween

## The raised picture. Available as soon as the scene is instantiated.
var visual: Node2D:
	get:
		return $Visual


func is_walking() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## Walks through the given ground positions in order, starting from the current position.
## `lifts` holds, for each point, how many pixels the picture is raised there (the level of
## that cell times 32); leave it empty for a flat map.
func walk_along(points: Array[Vector2], lifts: Array[float] = []) -> void:
	_stop_walking()
	_tween = create_tween()
	var from: Vector2 = position
	for i: int in points.size():
		var duration: float = maxf(from.distance_to(points[i]) / speed, 0.001)
		_tween.tween_property(self, "position", points[i], duration)
		if i < lifts.size():
			_tween.parallel().tween_property(visual, "position:y", -lifts[i], duration)
		from = points[i]
	_tween.finished.connect(_on_tween_finished)


func place_at(point: Vector2, lift: float = 0.0) -> void:
	_stop_walking()
	position = point
	visual.position.y = -lift


## Cancels a walk in progress. walk_finished is still emitted, so whoever waits for it
## (the World, which ignores taps while walking) is never left waiting forever.
func _stop_walking() -> void:
	if _tween == null:
		return
	var was_walking: bool = is_walking()
	_tween.kill()
	_tween = null
	if was_walking:
		walk_finished.emit()


func _on_tween_finished() -> void:
	walk_finished.emit()
