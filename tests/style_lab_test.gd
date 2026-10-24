class_name StyleLabTest
extends GdUnitTestSuite


func _make_lab() -> StyleLab:
	var lab: StyleLab = auto_free((load("res://scenes/lab/style_lab.tscn") as PackedScene).instantiate())
	add_child(lab)
	return lab


func test_the_lab_starts_with_daylight_off() -> void:
	assert_bool(_make_lab().is_daylight_on()).is_false()


func test_the_daylight_switch_toggles_the_glare_overlay() -> void:
	var lab: StyleLab = _make_lab()
	lab.set_daylight(true)
	assert_bool(lab.is_daylight_on()).is_true()
	lab.set_daylight(false)
	assert_bool(lab.is_daylight_on()).is_false()


func test_the_lab_button_press_switches_daylight() -> void:
	var lab: StyleLab = _make_lab()
	var button: Button = lab.get_node("Interface/DaylightButton")
	button.button_pressed = true
	assert_bool(lab.is_daylight_on()).is_true()
