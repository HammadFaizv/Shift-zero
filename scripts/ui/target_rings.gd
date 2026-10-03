extends Control

@export var ring_scale: float = 1.6
@export var line_width: float = 1.5
@export var label_size: int = 11
@export var ring_segments: int = 32

var enabled: bool = true
var pois: Array[EvidencePOI] = []
var evaluator: LightEvaluator
var camera: Camera3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera = get_viewport().get_camera_3d()
	evaluator = get_tree().get_first_node_in_group("light_evaluator") as LightEvaluator
	refresh_sources()
	evaluator.lighting_changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func refresh_sources() -> void:
	pois.clear()
	for poi in get_tree().get_nodes_in_group("evidence_pois"):
		pois.append(poi as EvidencePOI)
	queue_redraw()


func set_enabled(value: bool) -> void:
	enabled = value
	queue_redraw()


func _draw() -> void:
	if not enabled or camera == null:
		return
	var font := ThemeDB.fallback_font
	for poi in pois:
		var hero := poi.data.desired == POIData.Desired.VISIBLE
		var satisfied := poi.light_state == ("VISIBLE" if hero else "HIDDEN")
		var light_hint := "LIGHT HIM" if poi.data.type == POIData.Type.HERO else "LIGHT THEM" if poi.data.type == POIData.Type.VICTIM else "LIGHT THIS"
		var text := ("LIT" if satisfied else light_hint) if hero else ("HIDDEN" if satisfied else "HIDE")
		if poi.data.burned:
			text = "BURNED"
		var color := NewsroomTheme.STATE_COLORS["SPUN"] as Color if satisfied else NewsroomTheme.GOLD
		if not hero and not satisfied:
			color = NewsroomTheme.STATE_COLORS["DAMNING"]
		if poi.data.burned:
			color = NewsroomTheme.STATE_COLORS["TAMPERED"]
		var size := (poi.photo.mesh as PlaneMesh).size * poi.data.radius_uv * ring_scale
		var points := PackedVector2Array()
		for i in ring_segments + 1:
			var angle := TAU * float(i) / ring_segments
			points.append(camera.unproject_position(poi.global_position + Vector3(cos(angle) * size.x, 0, sin(angle) * size.y)))
		draw_polyline(points, color, line_width, true)
		var centre := camera.unproject_position(poi.global_position + Vector3(0, 0, -size.y))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size)
		var start := centre - Vector2(text_size.x * 0.5, 5)
		draw_rect(Rect2(start - Vector2(3, text_size.y), text_size + Vector2(6, 5)), NewsroomTheme.DARK)
		draw_string(font, start, text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, color)
