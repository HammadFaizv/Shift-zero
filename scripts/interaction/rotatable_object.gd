class_name RotatableObject
extends Node

signal rotated

@export var degrees_per_second: float = 90.0
@export var wheel_step_degrees: float = 12.0


func rotate_continuously(direction: float, delta: float) -> void:
	_rotate(direction * degrees_per_second * delta)


func rotate_step(direction: float) -> void:
	_rotate(direction * wheel_step_degrees)


func _rotate(degrees: float) -> void:
	if is_zero_approx(degrees):
		return
	var tool := get_parent() as Node3D
	tool.rotate_y(deg_to_rad(degrees))
	tool.force_update_transform()
	rotated.emit()
