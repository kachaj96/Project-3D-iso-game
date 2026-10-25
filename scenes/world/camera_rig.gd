class_name CameraRig
extends Camera2D
## Camera that follows a target, stays inside the map and zooms within limits.
## Presentation only: it never touches game state.

## Zoom 1.0 shows one pixel of the world per screen pixel.
@export var max_zoom: float = 2.0
@export var default_zoom: float = 1.0
## Extra room above and below the map diamond, for the height of blocks and obstacles.
@export var vertical_margin: float = 64.0
## The camera looks at this point above the target's feet, roughly its body centre.
@export var look_offset: Vector2 = Vector2(0, -30)

var target: Node2D

var _bounds: Rect2 = Rect2()
var _min_zoom: float = 0.5


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	limit_smoothed = true
	get_viewport().size_changed.connect(_update_min_zoom)
	_update_min_zoom()
	set_zoom_level(default_zoom)


func _process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position + look_offset


## The area in world pixels the camera may show (the map's rectangle). `margin` is the extra room
## above and below; a negative value means the default `vertical_margin`. A screen-shaped map is the
## picture itself, so it gets no margin: the camera never shows what lies outside the picture.
func set_map_bounds(bounds: Rect2, margin: float = -1.0) -> void:
	var extra: float = vertical_margin if margin < 0.0 else margin
	_bounds = bounds.grow_individual(0.0, extra, 0.0, extra)
	limit_left = floori(_bounds.position.x)
	limit_top = floori(_bounds.position.y)
	limit_right = ceili(_bounds.end.x)
	limit_bottom = ceili(_bounds.end.y)
	_update_min_zoom()
	set_zoom_level(zoom.x)


## Jumps to the target without the smooth glide, for example after a map change.
func snap_to_target() -> void:
	if target != null:
		global_position = target.global_position + look_offset
	reset_smoothing()


func zoom_by(factor: float) -> void:
	set_zoom_level(zoom.x * factor)


func set_zoom_level(value: float) -> void:
	var level: float = clampf(value, _min_zoom, maxf(max_zoom, _min_zoom))
	zoom = Vector2(level, level)


func min_zoom() -> float:
	return _min_zoom


## The smallest zoom that still fills the whole screen with map, so no grey edge is shown.
func _update_min_zoom() -> void:
	if _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		_min_zoom = 0.25
		return
	var view: Vector2 = get_viewport_rect().size
	_min_zoom = maxf(view.x / _bounds.size.x, view.y / _bounds.size.y)
	set_zoom_level(zoom.x)
