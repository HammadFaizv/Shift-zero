extends Node3D

@export var warm_color: Color = Color(1, 0.66, 0.13, 0.45)
@export var warning_color: Color = Color(1, 0.16, 0.03, 0.75)
@export var smoke_start: float = 0.55
@export var smoke_rise: float = 0.6
@export var smoke_radius: float = 0.065
@export var smoke_color: Color = Color(0.65, 0.62, 0.57, 0.35)

@onready var focus: Focuser = $Focuser
@onready var warning: Label3D = $Warning
@onready var spot: MeshInstance3D = $FocusSpot
var smoke: Array[MeshInstance3D] = []


func _ready() -> void:
	# Source lens is opaque in some imported materials; make it transparent so
	# it does not hide the evidence underneath the supplied magnifier model.
	for mesh in $Model.find_children("*", "MeshInstance3D", true, false):
		if "kaca" in String(mesh.name):
			# The supplied GLB has an offset authoring origin. Centre the actual
			# lens on the receiver without altering the original asset.
			var centre := to_local(mesh.to_global(mesh.get_aabb().get_center()))
			$Model.position += Vector3(-centre.x, $Receiver.position.y - centre.y, -centre.z)
			var lens := StandardMaterial3D.new()
			lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			lens.albedo_color = Color(0.6, 0.86, 0.9, 0.12)
			lens.roughness = 0.1
			mesh.material_override = lens
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		var puff := MeshInstance3D.new()
		puff.add_to_group("light_guides")
		var sphere := SphereMesh.new()
		sphere.radius = smoke_radius
		sphere.height = smoke_radius * 2.0
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = smoke_color
		sphere.material = material
		puff.mesh = sphere
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		smoke.append(puff)
	focus.heat_changed.connect(show_heat)


func show_heat(progress: float, hot: bool) -> void:
	spot.visible = focus.output > 0.0
	spot.global_position = focus.target
	spot.material_override.albedo_color = warm_color.lerp(warning_color, progress)
	warning.visible = hot
	warning.text = "TOO HOT — MOVE IT! %d%%" % roundi(progress * 100) if progress < 1.0 else "SCORCHED — RESTART CASE TO RESET"
	for i in smoke.size():
		var phase := fmod(Time.get_ticks_msec() / 1000.0 + float(i) / smoke.size(), 1.0)
		smoke[i].visible = progress >= smoke_start
		smoke[i].position = Vector3(sin(phase * TAU) * smoke_radius, 0.24 + phase * smoke_rise, 0)
		smoke[i].scale = Vector3.ONE * (1.0 + phase)
