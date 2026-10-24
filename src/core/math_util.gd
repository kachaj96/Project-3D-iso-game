class_name MathUtil
extends RefCounted
## Tiny pure helpers. Example target for the first unit test.


## Returns value limited to the range [low, high].
static func clamp_int(value: int, low: int, high: int) -> int:
	return maxi(low, mini(value, high))
