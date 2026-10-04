class_name DeskSnail
extends Node3D
## A snail that crawls a small circle on the left of the desk, wearing a "don't click" note.
## Click it and a pistol slides in, fires, and leaves a patch of green goo that dries away.

## Turn the snail on or off. Setting it true again brings a fresh one back.
@export var snail_on_table: bool = true:
	set(value):
		snail_on_table = value
		if is_node_ready():
			_sync()
@export var snail_model: PackedScene = preload("res://Assets/free_stylized_low_poly_snail.glb")
@export var gun_model: PackedScene = preload("res://Assets/low_poly_gun.glb")
@export_group("Roaming")
## Desk-space x/z box the roam circle's centre is drawn from. Keep it on the left, clear of the sticky notes and the left-hand tools.
@export var spawn_zone: Rect2 = Rect2(-4.8, -1.3, 0.3, 1.5)
@export_range(0.15, 1.0) var roam_radius_min: float = 0.28
@export_range(0.15, 1.0) var roam_radius_max: float = 0.4
@export var snail_length: float = 0.7
@export var crawl_speed: float = 0.08
@export var turn_speed: float = 2.5
@export var pause_seconds: Vector2 = Vector2(0.6, 2.0)
@export_group("Note")
@export var note_text: String = "don't\nclick"
@export var note_size: Vector2 = Vector2(0.4, 0.27)
@export var note_color: Color = Color(0.96, 0.92, 0.7)
@export var note_ink: Color = Color(0.5, 0.07, 0.05)
@export_group("Shot")
@export var gun_length: float = 1.5
## Where the gun hangs relative to the snail (x right, y up, z toward the viewer).
@export var gun_offset: Vector3 = Vector3(1.25, 0.9, 0.55)
@export var gun_entry: Vector3 = Vector3(3.0, 0.6, 0.0)
@export var slide_seconds: float = 0.35
@export var aim_seconds: float = 0.45
@export var recoil: float = 0.16
@export var screen_flash: float = 0.45
@export var goo_size: float = 1.6
@export var goo_hold_seconds: float = 1.0
@export var goo_fade_seconds: float = 3.5
@export_flags_3d_physics var pick_layer: int = 16

var _snail: Node3D
var _body: Node3D
var _pick: StaticBody3D
var _height: float = 0.5
var _centre: Vector3
var _radius: float = 0.4
var _target: Vector3
var _heading: float = 0.0
var _pause: float = 0.0
var _clock: float = 0.0
var _busy: bool = false


func _ready() -> void:
	_sync()


func _sync() -> void:
	if snail_on_table and _snail == null and not _busy:
		_spawn()
	elif not snail_on_table and _snail != null:
		_snail.queue_free()
		_snail = null


func _spawn() -> void:
	_radius = randf_range(roam_radius_min, roam_radius_max)
	_centre = Vector3(randf_range(spawn_zone.position.x, spawn_zone.end.x), 0.0, randf_range(spawn_zone.position.y, spawn_zone.end.y))
	_snail = Node3D.new()
	_snail.name = "Snail"
	add_child(_snail)
	_body = Node3D.new()
	_snail.add_child(_body)
	var model: Node3D = snail_model.instantiate()
	_body.add_child(model)
	var box := _bounds(model)
	var fit := snail_length / box.size.x
	model.scale = Vector3.ONE * fit
	model.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * fit
	_height = box.size.y * fit
	_snail.position = _centre + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)) * _radius
	_heading = randf() * TAU
	_pick_target()
	_body.rotation.y = _heading
	_build_note()
	_pick = StaticBody3D.new()
	_pick.collision_layer = pick_layer
	_pick.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = snail_length * 0.5
	shape.shape = sphere
	shape.position.y = sphere.radius * 0.8
	_pick.add_child(shape)
	_snail.add_child(_pick)


func _build_note() -> void:
	var note := Node3D.new()
	note.name = "Note"
	note.position = Vector3(0.0, _height + 0.03, 0.0)
	note.rotation_degrees = Vector3(randf_range(-4.0, 4.0), randf_range(-14.0, 14.0), randf_range(-4.0, 4.0))
	_snail.add_child(note)
	var paper := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(note_size.x, 0.012, note_size.y)
	var material := StandardMaterial3D.new()
	material.albedo_color = note_color
	material.roughness = 0.9
	mesh.material = material
	paper.mesh = mesh
	note.add_child(paper)
	var text := Label3D.new()
	text.text = note_text
	text.rotation_degrees.x = -90.0
	text.position.y = 0.008
	text.pixel_size = 0.0027
	text.font_size = 38
	text.outline_size = 0
	text.modulate = note_ink
	text.double_sided = false
	note.add_child(text)


func _process(delta: float) -> void:
	_clock += delta
	if _snail == null or _busy:
		return
	_body.scale.y = 1.0 + 0.03 * sin(_clock * 3.0)
	if _pause > 0.0:
		_pause -= delta
		return
	var to := _target - _snail.position
	to.y = 0.0
	if to.length() < 0.04:
		_pause = randf_range(pause_seconds.x, pause_seconds.y)
		_pick_target()
		return
	# Model forward is -x: heading h faces (-cos h, +sin h) on the desk plane.
	_heading = lerp_angle(_heading, atan2(to.z, -to.x), 1.0 - exp(-turn_speed * delta))
	_body.rotation.y = _heading
	var forward := Vector3(-cos(_heading), 0.0, sin(_heading))
	var alignment := maxf(forward.dot(to.normalized()), 0.0)
	var next := _snail.position + forward * crawl_speed * alignment * delta
	var out := next - _centre
	out.y = 0.0
	if out.length() > _radius:
		next = _centre + out.normalized() * _radius
		_pick_target()
	_snail.position = next


func _pick_target() -> void:
	var angle := randf() * TAU
	_target = _centre + Vector3(cos(angle), 0.0, sin(angle)) * _radius * sqrt(randf()) * 0.9


func _unhandled_input(event: InputEvent) -> void:
	if _snail == null or _busy:
		return
	if event is InputEventMouseButton and event.is_action_pressed("select") and _hits_snail(event.position):
		get_viewport().set_input_as_handled()
		_shoot()


func _hits_snail(point: Vector2) -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	var from := camera.project_ray_origin(point)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(point) * 50.0, pick_layer)
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider") == _pick


func _shoot() -> void:
	_busy = true
	var victim := _snail
	_snail = null
	var spot := victim.global_position
	var aim := spot + Vector3(0.0, _height * 0.4, 0.0)
	Sfx.click()
	var gun := _make_gun()
	var rest := aim + gun_offset
	gun.root.position = to_local(rest + gun_entry)
	gun.root.look_at(rest + gun_entry + (aim - rest), Vector3.UP)
	Sfx.swoosh()
	await create_tween().tween_property(gun.root, "position", to_local(rest), slide_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).finished
	await get_tree().create_timer(aim_seconds).timeout
	Sfx.shot()
	_flash(gun.muzzle)
	var kick: Vector3 = to_local(rest) + (gun.root.global_basis * Vector3(0, 0, recoil))
	var recoiling := create_tween()
	recoiling.tween_property(gun.root, "position", kick, 0.06).set_ease(Tween.EASE_OUT)
	recoiling.tween_property(gun.root, "position", to_local(rest), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	victim.queue_free()
	_splat(spot)
	await get_tree().create_timer(0.7).timeout
	Sfx.swoosh()
	await create_tween().tween_property(gun.root, "position", to_local(rest + gun_entry), slide_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).finished
	gun.root.queue_free()
	_busy = false


## Returns {root, muzzle}: the gun scaled to gun_length, its muzzle along -z so look_at aims it.
func _make_gun() -> Dictionary:
	var root := Node3D.new()
	root.name = "Pistol"
	add_child(root)
	var pivot := Node3D.new()
	pivot.rotation.y = PI
	root.add_child(pivot)
	var model: Node3D = gun_model.instantiate()
	pivot.add_child(model)
	var box := _bounds(model)
	var fit := gun_length / box.size.z
	model.scale = Vector3.ONE * fit
	model.position = -box.get_center() * fit
	var muzzle := Node3D.new()
	var tip := Vector3(box.get_center().x, box.position.y + box.size.y * 0.75, box.end.z)
	muzzle.position = pivot.transform * ((tip - box.get_center()) * fit)
	root.add_child(muzzle)
	return {"root": root, "muzzle": muzzle}


func _flash(muzzle: Node3D) -> void:
	var camera := get_viewport().get_camera_3d()
	var star := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 1.1
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/muzzle_flash.gdshader")
	quad.material = material
	star.mesh = quad
	star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle.add_child(star)
	if camera != null:
		star.global_basis = camera.global_basis
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.45)
	light.light_energy = 9.0
	light.omni_range = 4.0
	muzzle.add_child(light)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(light, "light_energy", 0.0, 0.16)
	tween.tween_method(func(value: float): material.set_shader_parameter("intensity", value), 1.4, 0.0, 0.16)
	tween.tween_property(star, "scale", Vector3.ONE * 1.5, 0.16)
	tween.chain().tween_callback(star.queue_free)
	tween.tween_callback(light.queue_free)
	var layer := CanvasLayer.new()
	layer.layer = 20
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, screen_flash)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(white)
	add_child(layer)
	var fade := create_tween()
	fade.tween_property(white, "color:a", 0.0, 0.22).set_ease(Tween.EASE_OUT)
	fade.tween_callback(layer.queue_free)


func _splat(spot: Vector3) -> void:
	var goo := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * goo_size
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/goo.gdshader")
	material.set_shader_parameter("seed", randf() * 20.0)
	plane.material = material
	goo.mesh = plane
	goo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	goo.position = to_local(spot) + Vector3(0.0, 0.016, 0.0)
	goo.rotation.y = randf() * TAU
	goo.scale = Vector3.ONE * 0.4
	add_child(goo)
	var tween := create_tween()
	tween.tween_property(goo, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(goo_hold_seconds)
	tween.tween_method(func(value: float): material.set_shader_parameter("fade", value), 1.0, 0.0, goo_fade_seconds)
	tween.tween_callback(goo.queue_free)


## Mesh bounds in the model root's own space (works before the model is in the tree).
static func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var transform := Transform3D()
		var walker: Node = mesh
		while walker != root and walker is Node3D:
			transform = (walker as Node3D).transform * transform
			walker = walker.get_parent()
		var local := transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
