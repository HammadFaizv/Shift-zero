extends Node3D

signal toggled(is_on: bool)

@export var starts_on: bool = true
@export var interaction_manager: Node
@export var body_color: Color = Color(0.16, 0.18, 0.20, 1.0)

@onready var visual_light: SpotLight3D = $Beam/VisualLight

var is_on: bool


func _ready() -> void:
	# The supplied body is pure black. Give it a readable charcoal finish,
	# keeping the original mesh, lens and red switch intact.
	for node in $Model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var material := mesh.get_active_material(0) as StandardMaterial3D
		if material != null and material.albedo_color.is_equal_approx(Color.BLACK):
			var readable := material.duplicate() as StandardMaterial3D
			readable.albedo_color = body_color
			mesh.material_override = readable
	is_on = starts_on
	_apply_state()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_torch") or event.is_echo():
		return
	if interaction_manager != null and interaction_manager.selected != null and interaction_manager.selected.tool == self:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	is_on = not is_on
	_apply_state()


func _apply_state() -> void:
	visual_light.visible = is_on
	toggled.emit(is_on)
