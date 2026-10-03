class_name GameplayLight
extends Node3D
## Gameplay values use the visual light's exact origin, direction and cone.

@export var visual_light: Light3D
@export_range(0.0, 8.0) var intensity: float = 1.6
@export_range(0.1, 8.0) var falloff: float = 2.0
@export_range(0.1, 8.0) var cone_falloff: float = 0.6

var origin: Vector3
var _direction: Vector3
var _range: float
var _cos_cone: float
var _enabled: bool
var _is_spot: bool


func state() -> Array:
	if visual_light is SpotLight3D:
		return [visual_light.global_transform, visual_light.is_visible_in_tree(), visual_light.spot_range, visual_light.spot_angle, intensity, falloff, cone_falloff]
	return [visual_light.global_transform, visual_light.is_visible_in_tree(), visual_light.omni_range, intensity, falloff]


func refresh() -> void:
	origin = visual_light.global_position
	_direction = -visual_light.global_basis.z.normalized()
	_enabled = visual_light.is_visible_in_tree()
	_is_spot = visual_light is SpotLight3D
	_range = visual_light.spot_range if _is_spot else visual_light.omni_range
	_cos_cone = cos(deg_to_rad(visual_light.spot_angle)) if _is_spot else -1.0


func contribution_at(point: Vector3) -> float:
	if not _enabled:
		return 0.0
	var offset := point - origin
	var distance := offset.length()
	if distance >= _range or is_zero_approx(_range):
		return 0.0
	var cone_strength := 1.0
	if _is_spot and not is_zero_approx(distance):
		var alignment := _direction.dot(offset / distance)
		if alignment <= _cos_cone:
			return 0.0
		cone_strength = pow((alignment - _cos_cone) / (1.0 - _cos_cone), cone_falloff)
	return intensity * pow(1.0 - distance / _range, falloff) * cone_strength
