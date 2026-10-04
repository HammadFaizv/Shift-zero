extends SceneTree
## Screenshot helper (needs a display):
##   godot --path . --script tools/shot.gd -- <case 0-6> <out_prefix> [mode]
## mode: "real" publishes the live lighting (default); "perfect" forces every hitbox to its
## desired state; "exposed" forces every hitbox to full light; "dark" to none.
## Saves <prefix>_desk.png and <prefix>_comic.png from the real main scene.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var index := int(args[0]) if args.size() > 0 else 0
	var prefix := String(args[1]) if args.size() > 1 else "shot"
	var mode := String(args[2]) if args.size() > 2 else "real"
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	for i in 6:
		await process_frame
	scene.load_case(index)
	for i in 8:
		await process_frame
	if args.size() > 3:
		var e := InputEventMouseMotion.new()
		e.position = Vector2(float(args[3]), float(args[4]))
		Input.parse_input_event(e)
		for i in 60:
			await process_frame
	if mode != "real":
		for panel in scene.level.panels:
			for poi in panel.data.pois:
				match mode:
					"perfect": poi.current_light = 1.0 if poi.desired == POIData.Desired.VISIBLE else 0.0
					"exposed": poi.current_light = 1.0
					"dark": poi.current_light = 0.0
			panel.state = Interpretation.evaluate(panel.data, 0.3, 0.55)
		scene.story.refresh()
		await process_frame
		await process_frame
	root.get_texture().get_image().save_png(prefix + "_desk.png")
	if mode == "real":
		await scene.publish()
	else:
		var snapshot: Dictionary = scene.get_node("ComicRenderer").capture(scene.level, scene.get_node("InkPreview"), scene.get_node("LightEvaluator"))
		snapshot["next_available"] = true
		snapshot["campaign_complete"] = false
		var reaction := ReactionGenerator.generate(snapshot, scene.level.data.comment_templates, scene.level.data.reaction_config)
		scene.get_node("Overlay/Frame").hide()
		var result = scene.results_scene.instantiate()
		scene.get_node("ResultsLayer").add_child(result)
		result.configure(snapshot, reaction)
	await create_timer(5.5).timeout
	root.get_texture().get_image().save_png(prefix + "_comic.png")
	quit()
