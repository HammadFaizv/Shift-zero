extends SceneTree
## godot --path . --script tools/shot_snail.gd -- <out_prefix>
## Screenshots the snail, then clicks it and captures the gun, the flash and the fading goo.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var prefix := String(OS.get_cmdline_user_args()[0])
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(1.0).timeout
	var snail: DeskSnail = scene.get_node("DeskSnail")
	root.get_texture().get_image().save_png(prefix + "_0idle.png")
	var camera := root.get_camera_3d()
	var spot := camera.unproject_position(snail._snail.global_position + Vector3(0, 0.3, 0))
	print("SNAIL at ", snail._snail.global_position, " screen ", spot)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = spot
	Input.parse_input_event(press)
	var release := press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	var marks := [0.25, 0.55, 0.92, 1.0, 1.15, 1.9, 4.5]
	var elapsed := 0.0
	for i in marks.size():
		await create_timer(marks[i] - elapsed).timeout
		elapsed = marks[i]
		root.get_texture().get_image().save_png("%s_%d.png" % [prefix, i + 1])
	print("SNAIL after: ", snail._snail, " busy ", snail._busy)
	quit()
