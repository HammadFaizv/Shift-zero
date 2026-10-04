extends Control
## The editor's grease-pencil marks on the prints: a loop round each subject and
## a small symbol, no words. Gold sun = still needs light, green tick = lit,
## red open eye = exposed, slashed eye = safely hidden. Line weight and a second
## loop show how badly a subject would hurt Halcyon if it printed.

@export var ring_scale: float = 1.55
@export var ring_segments: int = 44
@export var wobble: float = 0.07
@export var minor_width: float = 1.8
@export var serious_width: float = 2.8
@export var devastating_width: float = 3.6
@export var glyph_size: float = 8.0
@export var underlay_alpha: float = 0.5
@export var settled_alpha: float = 0.4
@export var pulse_speed: float = 4.0
@export var wanted_color: Color = Color("e4b85c")
@export var settled_color: Color = Color("85c5b1")
@export var danger_color: Color = Color("f17e72")
@export var burned_color: Color = Color("c0a0e8")

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


func _process(_delta: float) -> void:
	if enabled and is_visible_in_tree():
		queue_redraw()


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
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * pulse_speed)
	for poi in pois:
		var data := poi.data
		var wants_light := data.desired == POIData.Desired.VISIBLE
		var settled := Reputation.is_satisfied(data, evaluator.hidden_threshold, evaluator.visible_threshold)
		var color := wanted_color if wants_light else danger_color
		var alpha := 1.0
		if data.burned:
			color = burned_color
		elif settled:
			color = settled_color
			alpha = settled_alpha
		elif not wants_light:
			alpha = 0.7 + 0.3 * pulse
		color.a = alpha
		var tier := Reputation.tier(data.importance)
		var width := [minor_width, serious_width, devastating_width][tier] as float
		var size := (poi.photo.mesh as PlaneMesh).size * data.radius_uv * ring_scale
		var phase := float(hash(String(data.id)) % 628) * 0.01
		_loop(poi.global_position, size, phase, color, width)
		if tier == Reputation.Tier.DEVASTATING and not settled:
			_loop(poi.global_position, size * 1.24, phase + 1.7, color, width * 0.7)
		var corner := camera.unproject_position(poi.global_position + Vector3(size.x, 0, -size.y) * 0.95)
		if data.burned:
			_cross(corner, color)
		elif wants_light:
			_tick(corner, color) if settled else _sun(corner, color)
		else:
			_eye(corner, color, settled)


func _loop(centre: Vector3, size: Vector2, phase: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in ring_segments + 1:
		var t := float(i) / ring_segments
		var angle := t * TAU * 1.06 + phase
		var swell := 1.0 + wobble * sin(3.0 * angle + phase) + wobble * 0.6 * sin(5.0 * angle + 2.0 * phase) + t * 0.05
		points.append(camera.unproject_position(centre + Vector3(cos(angle) * size.x * swell, 0, sin(angle) * size.y * swell)))
	_pencil(points, color, width)


func _pencil(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, Color(0.04, 0.05, 0.07, underlay_alpha * color.a), width + 2.5, true)
	draw_polyline(points, color, width, true)


func _sun(at: Vector2, color: Color) -> void:
	var ring := PackedVector2Array()
	for i in 13:
		ring.append(at + Vector2.from_angle(TAU * i / 12.0) * glyph_size * 0.45)
	_pencil(ring, color, 1.8)
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0)
		_pencil(PackedVector2Array([at + direction * glyph_size * 0.75, at + direction * glyph_size * 1.1]), color, 1.8)


func _tick(at: Vector2, color: Color) -> void:
	_pencil(PackedVector2Array([at + Vector2(-1, 0.1) * glyph_size, at + Vector2(-0.3, 0.8) * glyph_size, at + Vector2(1, -0.8) * glyph_size]), color, 2.4)


func _cross(at: Vector2, color: Color) -> void:
	_pencil(PackedVector2Array([at + Vector2(-1, -1) * glyph_size * 0.7, at + Vector2(1, 1) * glyph_size * 0.7]), color, 2.4)
	_pencil(PackedVector2Array([at + Vector2(1, -1) * glyph_size * 0.7, at + Vector2(-1, 1) * glyph_size * 0.7]), color, 2.4)


func _eye(at: Vector2, color: Color, slashed: bool) -> void:
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in 9:
		var x := lerpf(-1.0, 1.0, i / 8.0)
		var lift := 0.55 * (1.0 - x * x)
		upper.append(at + Vector2(x, -lift) * glyph_size * 1.1)
		lower.append(at + Vector2(x, lift) * glyph_size * 1.1)
	_pencil(upper, color, 1.8)
	_pencil(lower, color, 1.8)
	var pupil := PackedVector2Array()
	for i in 13:
		pupil.append(at + Vector2.from_angle(TAU * i / 12.0) * glyph_size * 0.28)
	_pencil(pupil, color, 1.8)
	if slashed:
		_pencil(PackedVector2Array([at + Vector2(-1.0, 0.85) * glyph_size, at + Vector2(1.0, -0.85) * glyph_size]), color, 2.4)
