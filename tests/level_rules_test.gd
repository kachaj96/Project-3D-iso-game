class_name LevelRulesTest
extends GdUnitTestSuite

const KINDS: Array[String] = ["", "stairs", "ladder"]


func test_steps_on_the_same_level_are_always_allowed() -> void:
	for kind_a: String in KINDS:
		for kind_b: String in KINDS:
			for diagonal: bool in [false, true]:
				assert_bool(LevelRules.can_step(3, kind_a, 3, kind_b, diagonal)).is_true()


func test_plain_cells_never_change_level() -> void:
	assert_bool(LevelRules.can_step(0, "", 1, "", false)).is_false()
	assert_bool(LevelRules.can_step(1, "", 0, "", false)).is_false()
	assert_bool(LevelRules.can_step(0, "", 4, "", false)).is_false()


func test_stairs_lead_up_by_exactly_one_level() -> void:
	assert_bool(LevelRules.can_step(2, "stairs", 3, "", false)).is_true()
	assert_bool(LevelRules.can_step(2, "stairs", 4, "", false)).is_false()
	assert_bool(LevelRules.can_step(2, "stairs", 1, "", false)).is_false()


func test_walking_down_onto_the_stairs_is_allowed() -> void:
	assert_bool(LevelRules.can_step(3, "", 2, "stairs", false)).is_true()
	assert_bool(LevelRules.can_step(4, "", 2, "stairs", false)).is_false()


func test_a_ladder_leads_up_one_to_four_levels() -> void:
	for rise: int in [1, 2, 3, 4]:
		assert_bool(LevelRules.can_step(0, "ladder", rise, "", false)).is_true()
		assert_bool(LevelRules.can_step(rise, "", 0, "ladder", false)).is_true()
	assert_bool(LevelRules.can_step(0, "ladder", 5, "", false)).is_false()
	assert_bool(LevelRules.can_step(5, "", 0, "ladder", false)).is_false()


func test_a_ladder_cannot_be_used_the_wrong_way() -> void:
	# The ladder cell has the level of its lower end, so a ladder cell above cannot lead down.
	assert_bool(LevelRules.can_step(4, "ladder", 2, "", false)).is_false()


func test_a_diagonal_step_never_changes_level() -> void:
	assert_bool(LevelRules.can_step(0, "stairs", 1, "", true)).is_false()
	assert_bool(LevelRules.can_step(0, "ladder", 3, "", true)).is_false()
	assert_bool(LevelRules.can_step(3, "", 0, "ladder", true)).is_false()


func test_every_step_is_allowed_exactly_when_the_step_back_is() -> void:
	for height_a: int in range(0, LevelRules.MAX_LEVEL + 1):
		for height_b: int in range(0, LevelRules.MAX_LEVEL + 1):
			for kind_a: String in KINDS:
				for kind_b: String in KINDS:
					for diagonal: bool in [false, true]:
						var forward: bool = LevelRules.can_step(height_a, kind_a, height_b, kind_b, diagonal)
						var back: bool = LevelRules.can_step(height_b, kind_b, height_a, kind_a, diagonal)
						assert_bool(forward).is_equal(back)


func test_max_rise_and_weights() -> void:
	assert_int(LevelRules.max_rise("")).is_equal(0)
	assert_int(LevelRules.max_rise("stairs")).is_equal(1)
	assert_int(LevelRules.max_rise("ladder")).is_equal(4)
	assert_float(LevelRules.weight("")).is_equal(1.0)
	assert_float(LevelRules.weight("stairs")).is_equal(1.0)
	assert_float(LevelRules.weight("ladder")).is_equal(3.0)
	assert_bool(LevelRules.is_climbing_kind("ladder")).is_true()
	assert_bool(LevelRules.is_climbing_kind("")).is_false()
