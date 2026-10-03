extends PanelContainer

@export var row_font_size: int = 15
@export var hidden_color: Color = Color("b5a5ec")
@export var murky_color: Color = Color("dfb967")
@export var visible_color: Color = Color("85c5b1")

var _pois: Array[EvidencePOI] = []
var _rows: Array[Label] = []
var _evaluator: LightEvaluator


func _ready() -> void:
	_evaluator = get_tree().get_first_node_in_group("light_evaluator") as LightEvaluator
	refresh_sources()
	_evaluator.lighting_changed.connect(refresh)


func refresh_sources() -> void:
	for label in _rows:
		label.get_parent().remove_child(label)
		label.queue_free()
	_rows.clear()
	_pois.clear()
	for node in get_tree().get_nodes_in_group("evidence_pois"):
		var poi := node as EvidencePOI
		_pois.append(poi)
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", row_font_size)
		$Margin/Rows.add_child(label)
		_rows.append(label)


func refresh() -> void:
	$Margin/Rows/Thresholds.text = "H1–H4: hero / E1–E4: evidence\nHidden < %.0f%% / Visible >= %.0f%%" % [_evaluator.hidden_threshold * 100.0, _evaluator.visible_threshold * 100.0]
	for i in _pois.size():
		var poi := _pois[i]
		# Truncate the percentage so rounding cannot cross a state boundary.
		var percentage := floorf(poi.data.current_light * 1000.0) / 10.0
		_rows[i].text = "%s  /  %s\n%.1f%%   %s" % [poi.data.id, poi.data.description, percentage, poi.light_state]
		var color := visible_color
		if poi.light_state == "HIDDEN":
			color = hidden_color
		elif poi.light_state == "MURKY":
			color = murky_color
		_rows[i].add_theme_color_override("font_color", color)
