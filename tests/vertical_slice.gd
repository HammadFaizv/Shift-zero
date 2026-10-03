extends SceneTree
## Integration checks for the complete first-case slice. See docs/steps-6-10.md.

var viewport: SubViewport
var scene: Node3D
var camera: Camera3D
var failed: bool = false
var browser_inputs: Dictionary = {}


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
		quit(1)


func settle(frames: int = 3) -> void:
	for frame in frames:
		await physics_frame
	await process_frame


func button(at: Vector2, index: MouseButton, pressed: bool, double_click: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = index
	event.pressed = pressed
	event.double_click = double_click
	viewport.push_input(event, true)


func motion(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	viewport.push_input(event, true)


func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	viewport.push_input(event, true)


func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	button(point, MOUSE_BUTTON_LEFT, true)
	button(point, MOUSE_BUTTON_LEFT, false)


func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	check(image.get_size() == viewport.size, "Unexpected render dimensions")
	check(image.save_png("/tmp/shift-zero-slice-" + name + ".png") == OK, "Could not save preview")


func solve() -> void:
	var torch := scene.get_node("Tools/Torch")
	torch.get_node("Draggable").move_to(Vector3(-4.7, 0, 0.15), scene.get_node("InteractionManager").desk_bounds)
	torch.rotation.y = 0
	torch.force_update_transform()
	scene.get_node("Tools/Paperweight/Draggable").move_to(Vector3(1.18, 0, -1.245), scene.get_node("InteractionManager").desk_bounds)
	scene.get_node("Tools/Paperweight2/Draggable").move_to(Vector3(1.18, 0, 1.6675), scene.get_node("InteractionManager").desk_bounds)


func composition_test() -> void:
	var frame: Control = scene.get_node("Overlay/Frame")
	var story: Control = frame.get_node("StoryStatus")
	var strip_fraction := (frame.size.x - story.position.x) / frame.size.x
	check(strip_fraction >= 0.20 and strip_fraction <= 0.25, "Reserve 20–25% of desktop width for story/status")
	var page: MeshInstance3D = scene.get_node("DeskStage/CaseFilePage/Paper")
	var page_size: Vector3 = page.mesh.get_aabb().size
	for x in [-0.5, 0.5]:
		for z in [-0.5, 0.5]:
			var point := camera.unproject_position(page.to_global(Vector3(page_size.x * x, 0, page_size.z * z)))
			check(point.x > 0 and point.x < story.position.x, "Page must remain entirely beside the status UI")
			check(point.y > 90 and point.y < frame.size.y - 60, "Page must fit between the heading and control hints")
	for panel in scene.get_node("LevelManager").panels:
		var photo: MeshInstance3D = panel.get_node("Image")
		var photo_size: Vector2 = photo.mesh.size
		var top_left := camera.unproject_position(photo.to_global(Vector3(-photo_size.x / 2, 0, -photo_size.y / 2)))
		var top_right := camera.unproject_position(photo.to_global(Vector3(photo_size.x / 2, 0, -photo_size.y / 2)))
		var bottom_left := camera.unproject_position(photo.to_global(Vector3(-photo_size.x / 2, 0, photo_size.y / 2)))
		var bottom_right := camera.unproject_position(photo.to_global(Vector3(photo_size.x / 2, 0, photo_size.y / 2)))
		var width := top_left.distance_to(top_right)
		var height := top_left.distance_to(bottom_left)
		check(width > 160, "Photographs must stay large enough to read")
		check(is_equal_approx(width, bottom_left.distance_to(bottom_right)), "Camera must not taper photographs through perspective")
		check(height / width / (photo_size.y / photo_size.x) > 0.85, "Camera tilt must preserve readable photo proportions")


func rules_test() -> void:
	var panel := PanelData.new()
	var hero := POIData.new()
	var evidence := POIData.new()
	evidence.desired = POIData.Desired.HIDDEN
	panel.pois = [hero, evidence]
	hero.current_light = 0.55
	evidence.current_light = 0.299
	check(Interpretation.evaluate(panel, 0.30, 0.55) == &"SPUN", "Lit hero + hidden evidence must be SPUN")
	hero.current_light = 0.549
	check(Interpretation.evaluate(panel, 0.30, 0.55) == &"MURKY", "Unlit hero must be MURKY")
	evidence.current_light = 0.30
	panel.burned = true
	check(Interpretation.evaluate(panel, 0.30, 0.55) == &"DAMNING", "Exposed evidence takes priority over a burn mark")
	evidence.burned = true
	check(Interpretation.evaluate(panel, 0.30, 0.55) == &"TAMPERED", "Burning evidence must never count as SPUN")
	panel.rule_order = PackedInt32Array([1, 0, 2])
	evidence.burned = false
	check(Interpretation.evaluate(panel, 0.30, 0.55) == &"TAMPERED", "Rule order must be overridable per panel")


func run() -> void:
	rules_test()
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.size_2d_override = Vector2i(1280, 720)
	viewport.size_2d_override_stretch = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	scene = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(scene)
	camera = scene.get_node("Camera3D")
	await settle()
	var manager := scene.get_node("InteractionManager")
	var level: LevelManager = scene.get_node("LevelManager")
	var torch := scene.get_node("Tools/Torch")
	var weight := scene.get_node("Tools/Paperweight")
	var ceiling := scene.get_node("Tools/CeilingLight")
	var evaluator: LightEvaluator = scene.get_node("LightEvaluator")
	var ink := scene.get_node("InkPreview")
	var story := scene.get_node("Overlay/Frame/StoryStatus")
	var debug_panel := scene.get_node("Overlay/Frame/LightDebugPanel")
	composition_test()
	check(get_nodes_in_group("evidence_pois").size() == 8, "Each photo needs a hero and evidence POI")
	check(level.panels.size() == 4 and level.counts()["DAMNING"] == 4, "Ceiling-on case must expose all four crimes")
	for panel in level.panels:
		check(panel.data.texture.get_size() == Vector2(768, 640), "Keep final texture coordinates at 768x640")
		check(story.rows[panel.number - 1].caption.text == panel.caption(), "Live story captions must match data")
	check(not debug_panel.visible, "Debug readout should start hidden")
	var publish_point: Vector2 = story.publish_button.get_global_rect().get_center()
	browser_inputs["publish"] = [publish_point.x, publish_point.y]
	browser_inputs["tools"] = []
	for spec in [["Torch", Vector3(-4.7, 0, 0.15), 0.15], ["Paperweight", Vector3(1.18, 0, -1.245), 0.32], ["Paperweight2", Vector3(1.18, 0, 1.6675), 0.32]]:
		var tool: Node3D = scene.get_node("Tools/" + spec[0])
		var from := camera.unproject_position(tool.global_position + Vector3(0, spec[2], 0))
		var to := camera.unproject_position(spec[1] + Vector3(0, spec[2], 0))
		browser_inputs.tools.append({"name": spec[0], "from": [from.x, from.y], "to": [to.x, to.y]})
	key(KEY_F1, true)
	key(KEY_F1, false)
	check(debug_panel.visible and not story.visible, "F1 opens the debug readout")
	key(KEY_F1, true)
	key(KEY_F1, false)
	check(not debug_panel.visible and story.visible, "F1 returns to the story UI")
	click(story.rings)
	check(not scene.get_node("Overlay/Frame/TargetRings").enabled, "Evidence-target setting must toggle the rings")
	click(story.rings)
	await screenshot("desk-on")

	# Publishing remains available even for a completely damning edition.
	click(story.publish_button)
	await settle(6)
	check(scene.result != null, "Publish button must open the results scene")
	check(scene.result.reaction.score == 0 and scene.result.reaction.mood == "FURIOUS", "Ceiling-on edition must provoke outrage")
	check(scene.snapshot.subtitle == "...THE BANK BANDIT?!", "Damning subtitle must match the frozen states")
	check(not scene.result.next_button.disabled, "An imperfect published edition must still unlock the next implemented case")
	for action in ["back", "replay"]:
		var point: Vector2 = scene.result.get(action + "_button").get_global_rect().get_center()
		browser_inputs[action] = [point.x, point.y]
	for panel in level.panels:
		check(scene.result.reaction.verdict.contains(panel.data.title), "Editor must name every damning panel")
	var old_torch: Transform3D = torch.transform
	var old_ceiling: bool = ceiling.is_on
	key(KEY_L, true)
	key(KEY_L, false)
	key(KEY_Q, true)
	await settle(4)
	key(KEY_Q, false)
	check(ceiling.is_on == old_ceiling and torch.transform == old_torch, "Desk input must be frozen during results")
	await create_timer(3.9).timeout
	for view in scene.result.panel_views:
		check(is_equal_approx(view.material.get_shader_parameter("print_mix"), 1.0), "Every comic panel must finish its reveal")
	await screenshot("furious")
	click(scene.result.replay_button)
	check(is_zero_approx(scene.result.panel_views[0].material.get_shader_parameter("print_mix")), "Replay must reset the comic transition")
	click(scene.result.back_button)
	await settle()
	check(scene.result == null and torch.transform == old_torch and ceiling.is_on == old_ceiling, "Back must preserve the desk")
	check(story.visible, "Desk UI must return after publishing")

	key(KEY_L, true)
	key(KEY_L, false)
	await settle()
	key(KEY_L, true, true)
	check(not ceiling.is_on, "Key repeat must not toggle ceiling twice")
	# Pick and manipulate the GLB with real viewport input.
	var pick := camera.unproject_position(torch.global_position + Vector3(0, 0.15, 0))
	motion(pick)
	await settle()
	check(manager.hovered == torch.get_node("Draggable"), "Torch should be pickable")
	button(pick, MOUSE_BUTTON_LEFT, true)
	button(pick, MOUSE_BUTTON_LEFT, false)
	check(manager.selected == torch.get_node("Draggable"), "Torch selection")
	key(KEY_SPACE, true)
	key(KEY_SPACE, false)
	await settle()
	check(not torch.is_on, "Space toggles the selected torch")
	check(level.counts()["MURKY"] == 4, "All lights off must leave all heroes unreadable")
	button(pick, MOUSE_BUTTON_LEFT, true, true)
	button(pick, MOUSE_BUTTON_LEFT, false)
	check(torch.is_on, "Double-click restores the torch")
	var yaw: float = torch.rotation.y
	key(KEY_Q, true)
	await settle(5)
	key(KEY_Q, false)
	check(torch.rotation.y > yaw, "Q should rotate the torch")
	var changed_yaw: float = torch.rotation.y
	key(KEY_E, true)
	await settle(5)
	key(KEY_E, false)
	check(torch.rotation.y < changed_yaw, "E should rotate oppositely")
	yaw = torch.rotation.y
	button(pick, MOUSE_BUTTON_WHEEL_UP, true)
	check(torch.rotation.y > yaw, "Wheel should rotate the torch")
	button(pick, MOUSE_BUTTON_LEFT, true)
	motion(camera.unproject_position(torch.global_position + Vector3(0.4, 0, 0.2)))
	await settle()
	check(torch.transform != old_torch, "Drag should move the tool")
	motion(camera.unproject_position(Vector3(50, 0, 50)))
	await settle()
	check(torch.global_position.x <= manager.desk_bounds.end.x - torch.get_node("Draggable").footprint_radius + 0.001, "Tools must stay within desk bounds")
	button(pick, MOUSE_BUTTON_LEFT, false)
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	check(manager.selected == null, "Esc must clear selection")
	var beam: SpotLight3D = torch.get_node("Beam/VisualLight")
	check(is_equal_approx(evaluator.light_at(beam.global_position + beam.global_basis.z), evaluator.ambient), "No light behind the torch")
	check(is_equal_approx(evaluator.light_at(beam.global_position - beam.global_basis.z * beam.spot_range * 1.1), evaluator.ambient), "No light past the torch range")

	solve()
	await settle()
	for panel in level.panels:
		print(panel.data.title, ": ", panel.state, " / ", panel.data.pois[0].current_light, " / ", panel.data.pois[1].current_light)
	check(level.counts()["SPUN"] == 4, "The documented physical solution must reach 4/4 SPUN")
	check(level.passed(), "Three or more spun panels must pass the case")
	for panel in level.panels:
		for poi in panel.poi_nodes:
			var mean := 0.0
			for point in poi.sample_points():
				mean += evaluator.light_at(point) / poi.sample_points().size()
			check(is_equal_approx(mean, poi.data.current_light), "POI readings must use light_at()")
	# Moving each weight away must expose its evidence; restoring it hides it.
	for pair in [["Paperweight", 1], ["Paperweight2", 3]]:
		var tool := scene.get_node("Tools/" + pair[0])
		var position: Vector3 = tool.global_position
		tool.get_node("Draggable").move_to(Vector3(-3.5, 0, 3), manager.desk_bounds)
		await settle()
		check(level.panels[pair[1]].state == &"DAMNING", "Each weight must block real evidence rays")
		tool.get_node("Draggable").move_to(position, manager.desk_bounds)
		await settle()
		check(level.panels[pair[1]].state == &"SPUN", "Restored weight must restore its panel's spin")
	var idle_updates: int = ink.update_count
	await settle(8)
	check(ink.update_count == idle_updates, "Idle light map must not rebuild")
	var solved_pose: Transform3D = torch.transform
	var costs: Array[int] = []
	for step in 60:
		torch.get_node("Draggable").move_to(solved_pose.origin + Vector3(float(step) * 0.002, 0, 0), manager.desk_bounds)
		await settle(1)
		costs.append(ink.last_update_usec)
	costs.sort()
	print("Ink rebuild median/p95/max ms: ", costs[30] / 1000.0, " / ", costs[56] / 1000.0, " / ", costs[59] / 1000.0)
	if DisplayServer.get_name() != "headless":
		print("Native rendered FPS during movement: ", Engine.get_frames_per_second())
	torch.transform = solved_pose
	await settle()
	await screenshot("solution")
	var poses := {}
	for tool in scene.get_node("Tools").get_children():
		poses[tool.name] = tool.transform
	click(story.publish_button)
	await settle(6)
	print("Perfect publish counts: ", level.counts(), " / snapshot: ", scene.result.reaction.counts, " / score: ", scene.result.reaction.score)
	check(scene.result.reaction.score == 100 and scene.result.reaction.mood == "ADORING", "Perfect spin should receive ADORING")
	check(scene.snapshot.subtitle == "SAVES THE DAY!", "Perfect subtitle")
	var first: Dictionary = ReactionGenerator.generate(scene.snapshot, level.data.comment_templates, level.data.reaction_config)
	var second: Dictionary = ReactionGenerator.generate(scene.snapshot, level.data.comment_templates, level.data.reaction_config)
	check(first == second, "Identical results must produce identical reactions")
	var twist_found := false
	for comment in first.comments:
		if comment.text == level.data.comment_templates.twist:
			twist_found = not String(comment.reply).is_empty()
	check(twist_found, "Perfect edition must plant the lighting twist with a fan reply")
	var mixed: Dictionary = scene.snapshot.duplicate(true)
	mixed.panels[0].state = &"DAMNING"
	var mixed_reaction := ReactionGenerator.generate(mixed, level.data.comment_templates, level.data.reaction_config)
	check(mixed_reaction.score == 68 and mixed_reaction.passed, "Three spun panels must pass with configured weighted score")
	var reply_found := false
	for comment in mixed_reaction.comments:
		if comment.panel == 1 and not String(comment.reply).is_empty():
			reply_found = true
	check(reply_found, "A damning panel should receive a defensive fan reply when mood allows it")
	for i in 3:
		mixed.panels[i].state = &"MURKY"
	var murky_reaction := ReactionGenerator.generate(mixed, level.data.comment_templates, level.data.reaction_config)
	var murky_found := false
	for comment in murky_reaction.comments:
		murky_found = murky_found or comment.text == level.data.comment_templates.murky_group
	check(murky_found, "Three murky panels should trigger the darkness comment")
	mixed.panels[0].state = &"TAMPERED"
	var tampered_reaction := ReactionGenerator.generate(mixed, level.data.comment_templates, level.data.reaction_config)
	check(tampered_reaction.verdict.contains("Never touch the prints."), "Editor must scold tampering")
	# Verify every frozen print sample against the shared evaluator at that exact point.
	var frozen: Dictionary = scene.snapshot
	var page: MeshInstance3D = ink.page_mesh
	var size: Vector3 = page.mesh.get_aabb().size
	for y in range(0, frozen.resolution.y, 7):
		for x in range(0, frozen.resolution.x, 7):
			var point := page.to_global(Vector3(((float(x) + 0.5) / frozen.resolution.x - 0.5) * size.x, ink.sample_height, ((float(y) + 0.5) / frozen.resolution.y - 0.5) * size.z))
			check(is_equal_approx(frozen.light_values[y * frozen.resolution.x + x], evaluator.light_at(point)), "Printed ink must match the frozen light_at() samples")
	print("Print capture ms: ", scene.get_node("ComicRenderer").last_capture_usec / 1000.0)
	await create_timer(3.9).timeout
	await screenshot("adoring")
	click(scene.result.back_button)
	await settle()
	for tool in scene.get_node("Tools").get_children():
		check(tool.transform == poses[tool.name], "Publishing must preserve each tool pose")
	check(level.counts()["SPUN"] == 4, "Returning should preserve solved lighting")

	# Native render framing and clickable controls at both supported sizes.
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		viewport.size = resolution
		await settle()
		composition_test()
		var cord := camera.unproject_position(ceiling.get_node("PullCord/Handle").global_position)
		button(cord, MOUSE_BUTTON_LEFT, true)
		button(cord, MOUSE_BUTTON_LEFT, false)
		await settle()
		check(ceiling.is_on, "Cord should work at both resolutions")
		await screenshot("desk-%d" % resolution.x)
		click(story.publish_button)
		await settle(6)
		check(scene.result != null, "Publishing should work at both resolutions")
		await screenshot("results-%d" % resolution.x)
		click(scene.result.back_button)
		await settle()
		ceiling.toggle()
		await settle()
	if not failed:
		var file := FileAccess.open("/tmp/shift-zero-browser-inputs.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(browser_inputs))
		print("PASS: panel rules, actual 4/4 solution, live story/targets, tool controls, publishing/replay, deterministic reactions, frozen ink, return, and both viewport sizes.")
	quit(1 if failed else 0)
