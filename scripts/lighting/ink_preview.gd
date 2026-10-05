extends Node
## A float light map shared by all photo overlay materials.

@export var page_mesh: MeshInstance3D
@export var photos: Array[MeshInstance3D]
@export var grid_resolution: Vector2i = Vector2i(80, 100)
@export var sample_height: float = 0.032
@export var hidden_color: Color = Color("2a1f5c")
@export_range(0.0, 1.0) var hidden_opacity: float = 0.792
@export_range(0.0, 1.0) var murky_opacity: float = 0.36
@export var burn_edge_width: float = 0.025

var update_count: int = 0
var last_update_usec: int = 0
var light_values: PackedFloat32Array
var light_image: Image
var _points: PackedVector3Array
var _texture: ImageTexture
var burn_texture: ImageTexture
var burn_values: PackedFloat32Array
var _burn_image: Image
var _material: ShaderMaterial
var _evaluator: LightEvaluator
var _panels: Array[EvidencePanel] = []


func _ready() -> void:
	_evaluator = get_tree().get_first_node_in_group("light_evaluator") as LightEvaluator
	for panel in get_tree().get_nodes_in_group("evidence_panels"):
		_panels.append(panel)
	grid_resolution.x = maxi(grid_resolution.x, 2)
	grid_resolution.y = maxi(grid_resolution.y, 2)
	var size: Vector3 = page_mesh.mesh.get_aabb().size
	light_values.resize(grid_resolution.x * grid_resolution.y)
	for y in grid_resolution.y:
		for x in grid_resolution.x:
			var uv := Vector2((float(x) + 0.5) / grid_resolution.x, (float(y) + 0.5) / grid_resolution.y)
			_points.append(page_mesh.to_global(Vector3((uv.x - 0.5) * size.x, sample_height, (uv.y - 0.5) * size.z)))
	light_image = Image.create_from_data(grid_resolution.x, grid_resolution.y, false, Image.FORMAT_RF, light_values.to_byte_array())
	_texture = ImageTexture.create_from_image(light_image)
	burn_values.resize(light_values.size())
	_burn_image = Image.create_from_data(grid_resolution.x, grid_resolution.y, false, Image.FORMAT_RF, burn_values.to_byte_array())
	burn_texture = ImageTexture.create_from_image(_burn_image)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/ink_preview.gdshader")
	_material.set_shader_parameter("light_map", _texture)
	_material.set_shader_parameter("burn_map", burn_texture)
	_material.set_shader_parameter("world_to_page", page_mesh.global_transform.affine_inverse())
	_material.set_shader_parameter("page_size", Vector2(size.x, size.z))
	_material.set_shader_parameter("hidden_color", hidden_color)
	_material.set_shader_parameter("hidden_opacity", hidden_opacity)
	_material.set_shader_parameter("murky_opacity", murky_opacity)
	for photo in photos:
		photo.material_overlay = _material
	_evaluator.lighting_changed.connect(refresh)


func refresh() -> void:
	var start := Time.get_ticks_usec()
	_panels.clear()
	for panel in get_tree().get_nodes_in_group("evidence_panels"):
		_panels.append(panel)
	var has_burns := false
	for panel in _panels:
		has_burns = has_burns or not panel.data.burn_marks.is_empty()
	for i in _points.size():
		light_values[i] = _evaluator.light_at(_points[i])
		burn_values[i] = burn_at(_points[i]) if has_burns else 0.0
	light_image.set_data(grid_resolution.x, grid_resolution.y, false, Image.FORMAT_RF, light_values.to_byte_array())
	_texture.update(light_image)
	_burn_image.set_data(grid_resolution.x, grid_resolution.y, false, Image.FORMAT_RF, burn_values.to_byte_array())
	burn_texture.update(_burn_image)
	_material.set_shader_parameter("hidden_threshold", _evaluator.hidden_threshold)
	_material.set_shader_parameter("visible_threshold", _evaluator.visible_threshold)
	update_count += 1
	last_update_usec = Time.get_ticks_usec() - start


func burn_at(point: Vector3) -> float:
	var value := 0.0
	for panel in _panels:
		if panel.data.burn_marks.is_empty():
			continue
		var local: Vector3 = panel.photo.to_local(point)
		var size: Vector2 = panel.photo.mesh.size
		for mark in panel.data.burn_marks:
			var centre := Vector2((mark.x - 0.5) * size.x, (mark.y - 0.5) * size.y)
			var distance := centre.distance_to(Vector2(local.x, local.z))
			value = maxf(value, clampf((mark.z - distance) / burn_edge_width, 0.0, 1.0))
	return value
