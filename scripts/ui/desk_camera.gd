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


func _ready() -> void:
	frame.resized.connect(compose)
	compose()
	call_deferred("compose")


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
