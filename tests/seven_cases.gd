extends "res://tests/vertical_slice.gd"
## Current seven-case tutorial: real lighting, variable pages, ordinary rewards.
const COUNTS := [1, 2, 1, 2, 2, 2, 3]
const SOLUTIONS := [
	{"DeskLamp": [3.8, 0.1, 180]},
	{"DeskLamp": [3.8, 0.1, 180]},
	{"DeskLamp": [3.8, 0.1, 180], "Paperweight": [-1.2, 0.75, 0]},
	{"DeskLamp": [3.8, 0.1, 180], "Paperweight": [-0.6, 1.25, 0], "Paperweight2": [-0.6, -0.75, 0]},
	{"DeskLamp": [3.8, 0.1, 180], "Paperweight": [-0.6, 1.5, 0], "Paperweight2": [-0.6, 1.25, 0]},
	{"DeskLamp": [3.8, -1.0, 180], "Torch": [3.8, 1.05, 180], "Paperweight": [-0.6, 1.5, 0], "Paperweight2": [-0.9, 1.0, 0]},
	{"DeskLamp": [-0.91, -3.1, -90], "Torch": [3.8, -1.1, 180], "Torch2": [3.8, 1.3, 180], "Paperweight": [-0.9, 1.5, 0], "Paperweight2": [0.3, -0.75, 0], "Paperweight3": [-0.6, 1.25, 0]},
]
var recorded: Dictionary = {}

func move(name: String, pose: Array) -> void:
	var tool: Node3D = scene.get_node("Tools/" + name)
	tool.get_node("Draggable").move_to(Vector3(pose[0], 0, pose[1]), scene.get_node("InteractionManager").desk_bounds)
	tool.rotation.y = deg_to_rad(pose[2])
	tool.force_update_transform()

func screen_point(point: Vector3) -> Array:
	var position := camera.unproject_position(point)
	return [position.x, position.y]

func run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.size_2d_override = viewport.size
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	scene = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	camera = scene.get_node("Camera3D")
	await settle()
	var evaluator: LightEvaluator = scene.get_node("LightEvaluator")
	check(scene.campaign.size() == 7, "Seven cases must replace the former five-case campaign")
	check(is_equal_approx(scene.get_node("InkPreview").hidden_opacity, 0.88 * 0.9), "Hidden ink alpha is reduced by ten percent")
	check(scene.level.counts()["MURKY"] == 1, "The first tutorial begins with Halcyon needing illumination")
	key(KEY_L, true)
	key(KEY_L, false)
	await settle()
	check(scene.level.counts()["SPUN"] == 1, "The ceiling light illuminates the innocent photograph")
	key(KEY_L, true)
	key(KEY_L, false)
	await settle()
	# A poor first edition still allows progress, and has no original-photo choice.
	click(scene.story.publish_button)
	await settle(6)
	check(scene.result != null, "Publish must open the comic directly")
	check(not scene.result.next_button.disabled, "Imperfect editions never block progression")
	click(scene.result.back_button)
	await settle()
	for index in 7:
		check(scene.case_index == index, "Cases progress in the specified order")
		var level: LevelManager = scene.level
		check(level.panels.size() == COUNTS[index], "Each case must have its requested photo count")
		check(get_nodes_in_group("evidence_panels").size() == COUNTS[index], "Unused photo slots must not participate in the evaluator")
		var poi_count := 0
		for panel in level.panels:
			poi_count += panel.poi_nodes.size()
			check(panel.data.texture.get_size() == Vector2(768, 640), "Composed source photos retain readable dimensions")
		check(get_nodes_in_group("evidence_pois").size() == poi_count, "Loading cases must replace all POIs without stale clues")
		check(not level.data.final_case, "Case seven is not a moral-choice finale")
		check(level.data.comment_templates.twist.is_empty(), "Success must not add an explanation of the hidden narrative")
		for tool in scene.get_node("Tools").get_children():
			check(tool.visible == (String(tool.name) in level.data.available_tools), "Only taught tools may be available")
		composition_test()
		await screenshot("seven-%d-initial" % (index + 1))
		var input := {"tools": []}
		for name in SOLUTIONS[index]:
			var tool: Node3D = scene.get_node("Tools/" + name)
			input.tools.append({"name": name, "from": screen_point(tool.global_position + Vector3(0, 0.15, 0))})
			move(name, SOLUTIONS[index][name])
		await settle(5)
		evaluator.refresh()
		for entry in input.tools:
			var tool: Node3D = scene.get_node("Tools/" + entry.name)
			entry.to = screen_point(tool.global_position + Vector3(0, 0.15, 0))
			# Compute aim handle endpoints at the final location, before/after rotation.
			if tool.has_node("Rotatable") and not entry.name.begins_with("Paperweight"):
				var yaw := tool.rotation.y
				tool.rotation.y = deg_to_rad(float(level.data.tool_yaws.get(entry.name, 0)))
				tool.force_update_transform()
				entry.handle_from = screen_point(tool.global_position + tool.global_basis.x * 0.95)
				tool.rotation.y = yaw
				tool.force_update_transform()
				entry.handle_to = screen_point(tool.global_position + tool.global_basis.x * 0.95)
		for panel in level.panels:
			print("Case ", index + 1, " / ", panel.data.title, ": ", panel.state)
			for poi in panel.poi_nodes:
				print("  ",poi.data.description, " ", poi.data.current_light)
			check(panel.state == &"SPUN", "Every tutorial case must have an easy complete solution")
			for poi in panel.poi_nodes:
				check(poi.data.current_light >= 0.55 if poi.data.desired == 0 else poi.data.current_light < 0.3, "All positive subjects are lit and hidden clues are independently concealed")
		check(level.passed(), "A fully spun page is story ready")
		check(scene.story.goal.text.contains("GOOD WORK") and scene.story.goal.text.contains("STORY READY"), "Success stays positive through case seven")
		# The first omission uses a physical shadow, not a special-case POI rule.
		if index == 2:
			move("Paperweight", [-3.6,1.0,0])
			await settle()
			check(level.panels[0].state == &"DAMNING", "Removing the paperweight reveals the drowning woman")
			var weight: Node3D = scene.get_node("Tools/Paperweight")
			var from := camera.unproject_position(weight.global_position + Vector3(0,0.15,0))
			var to := Vector2(input.tools[1].to[0], input.tools[1].to[1])
			motion(from)
			button(from, MOUSE_BUTTON_LEFT, true)
			await settle()
			motion(to)
			await settle()
			button(to, MOUSE_BUTTON_LEFT, false)
			await settle()
			check(level.panels[0].state == &"SPUN", "After an actual drag stops, shadow readings must resample the settled physics pose without manual refresh")
		input.publish = [scene.story.publish_button.get_global_rect().get_center().x, scene.story.publish_button.get_global_rect().get_center().y]
		recorded["case%d" % index] = input
		await screenshot("seven-%d-solved" % (index + 1))
		click(scene.story.publish_button)
		await settle(7)
		check(scene.result != null and not scene.snapshot.has("ending"), "Every case publishes normally without an exposure ending")
		check(scene.result.reaction.score == 100 and scene.result.reaction.mood == "ADORING", "Every complete one/two/three-photo edition must receive the full positive reward")
		check(scene.result.reaction.verdict == "Excellent work.", "Editor treats every successful assignment as routine")
		check(scene.snapshot.panels.size() == COUNTS[index], "Print only active photos")
		check(scene.snapshot.hidden_opacity == scene.get_node("InkPreview").hidden_opacity, "Desk and comic use the same reduced ink opacity")
		if index == 6:
			check(scene.snapshot.subtitle == "OUR CITY'S GREATEST HERO!", "Case seven prints the cheerful title")
			for comment in scene.result.reaction.comments:
				check(not comment.text.contains("Who's") and not comment.text.contains("truth"), "A successful edition must not explain the discovery")
		var buttons := {}
		for action in ["back", "replay", "next"]:
			var center: Vector2 = scene.result.get(action + "_button").get_global_rect().get_center()
			buttons[action] = [center.x, center.y]
		recorded["result%d" % index] = buttons
		click(scene.result.back_button)
		await settle()
		check(level.counts()["SPUN"] == COUNTS[index], "Returning preserves the solved arrangement")
		click(scene.story.publish_button)
		await settle(7)
		click(scene.result.next_button)
		await settle(5)
	check(scene.case_index == 0, "After the seventh ordinary edition, the available tutorial sequence cycles normally")
	viewport.size = Vector2i(1920,1080)
	viewport.size_2d_override = viewport.size
	await settle()
	composition_test()
	var output := FileAccess.open("/tmp/shift-zero-seven-inputs.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(recorded))
	output.close()
	scene.queue_free()
	await settle()
	print("PASS: seven cases, variable photos, all solutions, paperweight shadow, rewards, frozen ink, ordinary publication and transitions.")
	quit(1 if failed else 0)
