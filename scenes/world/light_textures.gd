class_name LightTextures
extends RefCounted
## The soft round picture a 2D light uses: bright in the middle, fading smoothly to nothing at the
## edge. Made in code, so there is no file to keep in step.

const SIZE: int = 256


## A white disc that fades out. The light's `texture_scale` sets how big it is on screen:
## radius in pixels = SIZE / 2 * texture_scale.
static func radial() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = SIZE
	texture.height = SIZE
	return texture


## The scale that gives a light of this radius in pixels.
static func scale_for_radius(radius: float) -> float:
	return radius / (SIZE / 2.0)
