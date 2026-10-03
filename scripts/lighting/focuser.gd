class_name Focuser
extends Node3D
## A small additive boost; the lens and rim never occlude gameplay rays.

signal heat_changed(progress: float, warning: bool)
signal scorched(panel: Node3D)

@export var receiver: Node3D
@export var focus_gain: float = 3.0
@export var focus_radius: float = 0.23
@export var minimum_input: float = 0.12
@export var burn_input_threshold: float = 1.1
@export var burn_seconds: float = 2.5
@export var warning_seconds: float = 0.2
@export var movement_tolerance: float = 0.002
@export var burn_radius: float = 0.19
@export var surface_height: float = 0.09

var incoming: float = 0.0
var output: float = 0.0
var heat_seconds: float = 0.0
var target: Vector3
var _last_transform: Transform3D
var _evaluator: Node3D
var _burned_here: bool = false


func _ready() -> void:
	_evaluator = get_tree().get_first_node_in_group("light_evaluator")
	_last_transform = global_transform


func optical_state() -> Array:
	return [global_transform, get_parent().is_visible_in_tree(), focus_gain, focus_radius,
		minimum_input, burn_input_threshold, burn_seconds, burn_radius]


func prepare(evaluator: Node3D) -> void:
	incoming = evaluator.incoming_at(receiver.global_position, true) if get_parent().is_visible_in_tree() else 0.0
	output = incoming * focus_gain if incoming >= minimum_input else 0.0
	target = Vector3(receiver.global_position.x, surface_height, receiver.global_position.z)


func contribution_at(point: Vector3) -> float:
	if output <= 0.0:
		return 0.0
	var distance := Vector2(point.x - target.x, point.z - target.z).length()
	if distance >= focus_radius or _evaluator.ray_blocked(receiver.global_position, point):
		return 0.0
	return output * pow(1.0 - distance / focus_radius, 0.4)


func _physics_process(delta: float) -> void:
	var moved := global_position.distance_to(_last_transform.origin) > movement_tolerance or not global_basis.is_equal_approx(_last_transform.basis)
	if moved:
		_last_transform = global_transform
		heat_seconds = 0.0
		_burned_here = false
	if not get_parent().is_visible_in_tree() or incoming < burn_input_threshold:
		heat_seconds = 0.0
	elif not _burned_here and not moved:
		heat_seconds += delta
		if heat_seconds >= burn_seconds:
			_burn()
	heat_changed.emit(clampf(heat_seconds / burn_seconds, 0.0, 1.0), heat_seconds >= warning_seconds)


func reset_heat() -> void:
	heat_seconds = 0.0
	_burned_here = false
	_last_transform = global_transform


func _burn() -> void:
	for panel in get_tree().get_nodes_in_group("evidence_panels"):
		var photo: MeshInstance3D = panel.photo
		var local := photo.to_local(target)
		var size: Vector2 = photo.mesh.size
		var uv := Vector2(local.x / size.x + 0.5, local.z / size.y + 0.5)
		if Rect2(Vector2.ZERO, Vector2.ONE).has_point(uv):
			panel.add_burn(uv, burn_radius)
			_burned_here = true
			scorched.emit(panel)
			_evaluator.refresh()
			return
