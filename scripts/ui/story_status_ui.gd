extends PanelContainer

signal publish_requested
signal rings_toggled(enabled: bool)

@export var caption_font: Font
@export var caption_size: int = 18
@export var outer_padding: int = 16
@export var row_gap: int = 8
@export var caption_height: float = 43.0

var level: LevelManager
var summary: Label
var goal: Label
var segments: Array[ColorRect] = []
var rows: Array[Dictionary] = []
var rings: CheckBox
var publish_button: Button


func bind(manager: LevelManager) -> void:
	level = manager
	for child in get_children():
		remove_child(child)
		child.queue_free()
	segments.clear()
	rows.clear()
	add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.DARK, 9, Color("3a454b"), outer_padding))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", row_gap)
	add_child(column)
	var case_label := NewsroomTheme.label("THE EDITOR'S CUT  /  CASE %02d" % level.data.case_number, 12, NewsroomTheme.GOLD)
	case_label.tooltip_text = level.data.mechanic_hint
	column.add_child(case_label)
	column.add_child(NewsroomTheme.label(level.data.editor_note, 14, NewsroomTheme.GOLD, true))
	summary = NewsroomTheme.label("PANELS SPUN 0 / 4", 22)
	column.add_child(summary)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	column.add_child(bar)
	for panel in level.panels:
		var segment := ColorRect.new()
		segment.custom_minimum_size.y = 5
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(segment)
		segments.append(segment)
	for panel in level.panels:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		column.add_child(row)
		var header := HBoxContainer.new()
		row.add_child(header)
		var title := NewsroomTheme.label("%02d  %s" % [panel.number, panel.data.title], 12)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)
		var pill := NewsroomTheme.label("MURKY", 12)
		header.add_child(pill)
		var caption := NewsroomTheme.label("", caption_size, NewsroomTheme.PAPER, true)
		caption.custom_minimum_size.y = caption_height
		if caption_font != null:
			caption.add_theme_font_override("font", caption_font)
		row.add_child(caption)
		rows.append({"pill": pill, "caption": caption})
	goal = NewsroomTheme.label("", 12, NewsroomTheme.MUTED, true)
	column.add_child(goal)
	rings = CheckBox.new()
	rings.text = "Show evidence targets"
	rings.button_pressed = level.data.target_rings_default
	rings.add_theme_font_size_override("font_size", 13)
	rings.toggled.connect(func(value: bool): rings_toggled.emit(value))
	column.add_child(rings)
	publish_button = NewsroomTheme.button("PUBLISH THIS EDITION", true)
	publish_button.name = "PublishButton"
	publish_button.pressed.connect(func(): publish_requested.emit())
	column.add_child(publish_button)
	column.add_child(NewsroomTheme.label("Any edition can print.  /  F1: light readings", 11, NewsroomTheme.MUTED, true))
	if not level.panels[0].evaluator.lighting_changed.is_connected(refresh):
		level.panels[0].evaluator.lighting_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var counts := level.counts()
	summary.text = "PANELS SPUN %d / %d" % [counts["SPUN"], level.panels.size()]
	goal.text = "Deadline 6am  /  %s" % ["GOOD WORK  /  STORY READY" if level.passed() else "KEEP HALCYON IN THE RIGHT LIGHT"]
	for i in level.panels.size():
		var panel := level.panels[i]
		rows[i].pill.text = String(panel.state)
		rows[i].pill.add_theme_color_override("font_color", NewsroomTheme.STATE_COLORS[String(panel.state)])
		rows[i].caption.text = panel.caption()
		segments[i].color = NewsroomTheme.STATE_COLORS[String(panel.state)]
