extends PanelContainer

signal publish_requested
signal rings_toggled(enabled: bool)

const PILL_WORDS: Dictionary = {"SPUN": "CLEAN", "DAMNING": "SHOWING", "MURKY": "UNCLEAR", "TAMPERED": "SCORCHED"}

@export var caption_font: Font
@export var caption_size: int = 18
@export var headline_size: int = 26
@export var outer_padding: int = 16
@export var row_gap: int = 8
@export var caption_height: float = 22.0
@export var tone_colors: Dictionary = {"good": Color("85c5b1"), "warn": Color("e7a15c"), "bad": Color("f17e72"), "calm": Color("dfb967")}
@export var quiet_seconds: float = 0.8

var level: LevelManager
var headline: Label
var standing_fill: ColorRect
var standing_track: Control
var segments: Array[ColorRect] = []
var rows: Array[Dictionary] = []
var rings: CheckBox
var publish_button: Button
var _satisfied: int = -1
var _quiet_until: int = 0


func bind(manager: LevelManager) -> void:
	level = manager
	for child in get_children():
		remove_child(child)
		child.queue_free()
	segments.clear()
	rows.clear()
	_satisfied = -1
	_quiet_until = Time.get_ticks_msec() + int(quiet_seconds * 1000.0)
	add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.DARK, 9, Color("3a454b"), outer_padding))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", row_gap)
	add_child(column)
	var case_label := NewsroomTheme.label("THE EDITOR'S CUT  /  CASE %02d  /  6 AM" % level.data.case_number, 12, NewsroomTheme.GOLD)
	case_label.tooltip_text = level.data.mechanic_hint
	column.add_child(case_label)
	column.add_child(NewsroomTheme.label(level.data.editor_note, 14, NewsroomTheme.GOLD, true))
	headline = NewsroomTheme.label("", headline_size, NewsroomTheme.PAPER, true)
	if caption_font != null:
		headline.add_theme_font_override("font", caption_font)
	column.add_child(headline)
	standing_track = Control.new()
	standing_track.custom_minimum_size.y = 6
	standing_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track_back := ColorRect.new()
	track_back.color = Color("26333b")
	track_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	standing_track.add_child(track_back)
	standing_fill = ColorRect.new()
	standing_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	standing_fill.anchor_right = 0.0
	standing_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	standing_track.add_child(standing_fill)
	column.add_child(standing_track)
	for panel in level.panels:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)
		var header := HBoxContainer.new()
		row.add_child(header)
		var title := NewsroomTheme.label("%02d  %s" % [panel.number, panel.data.title], 12)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)
		var pill := NewsroomTheme.label("", 12)
		header.add_child(pill)
		var caption := NewsroomTheme.label("", caption_size, NewsroomTheme.PAPER, true)
		caption.custom_minimum_size.y = caption_height
		if caption_font != null:
			caption.add_theme_font_override("font", caption_font)
		row.add_child(caption)
		rows.append({"pill": pill, "caption": caption})
	rings = CheckBox.new()
	rings.text = "Show the editor's pencil marks"
	rings.button_pressed = level.data.target_rings_default
	rings.add_theme_font_size_override("font_size", 13)
	rings.toggled.connect(func(value: bool):
		Sfx.click()
		rings_toggled.emit(value))
	column.add_child(rings)
	publish_button = NewsroomTheme.button("PUBLISH THIS EDITION", true)
	publish_button.name = "PublishButton"
	publish_button.pressed.connect(func(): publish_requested.emit())
	column.add_child(publish_button)
	column.add_child(NewsroomTheme.label("Any edition can print.  /  F1: light readings  /  M: mute", 11, NewsroomTheme.MUTED, true))
	if not level.panels[0].evaluator.lighting_changed.is_connected(refresh):
		level.panels[0].evaluator.lighting_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var evaluator := level.panels[0].evaluator
	var hidden := evaluator.hidden_threshold
	var visible_at := evaluator.visible_threshold
	var datas: Array[PanelData] = []
	for panel in level.panels:
		datas.append(panel.data)
	var read := Reputation.headline(datas, hidden, visible_at)
	headline.text = read.text
	headline.add_theme_color_override("font_color", tone_colors[read.tone])
	var standing := Reputation.score(Reputation.records_from(datas), hidden, visible_at) / 100.0
	standing_fill.anchor_right = standing
	standing_fill.color = tone_colors["bad"].lerp(tone_colors["good"], standing)
	standing_track.tooltip_text = "How Halcyon stands with readers."
	var satisfied := 0
	for i in level.panels.size():
		var panel := level.panels[i]
		for poi in panel.data.pois:
			if Reputation.is_satisfied(poi, hidden, visible_at):
				satisfied += 1
		rows[i].pill.text = PILL_WORDS[String(panel.state)]
		rows[i].pill.add_theme_color_override("font_color", NewsroomTheme.STATE_COLORS[String(panel.state)])
		rows[i].caption.text = _note(panel, hidden, visible_at)
	if _satisfied >= 0 and satisfied != _satisfied and Time.get_ticks_msec() > _quiet_until:
		Sfx.pop(1.1 if satisfied > _satisfied else 0.75)
	_satisfied = satisfied


## One handwritten line per print: self-justification when clean, the loose thread when not.
func _note(panel: EvidencePanel, hidden: float, visible_at: float) -> String:
	match String(panel.state):
		"SPUN":
			return panel.data.rationale if not panel.data.rationale.is_empty() else "Nothing to see here."
		"TAMPERED":
			return "Scorched. This print is ruined. Restart the case for a fresh copy."
		"DAMNING":
			var exposed: Array[POIData] = []
			for poi in panel.data.pois:
				if Reputation.is_exposed(poi, hidden):
					exposed.append(poi)
			return "Still showing: " + _group(exposed)
		_:
			var dark: Array[POIData] = []
			for poi in panel.data.pois:
				if poi.desired == POIData.Desired.VISIBLE and not Reputation.is_satisfied(poi, hidden, visible_at):
					dark.append(poi)
			return "Not clear yet: " + _group(dark, false)


## Names collapse by series ("falling bill x5") and then by tier, heaviest first:
## "hero head (devastating), hero dialogue (serious), fleeing man, fleeing woman (minor)."
func _group(pois: Array[POIData], with_tier: bool = true) -> String:
	var counts: Dictionary = {}
	var weights: Dictionary = {}
	var order: PackedStringArray = []
	for poi in pois:
		var key := poi.description.rstrip("0123456789 ")
		if not counts.has(key):
			order.append(key)
			counts[key] = 0
			weights[key] = 0.0
		counts[key] += 1
		weights[key] = maxf(weights[key], poi.importance)
	if not with_tier:
		return ", ".join(_names(order, counts)) + "."
	var parts := PackedStringArray()
	for tier in [Reputation.Tier.DEVASTATING, Reputation.Tier.SERIOUS, Reputation.Tier.MINOR]:
		var members := PackedStringArray()
		for key in order:
			if Reputation.tier(weights[key]) == tier:
				members.append(key)
		if not members.is_empty():
			parts.append("%s (%s)" % [", ".join(_names(members, counts)), Reputation.TIER_WORDS[tier]])
	return ", ".join(parts) + "."


func _names(keys: PackedStringArray, counts: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	for key in keys:
		names.append(key.to_lower() + (" x%d" % counts[key] if counts[key] > 1 else ""))
	return names
