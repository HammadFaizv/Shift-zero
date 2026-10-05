extends Node3D
@export var names := PackedStringArray(["James Jork", "Eric Spins", "Nora Quill", "Miles Margin", "Clara Press", "Victor Frame", "Ada Angle", "Oscar Ink", "Penny Proof", "Felix Fold", "Mabel Slate", "Theo Types", "Iris Page", "Arthur Lead", "Ruby Reed"])
@export var plate_size := Vector3(1.45, 0.12, 0.5)
var editor_name := ""
var label: Label3D

func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = plate_size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("bf9c54")
	material.metallic = 0.2
	material.roughness = 0.45
	mesh.material = material
	body.mesh = mesh
	add_child(body)
	label = Label3D.new()
	label.position.y = plate_size.y / 2 + 0.008
	label.rotation_degrees.x = -90
	label.font = NewsroomTheme.portable_font()
	label.pixel_size = 0.0025
	label.font_size = 48
	label.modulate = Color("17232b")
	label.outline_size = 0
	add_child(label)
	change_editor()

func change_editor() -> void:
	var candidates: Array[String] = []
	for candidate in names:
		if candidate != editor_name: candidates.append(candidate)
	if not candidates.is_empty(): editor_name = candidates.pick_random()
	label.text = editor_name + "\nNIGHT DESK EDITOR"
