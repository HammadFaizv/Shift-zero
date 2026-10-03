class_name Redirector
extends GameplayLight
## Predictable game optics. Only direct lights energise this beam.

@export var receiver: Node3D
@export var transfer_efficiency: float = 0.9
@export var minimum_input: float = 0.12
@export var maximum_output: float = 1.4
@export var visual_energy_scale: float = 3.0

var incoming: float = 0.0
var output: float = 0.0


func optical_state() -> Array:
	return [global_transform, get_parent().is_visible_in_tree(), transfer_efficiency,
		minimum_input, maximum_output, intensity, falloff, cone_falloff,
		visual_light.spot_range, visual_light.spot_angle]


func prepare(evaluator: Node3D) -> void:
	incoming = evaluator.incoming_at(receiver.global_position) if get_parent().is_visible_in_tree() else 0.0
	output = minf(incoming * transfer_efficiency, maximum_output) if incoming >= minimum_input else 0.0
	visual_light.visible = output > 0.0
	visual_light.light_energy = output * visual_energy_scale
	refresh()


func contribution_at(point: Vector3) -> float:
	return super.contribution_at(point) * output
