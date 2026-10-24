class_name TouchGesturesTest
extends GdUnitTestSuite

var _gestures: TouchGestures
var _taps: Array[Vector2]
var _pinches: Array[float]


func before_test() -> void:
	_gestures = auto_free(TouchGestures.new())
	_taps = []
	_pinches = []
	_gestures.tapped.connect(func(position: Vector2) -> void: _taps.append(position))
	_gestures.pinched.connect(func(factor: float) -> void: _pinches.append(factor))


func test_short_press_without_movement_is_a_tap() -> void:
	_gestures.handle_touch(0, Vector2(100, 100), true, 1000)
	_gestures.handle_touch(0, Vector2(103, 101), false, 1120)
	assert_array(_taps).is_equal([Vector2(103, 101)])


func test_press_that_moves_far_is_not_a_tap() -> void:
	_gestures.handle_touch(0, Vector2(100, 100), true, 1000)
	_gestures.handle_drag(0, Vector2(200, 100))
	_gestures.handle_touch(0, Vector2(200, 100), false, 1100)
	assert_array(_taps).is_empty()


func test_long_press_is_not_a_tap() -> void:
	_gestures.handle_touch(0, Vector2(100, 100), true, 1000)
	_gestures.handle_touch(0, Vector2(100, 100), false, 1500)
	assert_array(_taps).is_empty()


func test_two_fingers_apart_zoom_in() -> void:
	_gestures.handle_touch(0, Vector2(100, 200), true, 1000)
	_gestures.handle_touch(1, Vector2(200, 200), true, 1010)
	_gestures.handle_drag(1, Vector2(300, 200))
	assert_int(_pinches.size()).is_equal(1)
	assert_float(_pinches[0]).is_equal_approx(2.0, 0.001)


func test_two_fingers_together_zoom_out() -> void:
	_gestures.handle_touch(0, Vector2(100, 200), true, 1000)
	_gestures.handle_touch(1, Vector2(300, 200), true, 1010)
	_gestures.handle_drag(1, Vector2(200, 200))
	assert_float(_pinches[0]).is_equal_approx(0.5, 0.001)


func test_lifting_fingers_after_a_pinch_does_not_tap() -> void:
	_gestures.handle_touch(0, Vector2(100, 200), true, 1000)
	_gestures.handle_touch(1, Vector2(200, 200), true, 1010)
	_gestures.handle_drag(1, Vector2(210, 200))
	_gestures.handle_touch(1, Vector2(210, 200), false, 1050)
	_gestures.handle_touch(0, Vector2(100, 200), false, 1060)
	assert_array(_taps).is_empty()


func test_a_normal_tap_works_again_after_a_pinch() -> void:
	_gestures.handle_touch(0, Vector2(100, 200), true, 1000)
	_gestures.handle_touch(1, Vector2(200, 200), true, 1010)
	_gestures.handle_touch(1, Vector2(200, 200), false, 1050)
	_gestures.handle_touch(0, Vector2(100, 200), false, 1060)
	_gestures.handle_touch(0, Vector2(50, 60), true, 2000)
	_gestures.handle_touch(0, Vector2(50, 60), false, 2100)
	assert_array(_taps).is_equal([Vector2(50, 60)])


func test_one_finger_drag_does_not_pinch() -> void:
	_gestures.handle_touch(0, Vector2(100, 200), true, 1000)
	_gestures.handle_drag(0, Vector2(300, 200))
	assert_array(_pinches).is_empty()


func test_mouse_wheel_zooms_in_steps() -> void:
	_gestures.handle_wheel(true)
	_gestures.handle_wheel(false)
	assert_float(_pinches[0]).is_equal_approx(1.1, 0.001)
	assert_float(_pinches[1]).is_equal_approx(1.0 / 1.1, 0.001)
