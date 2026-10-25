class_name MapTheme
extends RefCounted
## What a map's mood means in the scene: how dark it is, the colour and strength of the mist and
## the light shafts. The theme name is the `theme:` of the map file. Pure data.
##
## "forest": daylight under trees, almost no darkening.
## "dark_interior": a room lit by a few torches and cold light from high windows. Dark on purpose:
## the room is nearly black outside the pools of light.

const FOREST: String = "forest"
const DARK_INTERIOR: String = "dark_interior"


## The colour the whole scene is multiplied with. White means no darkening.
static func darkness(theme: String) -> Color:
	if theme == DARK_INTERIOR:
		return Color(0.2, 0.22, 0.3, 1.0)
	return Color.WHITE


static func mist_tint(theme: String) -> Color:
	if theme == DARK_INTERIOR:
		return Color(0.45, 0.55, 0.62, 1.0)
	return Color(0.62, 0.72, 0.78, 1.0)


static func mist_opacity(theme: String) -> float:
	return 0.55 if theme == DARK_INTERIOR else 0.4


static func light_tint(theme: String) -> Color:
	if theme == DARK_INTERIOR:
		return Color(0.65, 0.8, 1.0, 1.0)
	return Color(1.0, 0.86, 0.55, 1.0)


static func light_opacity(theme: String) -> float:
	return 0.5 if theme == DARK_INTERIOR else 0.45


## Strength and colour of a wall torch.
static func torch_color() -> Color:
	return Color(1.0, 0.55, 0.2, 1.0)


static func torch_energy() -> float:
	return 1.3


## Radius of the pool of torch light on the floor in project pixels.
static func torch_radius() -> float:
	return 330.0
