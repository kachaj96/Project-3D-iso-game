class_name TouchGestures
extends Node
## Turns raw touch input into two things the game understands: a tap (short press that
## barely moves) and a pinch (two fingers changing distance). A press that turns into a pinch
## or a drag is never a tap, so zooming cannot send the character walking.
##
## On a phone the screen sends touch events. On a PC, "emulate touch from mouse" in the
## project settings makes mouse clicks arrive as touch events too, so one code path is used.

signal tapped(position: Vector2)
## factor > 1 zooms in (fingers apart), factor < 1 zooms out.
signal pinched(factor: float)

## A finger may move this many pixels (in viewport coordinates) and still count as a tap.
const TAP_MAX_MOVE: float = 24.0
const TAP_MAX_MS: int = 350
const WHEEL_STEP: float = 1.1

## Finger index -> {"start": Vector2, "pos": Vector2, "ms": int}
var _touches: Dictionary = {}
var _was_multi_touch: bool = false


func _unhandled_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		handle_touch(touch.index, touch.position, touch.pressed, Time.get_ticks_msec())
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null:
		handle_drag(drag.index, drag.position)
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			handle_wheel(true)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			handle_wheel(false)


func handle_touch(index: int, position: Vector2, pressed: bool, now_ms: int) -> void:
	if pressed:
		_touches[index] = {"start": position, "pos": position, "ms": now_ms}
		if _touches.size() >= 2:
			_was_multi_touch = true
		return
	if not _touches.has(index):
		return
	var touch: Dictionary = _touches[index]
	_touches.erase(index)
	var moved: float = position.distance_to(touch["start"])
	var held_ms: int = now_ms - int(touch["ms"])
	if not _was_multi_touch and moved <= TAP_MAX_MOVE and held_ms <= TAP_MAX_MS:
		tapped.emit(position)
	if _touches.is_empty():
		_was_multi_touch = false


func handle_drag(index: int, position: Vector2) -> void:
	if not _touches.has(index):
		return
	if _touches.size() == 2:
		var before: float = _finger_distance()
		_touches[index]["pos"] = position
		var after: float = _finger_distance()
		if before > 1.0:
			pinched.emit(after / before)
	else:
		_touches[index]["pos"] = position


func handle_wheel(zoom_in: bool) -> void:
	pinched.emit(WHEEL_STEP if zoom_in else 1.0 / WHEEL_STEP)


func _finger_distance() -> float:
	var positions: Array[Vector2] = []
	for index: int in _touches:
		positions.append(_touches[index]["pos"])
	return positions[0].distance_to(positions[1])
