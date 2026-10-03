class_name LightEvaluator
extends Node3D
## The only light sampling entry point, shared by POIs and the ink preview.

signal lighting_changed

@export_range(0.0, 1.0) var ambient: float = 0.05
@export_range(0.0, 1.0) var hidden_threshold: float = 0.30
@export_range(0.0, 1.0) var visible_threshold: float = 0.55
@export_flags_3d_physics var occluder_mask: int = 2

var revision: int = 0
var _lights: Array[GameplayLight] = []
var _active_lights: Array[GameplayLight] = []
var _occluders: Array[LightOccluder] = []
var _redirectors: Array[Redirector] = []
var _focusers: Array[Focuser] = []
var _active_redirectors: Array[Redirector] = []
var _active_focusers: Array[Focuser] = []
var _previous_state: Array = []
var _awaiting_physics_sync: bool = false
var _bounds: Array[Vector4] = []
var _ray := PhysicsRayQueryParameters3D.new()
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	for light in get_tree().get_nodes_in_group("gameplay_lights"):
		_lights.append(light as GameplayLight)
	for body in get_tree().get_nodes_in_group("light_occluders"):
		_occluders.append(body as LightOccluder)
	for optic in get_tree().get_nodes_in_group("light_redirectors"):
		_redirectors.append(optic as Redirector)
	for optic in get_tree().get_nodes_in_group("light_focusers"):
		_focusers.append(optic as Focuser)
	_ray.collision_mask = occluder_mask
	_ray.hit_from_inside = true
	_space = get_world_3d().direct_space_state


func _physics_process(_delta: float) -> void:
	var current: Array = [ambient, hidden_threshold, visible_threshold, occluder_mask]
	for light in _lights:
		current.append(light.state())
	for occluder in _occluders:
		current.append(occluder.state())
	for optic in _redirectors:
		current.append(optic.optical_state())
	for optic in _focusers:
		current.append(optic.optical_state())
	if current == _previous_state:
		# A drag updates node transforms before the physics query space catches
		# up. Resample once on the following step so a resting shadow cannot
		# retain the previous pose's reading indefinitely.
		if _awaiting_physics_sync:
			_awaiting_physics_sync = false
			refresh()
		return
	_previous_state = current
	_awaiting_physics_sync = true
	refresh()


func refresh() -> void:
	_ray.collision_mask = occluder_mask
	_active_lights.clear()
	for light in _lights:
		light.refresh()
		if light.visual_light.is_visible_in_tree() and light.intensity > 0.0:
			_active_lights.append(light)
	_bounds.clear()
	for body in _occluders:
		if not (body.collision_layer & occluder_mask):
			continue
		var centre: Vector3 = body.global_transform * body.bounds_center
		var scale := body.global_basis.get_scale().abs()
		var radius: float = body.bounds_radius * maxf(scale.x, maxf(scale.y, scale.z))
		_bounds.append(Vector4(centre.x, centre.y, centre.z, radius * radius))
	# One transfer per pair: glasses receive direct light; magnifiers can also
	# receive redirected light. No feedback or recursive beam multiplication.
	_active_redirectors.clear()
	for optic in _redirectors:
		optic.prepare(self)
		if optic.output > 0.0:
			_active_redirectors.append(optic)
	_active_focusers.clear()
	for optic in _focusers:
		optic.prepare(self)
		if optic.output > 0.0:
			_active_focusers.append(optic)
	# Explicit order also holds after replacing a case's POI nodes.
	for poi in get_tree().get_nodes_in_group("evidence_pois"):
		poi.refresh()
	for panel in get_tree().get_nodes_in_group("evidence_panels"):
		panel.refresh()
	revision += 1
	lighting_changed.emit()


func light_at(point: Vector3) -> float:
	var value := ambient + incoming_at(point, true)
	for optic in _active_focusers:
		value += optic.contribution_at(point)
	return clampf(value, 0.0, 1.0)


func incoming_at(point: Vector3, include_redirected: bool = false) -> float:
	var value := 0.0
	for light in _active_lights:
		var contribution := light.contribution_at(point)
		if contribution > 0.0 and not _blocked(light.origin, point):
			value += contribution
	if include_redirected:
		for optic in _active_redirectors:
			var contribution := optic.contribution_at(point)
			if contribution > 0.0 and not _blocked(optic.origin, point):
				value += contribution
	return value


func ray_blocked(from: Vector3, to: Vector3) -> bool:
	return _blocked(from, to)


func classify(value: float) -> String:
	if value < hidden_threshold:
		return "HIDDEN"
	if value < visible_threshold:
		return "MURKY"
	return "VISIBLE"


func _blocked(from: Vector3, to: Vector3) -> bool:
	var direction := to - from
	var length_squared := direction.length_squared()
	if is_zero_approx(length_squared):
		return false
	for bound in _bounds:
		var centre := Vector3(bound.x, bound.y, bound.z)
		var t := clampf((centre - from).dot(direction) / length_squared, 0.0, 1.0)
		if centre.distance_squared_to(from + direction * t) <= bound.w:
			_ray.from = from
			_ray.to = to
			return not _space.intersect_ray(_ray).is_empty()
	return false
