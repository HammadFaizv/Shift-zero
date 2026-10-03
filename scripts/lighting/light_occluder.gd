class_name LightOccluder
extends StaticBody3D
## A conservative sphere skips raycasts that cannot hit these collision shapes.

@export var bounds_center: Vector3 = Vector3(0.0, 0.25, 0.0)
@export var bounds_radius: float = 0.45


func state() -> Array:
	return [global_transform, collision_layer, bounds_center, bounds_radius]
