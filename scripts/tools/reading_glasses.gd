extends Node3D

@export var beam_color: Color = Color(0.35, 0.9, 0.8, 0.14)
@export var guide_height: float = 0.096
@export var guide_segments: int = 18

@onready var optic: Redirector = $Redirector
@onready var guide: MeshInstance3D = $BeamGuide


func _ready() -> void:
	get_tree().get_first_node_in_group("light_evaluator").lighting_changed.connect(refresh_guide)


func refresh_guide() -> void:
	guide.visible = optic.output > 0.0 and is_visible_in_tree()
	if not guide.visible:
		return
	var evaluator: LightEvaluator = get_tree().get_first_node_in_group("light_evaluator")
	var drawing := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = beam_color
	drawing.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var forward := global_basis.x.normalized()
	var side := global_basis.z.normalized()
	var source := optic.origin
	var spread := tan(deg_to_rad(optic.visual_light.spot_angle))
	var previous: Array[Vector3] = []
	for i in guide_segments + 1:
		var distance: float = optic.visual_light.spot_range * float(i) / guide_segments
		var centre: Vector3 = source + forward * distance
		var current: Array[Vector3] = []
		for sign_value in [-1.0, 1.0]:
			var point: Vector3 = centre + side * distance * spread * sign_value
			point.y = guide_height
			if evaluator.ray_blocked(source, point):
				point = centre
				point.y = guide_height
			current.append(point)
		if not previous.is_empty():
			for vertex in [previous[0], current[0], previous[1], previous[1], current[0], current[1]]:
				drawing.surface_add_vertex(guide.to_local(vertex))
		previous = current
	drawing.surface_end()
	guide.mesh = drawing
