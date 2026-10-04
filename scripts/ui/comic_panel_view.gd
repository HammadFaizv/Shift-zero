class_name ComicPanelView
extends Control
## One printed comic panel: the shaded photo, a thick ink border, a narration box,
## a speech balloon whose tail points at the speaker, and a sound-effect burst.

@export var lettering: Font = preload("res://Assets/fonts/Caveat.ttf")
@export var ink: Color = Color("2a1f5c")
@export var paper: Color = Color("fffdf0")
@export var narration_fill: Color = Color("ffe58a")
@export var burst_fill: Color = Color("ff6b4a")
@export var burst_text: Color = Color("fff4d6")
@export var border_width: int = 4
@export var text_per_width: float = 0.064
@export var min_text_size: int = 14
@export var max_text_size: int = 22
@export var narration_width: float = 0.82
@export var balloon_width: float = 0.44
@export var edge: float = 6.0
@export var balloon_offset: float = 0.22
@export var line_pad: float = 2.0

var photo_material: ShaderMaterial
var tag: Label
var narration: PanelContainer
var balloon: PanelContainer
var burst: Control
var _narration_label: Label
var _balloon_label: Label
var _burst_label: Label
var _tip: Vector2 = Vector2.ZERO
var _speaker_uv: Vector2 = Vector2(0.5, 0.5)
var _subjects: Array[Vector3] = [] # uv.x, uv.y, radius_uv of what the page is meant to show


func setup(panel: Dictionary, snapshot: Dictionary, photo_shader: Shader, original: bool) -> void:
	var photo_size: Vector2 = panel.photo.get_size()
	set_meta("aspect", photo_size.x / photo_size.y)
	clip_contents = false
	var frame := Control.new()
	frame.clip_contents = true
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var photo := TextureRect.new()
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	photo.texture = panel.photo
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_SCALE
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_material = ShaderMaterial.new()
	photo_material.shader = photo_shader
	photo_material.set_shader_parameter("light_map", snapshot.light_map)
	photo_material.set_shader_parameter("burn_map", snapshot.burn_map)
	photo_material.set_shader_parameter("light_uv_rect", panel.uv_rect)
	for key in ["hidden_threshold", "visible_threshold", "hidden_opacity", "murky_opacity", "posterize_steps", "color_boost", "comic_brightness", "edge_strength", "edge_threshold", "halftone_spacing", "ink_color"]:
		photo_material.set_shader_parameter(key, snapshot[key])
	photo.material = photo_material
	frame.add_child(photo)
	var border := Panel.new()
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color.TRANSPARENT
	border_style.border_color = ink
	border_style.set_border_width_all(border_width)
	border.add_theme_stylebox_override("panel", border_style)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	_speaker_uv = _speaker(panel)
	for poi in panel.pois:
		if poi.desired == POIData.Desired.VISIBLE or (panel.state == &"DAMNING" and poi.type == POIData.Type.HERO):
			_subjects.append(Vector3(poi.position_uv.x, poi.position_uv.y, 0.07))
	narration = _note_box(narration_fill, 3, 2)
	_narration_label = _lettering(String(panel.caption), ink)
	narration.add_child(_narration_label)
	add_child(narration)
	narration.visible = not String(panel.caption).is_empty()
	balloon = _note_box(paper, 16, 2)
	_balloon_label = _lettering(String(panel.balloon), ink)
	_balloon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balloon.add_child(_balloon_label)
	balloon.draw.connect(_draw_tail)
	add_child(balloon)
	balloon.visible = not String(panel.balloon).is_empty()
	burst = Control.new()
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.draw.connect(_draw_burst)
	_burst_label = _lettering(String(panel.sfx), burst_text)
	_burst_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_burst_label.add_theme_color_override("font_outline_color", ink)
	_burst_label.add_theme_constant_override("outline_size", 6)
	burst.add_child(_burst_label)
	add_child(burst)
	burst.visible = not String(panel.sfx).is_empty()
	tag = NewsroomTheme.label("ORIGINAL EVIDENCE", 11, Color("fff4d6"))
	tag.add_theme_stylebox_override("normal", NewsroomTheme.box(ink, 3, Color.TRANSPARENT, 3))
	tag.position = Vector2(8, 8)
	tag.visible = original
	add_child(tag)
	resized.connect(_layout)
	_layout.call_deferred()


func set_revealed(amount: float) -> void:
	for node in [narration, balloon, burst]:
		node.modulate.a = amount


func pop_in(seconds: float) -> Tween:
	var tween := create_tween().set_parallel(true)
	for node in [narration, balloon, burst]:
		if not node.visible:
			continue
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2(0.6, 0.6)
		tween.tween_property(node, "modulate:a", 1.0, seconds)
		tween.tween_property(node, "scale", Vector2.ONE, seconds * 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Who is talking: the hero when he is in frame (or caught in print), else the first lit subject.
func _speaker(panel: Dictionary) -> Vector2:
	var fallback := Vector2(0.5, 0.45)
	var found := false
	for poi in panel.pois:
		if poi.type == POIData.Type.HERO and (panel.state == &"DAMNING" or poi.desired == POIData.Desired.VISIBLE):
			return poi.position_uv
		if not found and poi.desired == POIData.Desired.VISIBLE:
			fallback = poi.position_uv
			found = true
	return fallback


func _note_box(fill: Color, radius: int, border: int) -> PanelContainer:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = ink
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


func _lettering(text: String, color: Color) -> Label:
	var label := NewsroomTheme.label(text, 16, color, true)
	label.add_theme_font_override("font", lettering)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## How many of the subjects this rectangle would cover (the speaker's own spot excluded).
func _cost(rect: Rect2, skip: Vector2 = Vector2(-1, -1)) -> float:
	var total := 0.0
	for subject in _subjects:
		if skip.is_equal_approx(Vector2(subject.x, subject.y)):
			continue
		var centre := Vector2(subject.x, subject.y) * size
		if rect.grow(subject.z * size.x).has_point(centre):
			total += 1.0
	return total


func _layout() -> void:
	if size.x < 10.0 or narration == null:
		return
	var w := size.x
	var h := size.y
	var font_size := clampi(roundi(w * text_per_width), min_text_size, max_text_size)
	for label in [_narration_label, _balloon_label]:
		label.add_theme_font_size_override("font_size", font_size)
	_burst_label.add_theme_font_size_override("font_size", roundi(font_size * 1.25))
	var nsize := _fit(narration, _narration_label, w * narration_width, font_size)
	var bsize := _fit(balloon, _balloon_label, w * balloon_width, font_size)
	# Caption along the top or bottom edge, whichever hides fewer subjects.
	var top := Rect2(Vector2(edge, edge), nsize)
	var bottom := Rect2(Vector2(edge, h - nsize.y - edge), nsize)
	var speaker_high := _speaker_uv.y < 0.5
	var caption := bottom if _cost(bottom) < _cost(top) or (_cost(bottom) == _cost(top) and speaker_high) else top
	narration.position = caption.position
	# Balloon above or below the speaker, clear of the caption and other subjects.
	var speaker := _speaker_uv * size
	var bx := clampf(speaker.x - bsize.x * 0.5, edge, maxf(w - bsize.x - edge, edge))
	var best := Vector2.ZERO
	var best_cost := INF
	for above in [true, false]:
		var y := speaker.y - h * balloon_offset - bsize.y if above else speaker.y + h * balloon_offset
		var at := Vector2(bx, clampf(y, edge, maxf(h - bsize.y - edge, edge)))
		var cost := _cost(Rect2(at, bsize), _speaker_uv) + (10.0 if Rect2(at, bsize).grow(2.0).intersects(caption) else 0.0)
		if cost < best_cost:
			best_cost = cost
			best = at
	balloon.position = best
	_tip = speaker - balloon.position
	balloon.queue_redraw()
	var burst_size := _burst_label.get_combined_minimum_size()
	_burst_label.size = burst_size
	burst.size = burst_size * 1.6
	_burst_label.position = (burst.size - burst_size) * 0.5
	burst.pivot_offset = burst.size * 0.5
	burst.rotation = -0.09
	# The burst takes whichever corner is clearest of the caption, balloon and subjects.
	var corners: Array[Vector2] = [Vector2(w - burst.size.x - edge, edge), Vector2(w - burst.size.x - edge, h - burst.size.y - edge),
		Vector2(edge, edge), Vector2(edge, h - burst.size.y - edge)]
	var burst_at := corners[0]
	var burst_cost := INF
	for corner in corners:
		var rect := Rect2(corner, burst.size)
		var cost := _cost(rect) + (10.0 if rect.intersects(caption) else 0.0) + (10.0 if balloon.visible and rect.intersects(Rect2(balloon.position, bsize)) else 0.0)
		if cost < burst_cost:
			burst_cost = cost
			burst_at = corner
	burst.position = burst_at


## Wrapped label height is not known to the container until after layout, so measure it here.
func _fit(box: PanelContainer, label: Label, width: float, font_size: int) -> Vector2:
	var inner := width - 14.0
	var text_size := lettering.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, inner, font_size)
	label.custom_minimum_size = Vector2(inner, ceilf(text_size.y) + line_pad)
	box.reset_size()
	box.size = box.get_combined_minimum_size()
	return box.size


func _draw_tail() -> void:
	var size_now := balloon.size
	var tip := _tip
	var below := tip.y > size_now.y + 8.0
	var above := tip.y < -8.0
	if not below and not above:
		return
	var base_x := clampf(tip.x, 18.0, maxf(size_now.x - 18.0, 18.0))
	var base_y := size_now.y - 1.0 if below else 1.0
	var reach := clampf(tip.y - base_y, -22.0, 22.0)
	var point := Vector2(base_x + clampf(tip.x - base_x, -8.0, 8.0), base_y + reach)
	var left := Vector2(base_x - 8.0, base_y)
	var right := Vector2(base_x + 8.0, base_y)
	balloon.draw_colored_polygon(PackedVector2Array([left, point, right]), paper)
	balloon.draw_polyline(PackedVector2Array([left, point, right]), ink, 2.0, true)
	balloon.draw_line(left + Vector2(1, 0), right - Vector2(1, 0), paper, 3.0)


func _draw_burst() -> void:
	var centre := burst.size * 0.5
	var points := PackedVector2Array()
	var spikes := 12
	for i in spikes * 2:
		var radius := 0.5 if i % 2 == 0 else 0.34
		var angle := TAU * i / (spikes * 2.0)
		points.append(centre + Vector2(cos(angle) * burst.size.x * radius, sin(angle) * burst.size.y * radius * 1.05))
	burst.draw_colored_polygon(points, burst_fill)
	points.append(points[0])
	burst.draw_polyline(points, ink, 2.5, true)
