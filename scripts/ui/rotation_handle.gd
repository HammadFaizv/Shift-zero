extends Control
## A projected handle uses the same desk-plane mouse mapping as tool dragging.

@export var manager: Node3D
@export var handle_radius: float = 0.95
@export var pick_radius: float = 16.0
@export var line_width: float = 2.0
@export var color: Color = Color(1, 0.75, 0.27, 1)
@export var ring_segments: int = 24
@export var label_size: int = 10

var _rotating: bool = false


func _process(_delta: float) -> void:
	queue_redraw()


func _handle_position() -> Vector2:
	var tool: Node3D = manager.selected.tool
	return get_viewport().get_camera_3d().unproject_position(tool.global_position + tool.global_basis.x * handle_radius)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or manager.selected == null or manager.selected.rotatable() == null:
		_rotating = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.distance_to(_handle_position()) <= pick_radius:
			_rotating = true
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			_rotating = false
	if _rotating and event is InputEventMouseMotion:
		var camera := get_viewport().get_camera_3d()
		var tool: Node3D = manager.selected.tool
		var plane := Plane(Vector3.UP, tool.global_position.y)
		var point: Variant = plane.intersects_ray(camera.project_ray_origin(event.position), camera.project_ray_normal(event.position))
		if point != null:
			var direction: Vector3 = point - tool.global_position
			tool.rotation.y = atan2(-direction.z, direction.x)
			tool.force_update_transform()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if manager.selected == null or manager.selected.rotatable() == null:
		return
	var camera := get_viewport().get_camera_3d()
	var centre := camera.unproject_position(manager.selected.tool.global_position)
	var handle := _handle_position()
	draw_line(centre, handle, color, line_width, true)
	draw_circle(handle, pick_radius * 0.65, NewsroomTheme.DARK)
	draw_arc(handle, pick_radius * 0.65, 0, TAU, ring_segments, color, line_width, true)
	draw_string(NewsroomTheme.portable_font(), handle + Vector2(-34, -20), "DRAG TO AIM", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, color)
