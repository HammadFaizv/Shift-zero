class_name EvidencePOI
extends Node3D

@export var data: POIData
@export var photo: MeshInstance3D
@export var sample_height: float = 0.003
@export var perimeter_samples: int = 8

var light_state: String = "HIDDEN"
var _evaluator: LightEvaluator
var _samples: PackedVector3Array


func _ready() -> void:
	_evaluator = get_tree().get_first_node_in_group("light_evaluator") as LightEvaluator
	var size: Vector2 = (photo.mesh as PlaneMesh).size
	var centre := Vector3((data.position_uv.x - 0.5) * size.x, sample_height, (data.position_uv.y - 0.5) * size.y)
	global_position = photo.to_global(centre)
	_samples.append(global_position)
	for i in perimeter_samples:
		var angle := TAU * float(i) / float(perimeter_samples)
		var offset := Vector3(cos(angle) * data.radius_uv * size.x, 0, sin(angle) * data.radius_uv * size.y)
		_samples.append(photo.to_global(centre + offset))
	var marker := get_node_or_null("Marker") as Label3D
	if marker != null:
		marker.text = String(data.id)


func refresh() -> void:
	var value := 0.0
	var count := 0
	for point in _samples:
		count += 1
		# An incremental mean preserves uniform readings at exact thresholds.
		value += (_evaluator.light_at(point) - value) / float(count)
	data.current_light = value
	light_state = _evaluator.classify(data.current_light)


func sample_points() -> PackedVector3Array:
	return _samples
