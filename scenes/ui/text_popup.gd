class_name TextPopup
extends CanvasLayer
## A box at the bottom of the screen that shows one translated text, for example a sign.
## It is hidden at start. The text always comes from a translation key.

signal closed

@onready var _label: Label = $Panel/Margin/Content/Text
@onready var _close_button: Button = $Panel/Margin/Content/CloseButton


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)


func is_open() -> bool:
	return visible


## Shows the translation of text_key in the player's current language.
func show_key(text_key: String) -> void:
	_label.text = tr(text_key)
	_close_button.text = tr("ui.popup.close")
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
