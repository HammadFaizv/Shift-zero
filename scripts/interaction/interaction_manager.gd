extends Node3D

@export var desk_bounds: Rect2 = Rect2(-6.0, -4.0, 12.0, 8.0)
@export var drag_plane_height: float = 0.0
@export_flags_3d_physics var pick_mask: int = 9
@export_flags_3d_physics var cord_mask: int = 8
@export var pick_distance: float = 50.0
@export var hint_label: Label
@export var idle_hint: String = "L / red cord: ceiling light    |    Click and drag a tool"
@export var selected_hint: String = "%s    |    Drag to move    |    Right click / Esc: deselect"
@export var rotation_hint: String = "    |    Q/E / wheel: rotate"
@export var toggle_hint: String = "    |    Space / double-click: on/off"

var selected: DraggableObject
var hovered: DraggableObject
var _dragging: bool = false
var _mouse: Vector2
var _grab_offset: Vector3
var _rotate_left: bool = false
var _rotate_right: bool = false


func _ready() -> void:
	_mouse = get_viewport().get_mouse_position()
	_update_hint()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = event.position
	# Release must stop dragging even if a Control consumes the event.
	if event is InputEventMouseButton and event.is_action_released("select"):
		_dragging = false
	if event.is_action_released("rotate_left"):
		_rotate_left = false
	if event.is_action_released("rotate_right"):
		_rotate_right = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("deselect"):
		_select(null)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_mouse = event.position
		if event.is_action_pressed("select"):
			var hit := _pick(_mouse)
			# Leave the cord event available to the ceiling controller.
			if hit != null and hit.collision_layer & cord_mask:
				return
			var component: DraggableObject = null
			if hit != null:
				component = hit.get_parent().get_node_or_null("Draggable") as DraggableObject
			_select(component)
			if selected != null and event.double_click and selected.tool.has_method("toggle"):
				selected.tool.call("toggle")
				get_viewport().set_input_as_handled()
				return
			var point: Variant = _point_on_desk(_mouse)
			if selected != null and point != null:
				_grab_offset = selected.tool.global_position - point
				_grab_offset.y = 0.0
				_dragging = true
			get_viewport().set_input_as_handled()
		elif selected != null and selected.rotatable() != null:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				selected.rotatable().rotate_step(1.0)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				selected.rotatable().rotate_step(-1.0)
				get_viewport().set_input_as_handled()
	elif selected != null:
		if event.is_action_pressed("rotate_left"):
			_rotate_left = true
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("rotate_right"):
			_rotate_right = true
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _dragging and selected != null:
		var point: Variant = _point_on_desk(_mouse)
		if point != null:
			selected.move_to(point + _grab_offset, desk_bounds)
	if selected != null and selected.rotatable() != null:
		selected.rotatable().rotate_continuously(float(_rotate_left) - float(_rotate_right), delta)
	var hit := _pick(_mouse)
	var next_hover: DraggableObject = null
	if hit != null:
		next_hover = hit.get_parent().get_node_or_null("Draggable") as DraggableObject
	if next_hover != hovered:
		if hovered != null:
			hovered.set_hovered(false)
		hovered = next_hover
		if hovered != null:
			hovered.set_hovered(true)


func _pick(screen_point: Vector2) -> CollisionObject3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not get_viewport().get_visible_rect().has_point(screen_point):
		return null
	var from := camera.project_ray_origin(screen_point)
	var to := from + camera.project_ray_normal(screen_point) * pick_distance
	var query := PhysicsRayQueryParameters3D.create(from, to, pick_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") as CollisionObject3D


func _point_on_desk(screen_point: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	return Plane(Vector3.UP, drag_plane_height).intersects_ray(camera.project_ray_origin(screen_point), camera.project_ray_normal(screen_point))


func _select(component: DraggableObject) -> void:
	_dragging = false
	_rotate_left = false
	_rotate_right = false
	if selected != null:
		selected.set_selected(false)
	selected = component
	if selected != null:
		selected.set_selected(true)
	if hovered != null:
		hovered.set_hovered(hovered != selected)
	_update_hint()


func deselect() -> void:
	_select(null)


func _update_hint() -> void:
	if hint_label == null:
		return
	hint_label.text = idle_hint if selected == null else selected_hint % selected.display_name
	if selected != null and selected.rotatable() != null:
		hint_label.text += rotation_hint
	if selected != null and not selected.usage_hint.is_empty():
		hint_label.text = selected.display_name + "  |  " + selected.usage_hint + rotation_hint
	if selected != null and selected.tool.has_method("toggle"):
		hint_label.text += toggle_hint
