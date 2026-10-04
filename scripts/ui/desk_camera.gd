extends Camera3D
## Fixed seated view, framed around the page beside the desktop story panel.

@export var frame: Control
@export var story_status: Control
@export var page_centre: Vector3 = Vector3(-0.3, 0.055, 0)
@export_range(5.0, 30.0) var tilt_from_vertical: float = 24.0
@export_range(5.0, 20.0) var desk_height: float = 12.0
@export_range(0.20, 0.25) var sidebar_width_fraction: float = 0.24
@export var sidebar_right_margin: float = 26.0
@export var page_vertical_offset: float = 0.3
@export var minimum_view_size: float = 2.5
@export var maximum_view_size: float = 7.8
@export var zoom_step: float = 0.8
## Head sway: moving the mouse sideways tips the view left or right; up and down tips it forward and back.
@export var sway_enabled: bool = false
@export_range(0.0, 3.0) var sway_degrees: float = 0.9
@export_range(0.0, 3.0) var tip_degrees: float = 0.8
@export_range(0.5, 20.0) var sway_smoothing: float = 3.0

var _base: Transform3D
var _lean: Vector2 = Vector2.ZERO
var _mouse: Vector2 = Vector2(0.5, 0.5) # 0..1 across the window; centred until the mouse moves


func _ready() -> void:
	frame.resized.connect(compose)
	compose()
	call_deferred("compose")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var view := get_viewport().get_visible_rect().size
		if view.x > 0.0 and view.y > 0.0:
			_mouse = (event.position / view).clamp(Vector2.ZERO, Vector2.ONE)


func _process(delta: float) -> void:
	var target := (_mouse * 2.0 - Vector2.ONE) if sway_enabled else Vector2.ZERO
	_lean = _lean.lerp(target, 1.0 - exp(-sway_smoothing * delta))
	_apply_sway()


func compose() -> void:
	if frame.size.y <= 0:
		return
	story_status.anchor_left = 1.0 - sidebar_width_fraction
	story_status.anchor_right = 1.0
	story_status.offset_left = 0.0
	story_status.offset_right = -sidebar_right_margin
	# The reserved strip includes its right margin. Centre the page in the rest.
	var units_per_pixel := size / frame.size.y
	var sideways := frame.size.x * sidebar_width_fraction * 0.5 * units_per_pixel
	var tilt := deg_to_rad(tilt_from_vertical)
	rotation = Vector3(tilt - PI * 0.5, 0, 0)
	position = page_centre + Vector3(sideways, desk_height, desk_height * tan(tilt) - page_vertical_offset)
	_base = transform
	_apply_sway()


func _apply_sway() -> void:
	if _base == Transform3D():
		return
	# Up/down tilts the view about the page; left/right rolls it about the line of sight.
	var pitch := Basis(_base.basis.x, _lean.y * deg_to_rad(sway_degrees))
	var roll := Basis(-_base.basis.z, _lean.x * deg_to_rad(tip_degrees))
	transform = Transform3D(roll * pitch * _base.basis, page_centre + pitch * (_base.origin - page_centre))


func _unhandled_input(event: InputEvent) -> void:
	if not frame.is_visible_in_tree() or not event is InputEventKey or not event.pressed:
		return
	var direction := 0.0
	if event.physical_keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
		direction = -1.0
	elif event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		direction = 1.0
	if direction == 0.0:
		return
	size = clampf(size + direction * zoom_step, minimum_view_size, maximum_view_size)
	compose()
	get_viewport().set_input_as_handled()
