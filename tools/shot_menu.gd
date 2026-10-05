extends SceneTree
## godot --path . --script tools/shot_menu.gd -- <out_prefix>   (needs a display)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var prefix := String(OS.get_cmdline_user_args()[0])
	root.size = Vector2i(1280, 720)
	var screen = load("res://scenes/ui/start_screen.tscn").instantiate()
	root.add_child(screen)
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png(prefix + "_menu.png")
	screen.show_tutorial(3)
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png(prefix + "_tutorial4.png")
	quit()
