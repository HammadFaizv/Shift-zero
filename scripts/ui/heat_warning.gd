extends Label
## Screen-space warning stays readable independently of the desk camera scale.

@export var focus: Focuser
@export var story_status: Control
@export var warning_width: float = 330.0
@export var vertical_offset: float = 70.0
@export var edge_margin: float = 16.0
@export var warning_font_size: int = 18


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = warning_width
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_override("font", NewsroomTheme.portable_font())
	add_theme_font_size_override("font_size", warning_font_size)
	add_theme_color_override("font_color", NewsroomTheme.GOLD)
	add_theme_stylebox_override("normal", NewsroomTheme.box(NewsroomTheme.DARK, 8, NewsroomTheme.GOLD, 8))
	focus.heat_changed.connect(show_heat)
	hide()


func show_heat(progress: float, hot: bool) -> void:
	visible = hot and focus.get_parent().is_visible_in_tree()
	if not visible:
		return
	text = "TOO HOT — MOVE IT! %d%%" % roundi(progress * 100.0) if progress < 1.0 else "SCORCHED — RESTART CASE"
	var point := get_viewport().get_camera_3d().unproject_position(focus.target)
	position.x = clampf(point.x - warning_width * 0.5, edge_margin, story_status.position.x - warning_width - edge_margin)
	position.y = clampf(point.y - vertical_offset, edge_margin, get_parent().size.y - size.y - vertical_offset)
