class_name TorchFlicker
extends PointLight2D
## A torch flame: the light gets a little stronger and weaker all the time, never in a regular
## rhythm. Several slow and fast waves with a random start are added, so that two torches do not
## flicker together.

@export var base_energy: float = 1.3
## How much of the energy may be lost at the darkest moment, 0 to 1.
@export var flicker: float = 0.22
@export var speed: float = 1.0

var _phase: Array[float] = []
var _time: float = 0.0


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for index: int in 3:
		_phase.append(rng.randf() * TAU)
	energy = base_energy


func _process(delta: float) -> void:
	_time += delta * speed
	var wave: float = (sin(_time * 7.3 + _phase[0]) + sin(_time * 12.1 + _phase[1]) * 0.6 + sin(_time * 2.2 + _phase[2]) * 0.8) / 2.4
	energy = base_energy * (1.0 - flicker * (0.5 - 0.5 * wave))
