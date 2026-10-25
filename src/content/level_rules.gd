class_name LevelRules
extends RefCounted
## Which steps between neighbouring cells are allowed when a map has levels (D-020).
## One place for the rules, used by the pathfinder and by map validation.
##
## A cell has a level 0 to 7 (one level is 32 px on screen) and may be a "stairs" or
## "ladder" cell. A stairs or ladder cell has the level of its LOWER end.
##   - same level: any step is allowed
##   - stairs: lead up by exactly 1 level
##   - ladder: leads up by 1 to 4 levels (one storey)
##   - every other change of level is forbidden, and a diagonal step never changes level
## The rules are symmetric: a step is allowed exactly when the step back is allowed.

const MAX_LEVEL: int = 7
const KIND_STAIRS: String = "stairs"
const KIND_LADDER: String = "ladder"
const STAIRS_RISE: int = 1
const LADDER_RISE: int = 4

## Extra cost of entering a cell, so the path finder prefers stairs and avoids ladders
## unless they are the only way. Plain cells and stairs cost 1.
const STAIRS_WEIGHT: float = 1.0
const LADDER_WEIGHT: float = 3.0


## True when a character may step from a cell to a neighbour. `kind` is "", "stairs" or "ladder".
static func can_step(height_from: int, kind_from: String, height_to: int, kind_to: String, diagonal: bool) -> bool:
	var difference: int = height_to - height_from
	if difference == 0:
		return true
	if diagonal:
		return false
	if difference > 0:
		return difference <= max_rise(kind_from)
	return -difference <= max_rise(kind_to)


## How many levels up a cell of this kind can lead from its own level.
static func max_rise(kind: String) -> int:
	match kind:
		KIND_STAIRS:
			return STAIRS_RISE
		KIND_LADDER:
			return LADDER_RISE
	return 0


## Cost multiplier for entering a cell of this kind.
static func weight(kind: String) -> float:
	return LADDER_WEIGHT if kind == KIND_LADDER else STAIRS_WEIGHT


static func is_climbing_kind(kind: String) -> bool:
	return kind == KIND_STAIRS or kind == KIND_LADDER
