class_name EvidencePanel
extends Node3D

signal state_changed

@export var data: PanelData
@export var number: int = 1
@export var border_padding: Vector2 = Vector2(0.06, 0.08)
## Photos sit on visual layer 2 only, so the desk fill light (layer 1) never changes how they read.
@export_flags_3d_render var photo_layers: int = 2
@export var poi_scene: PackedScene = preload("res://scenes/desk/evidence_poi.tscn")

var state: StringName = &"MURKY"
var poi_nodes: Array[EvidencePOI] = []
var evaluator: LightEvaluator
@onready var photo: MeshInstance3D = $Image


func _ready() -> void:
	var material := photo.get_active_material(0).duplicate() as StandardMaterial3D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	photo.layers = photo_layers
	photo.material_override = material
	evaluator = get_tree().get_first_node_in_group("light_evaluator") as LightEvaluator
	set_content(data, number)


func configure_layout(layout: Rect2) -> void:
	position = Vector3(layout.position.x, 0.02, layout.position.y)
	var image := get_node("Image") as MeshInstance3D
	image.mesh = image.mesh.duplicate()
	image.mesh.size = layout.size
	image.position = Vector3(0, 0.009, 0)
	$Border.mesh = $Border.mesh.duplicate()
	$Border.mesh.size = Vector3(layout.size.x + border_padding.x, 0.012, layout.size.y + border_padding.y)
	$Border.position.z = 0.0
	$Tape.position.z = -layout.size.y * 0.5 - 0.04


func refresh() -> void:
	var next := Interpretation.evaluate(data, evaluator.hidden_threshold, evaluator.visible_threshold)
	if next != state:
		state = next
		state_changed.emit()


func caption() -> String:
	return String(data.captions.get(String(state), ""))


func set_content(content: PanelData, index: int) -> void:
	for poi in poi_nodes:
		remove_child(poi)
		poi.queue_free()
	poi_nodes.clear()
	visible = content != null
	if content == null:
		data = null
		remove_from_group("evidence_panels")
		return
	add_to_group("evidence_panels")
	data = content.duplicate(true) as PanelData
	data.burned = false
	data.burn_marks.clear()
	number = index
	photo.material_override.albedo_texture = data.texture
	for source in data.pois:
		source.burned = false
		var poi := poi_scene.instantiate() as EvidencePOI
		poi.data = source
		poi.photo = photo
		add_child(poi)
		poi_nodes.append(poi)


func add_burn(uv: Vector2, radius: float) -> void:
	data.burned = true
	data.burn_marks.append(Vector3(uv.x, uv.y, radius))
	var photo_size: Vector2 = photo.mesh.size
	for poi in poi_nodes:
		var distance := ((poi.data.position_uv - uv) * photo_size).length()
		if distance <= radius + poi.data.radius_uv * photo_size.x:
			poi.data.burned = true
