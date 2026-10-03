extends Control

signal chosen(choice: StringName)
signal cancelled

@export var dialog_size: Vector2 = Vector2(680, 330)
@export var heading_size: int = 27

var edited_button: Button
var original_button: Button
var cancel_button: Button


func _ready() -> void:
	var scrim := ColorRect.new()
	scrim.color = Color(0.025, 0.035, 0.05, 0.9)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -dialog_size.x * 0.5
	panel.offset_right = dialog_size.x * 0.5
	panel.offset_top = -dialog_size.y * 0.5
	panel.offset_bottom = dialog_size.y * 0.5
	panel.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.DARK, 12, NewsroomTheme.GOLD, 24))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(NewsroomTheme.label("5:59 AM / THE LAST EDITION", 12, NewsroomTheme.GOLD))
	column.add_child(NewsroomTheme.label("What will the city see?", heading_size))
	column.add_child(NewsroomTheme.label("Your edited page is ready. The original evidence photographs are still here. Choose which edition reaches the city.", 17, NewsroomTheme.PAPER, true))
	edited_button = NewsroomTheme.button("PUBLISH EDITED STORY", true)
	original_button = NewsroomTheme.button("PUBLISH ORIGINAL PHOTOS")
	cancel_button = NewsroomTheme.button("KEEP WORKING AT THE DESK")
	for button in [edited_button, original_button, cancel_button]:
		column.add_child(button)
	edited_button.pressed.connect(func(): chosen.emit(&"edited"))
	original_button.pressed.connect(func(): chosen.emit(&"original"))
	cancel_button.pressed.connect(func(): cancelled.emit())
