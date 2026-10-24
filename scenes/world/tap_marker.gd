class_name TapMarker
extends Node2D
## Diamond outline shown on the tapped cell for a moment: green if the move was accepted,
## red if it was refused.

const ACCEPTED_COLOR: Color = Color(0.4, 1.0, 0.5, 1.0)
const REJECTED_COLOR: Color = Color(1.0, 0.3, 0.3, 1.0)
const VISIBLE_SECONDS: float = 0.6

@onready var _outline: Line2D = $Outline

var _tween: Tween


func _ready() -> void:
	modulate.a = 0.0


func show_at(point: Vector2, accepted: bool) -> void:
	position = point
	_outline.default_color = ACCEPTED_COLOR if accepted else REJECTED_COLOR
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, VISIBLE_SECONDS)
