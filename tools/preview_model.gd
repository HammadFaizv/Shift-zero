extends SceneTree
## godot --path . --script tools/preview_model.gd -- res://model.glb out.png
## Prints the model's bounds and renders it from the front-right-above at 640x480.
func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(640, 480)
	var model: Node3D = load(args[0]).instantiate()
	root.add_child(model)
	await process_frame
	var box := AABB()
	var first := true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	print("BOUNDS pos ", box.position, " size ", box.size, " centre ", box.get_center())
	var camera := Camera3D.new()
	root.add_child(camera)
	var centre := box.get_center()
	var span := box.size.length()
	camera.position = centre + Vector3(1, 0.8, 1.4).normalized() * span * 1.3
	camera.look_at(centre)
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-40, 30, 0)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("5a6a78")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.5
	root.add_child(env)
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(args[1])
	quit()
