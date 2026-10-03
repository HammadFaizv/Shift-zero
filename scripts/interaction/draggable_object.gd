class_name DraggableObject
extends Node
## Plane-based movement and tool feedback; no rigid-body simulation.

signal moved

@export var display_name: String = "Tool"
@export var usage_hint: String = ""
@export var footprint_radius: float = 0.3
@export var support_radius: float = 0.3
@export var desk_height: float = 0.0
@export var page_height: float = 0.086
@export var page_bounds: Rect2 = Rect2(-2.65, -2.925, 4.7, 5.85)
@export var hover_color: Color = Color(1.0, 0.82, 0.45, 0.12)
@export var outline_color: Color = Color(1.0, 0.73, 0.26)
@export var outline_width: float = 0.018

var tool: Node3D
var _meshes: Array[MeshInstance3D] = []
var _outlines: Array[MeshInstance3D] = []
var _hover_material: StandardMaterial3D
var _selected: bool = false


func _ready() -> void:
	tool = get_parent() as Node3D
	_hover_material = StandardMaterial3D.new()
	_hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hover_material.albedo_color = hover_color
	var outline_material := ShaderMaterial.new()
	outline_material.shader = preload("res://shaders/tool_outline.gdshader")
	outline_material.set_shader_parameter("outline_color", outline_color)
	outline_material.set_shader_parameter("outline_width", outline_width)
	for node in tool.find_children("*", "MeshInstance3D", true, false):
		var source := node as MeshInstance3D
		if source.is_in_group("light_guides"):
			continue
		_meshes.append(source)
		var outline := MeshInstance3D.new()
		outline.name = "SelectionOutline"
		outline.mesh = source.mesh
		# Imported models can have very different mesh units. Keep the outline
		# at the exported world-space width instead of scaling it with the GLB.
		var world_scale := source.global_basis.get_scale().abs()
		var mesh_scale := maxf(world_scale.x, maxf(world_scale.y, world_scale.z))
		var mesh_outline := outline_material.duplicate() as ShaderMaterial
		if not is_zero_approx(mesh_scale):
			mesh_outline.set_shader_parameter("outline_width", outline_width / mesh_scale)
		outline.material_override = mesh_outline
		outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		outline.visible = false
		source.add_child(outline)
		_outlines.append(outline)


func move_to(point: Vector3, desk_bounds: Rect2) -> void:
	var next := tool.global_position
	next.x = clampf(point.x, desk_bounds.position.x + footprint_radius, desk_bounds.end.x - footprint_radius)
	next.z = clampf(point.z, desk_bounds.position.y + footprint_radius, desk_bounds.end.y - footprint_radius)
	# Raise a tool when any part of its support footprint overlaps the page.
	next.y = page_height if page_bounds.grow(support_radius).has_point(Vector2(next.x, next.z)) else desk_height
	if not next.is_equal_approx(tool.global_position):
		tool.global_position = next
		tool.force_update_transform()
		moved.emit()


func set_hovered(hovered: bool) -> void:
	for mesh in _meshes:
		mesh.material_overlay = _hover_material if hovered and not _selected else null


func set_selected(selected: bool) -> void:
	_selected = selected
	set_hovered(false)
	for outline in _outlines:
		outline.visible = selected


func rotatable() -> RotatableObject:
	return tool.get_node_or_null("Rotatable") as RotatableObject
