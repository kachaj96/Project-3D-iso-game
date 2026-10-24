class_name ExampleTest
extends GdUnitTestSuite
## First test: proves the test runner works. Replace with real rule tests later.


func test_clamp_int_limits_value_to_range() -> void:
	assert_int(MathUtil.clamp_int(15, 0, 10)).is_equal(10)
	assert_int(MathUtil.clamp_int(-3, 0, 10)).is_equal(0)
	assert_int(MathUtil.clamp_int(5, 0, 10)).is_equal(5)
