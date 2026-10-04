extends SceneTree
## Desk snail: stays on the left, toggles with the bool, click fires the shot and leaves goo.
## godot --headless --path . --script tests/snail.gd
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func verify(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var desk: DeskSnail = scene.get_node("DeskSnail")
	await process_frame
	verify(desk._snail != null, "Snail spawns when snail_on_table is true")
	var camera := root.get_camera_3d()
	# Left side of the desk, clear of the case file (x >= -2.65), and it stays in its circle.
	for i in 600:
		await physics_frame
		var at: Vector3 = desk._snail.global_position
		verify(at.x < -3.4 and at.x > -6.0, "Snail stays on the left of the table (x=%.2f)" % at.x)
		verify(at.distance_to(desk._centre) <= desk._radius + 0.01, "Snail stays inside its roam circle")
	desk.snail_on_table = false
	await process_frame
	verify(desk._snail == null, "Turning the bool off removes the snail")
	desk.snail_on_table = true
	await process_frame
	verify(desk._snail != null, "Turning it on again brings one back")
	await physics_frame
	await physics_frame
	var spot := camera.unproject_position(desk._snail.global_position + Vector3(0, 0.3, 0))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = spot
	verify(desk._hits_snail(spot), "Ray picks the snail at its screen position")
	# Dispatch directly: headless runs have no window to deliver mouse events.
	desk._unhandled_input(press)
	await create_timer(0.15).timeout
	verify(desk._busy, "Clicking the snail starts the shot")
	await create_timer(1.6).timeout
	verify(desk._snail == null, "Snail is gone after the shot")
	var goo := 0
	for child in desk.get_children():
		if child is MeshInstance3D and child.mesh is PlaneMesh:
			goo += 1
	verify(goo == 1, "Goo is left behind")
	await create_timer(6.0).timeout
	verify(not desk._busy, "Sequence finishes")
	verify(desk.get_child_count() == 0, "Gun, flash and goo clean themselves up")
	print("Snail regression: ", failures, " failures")
	quit(1 if failures else 0)
