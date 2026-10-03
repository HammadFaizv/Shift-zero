extends Node3D
## Ceiling switch. GameplayLight follows the VisualLight visibility.

signal toggled(is_on: bool)

@export var starts_on: bool = true
@export_flags_3d_physics var cord_collision_mask: int = 8
@export_range(1.0, 100.0) var pick_distance: float = 50.0
@export var on_label: String = "CEILING ON  /  L"
@export var off_label: String = "CEILING OFF  /  L"

@onready var visual_light: OmniLight3D = $VisualLight
@onready var status: Label3D = $Status

var is_on: bool


func _ready() -> void:
	is_on = starts_on
	_apply_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_ceiling") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_action_pressed("select"):
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			return
		var origin := camera.project_ray_origin(event.position)
		var end := origin + camera.project_ray_normal(event.position) * pick_distance
		var query := PhysicsRayQueryParameters3D.create(origin, end, cord_collision_mask)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.get("collider") == $PullCord/Handle:
			toggle()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	is_on = not is_on
	_apply_state()


func _apply_state() -> void:
	visual_light.visible = is_on
	status.text = on_label if is_on else off_label
	toggled.emit(is_on)
