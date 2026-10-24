class_name PlayerActor
extends Node2D
## Visual stand-in for the player's character. Only plays movement; it never decides
## where the character is. The Authority does that, this node just walks there.

signal walk_finished

## Pixels per second.
var speed: float = 360.0

var _tween: Tween


func is_walking() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## Walks through the given pixel positions in order, starting from the current position.
func walk_along(points: Array[Vector2]) -> void:
	_stop_walking()
	_tween = create_tween()
	var from: Vector2 = position
	for point: Vector2 in points:
		_tween.tween_property(self, "position", point, maxf(from.distance_to(point) / speed, 0.001))
		from = point
	_tween.finished.connect(_on_tween_finished)


func place_at(point: Vector2) -> void:
	_stop_walking()
	position = point


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
