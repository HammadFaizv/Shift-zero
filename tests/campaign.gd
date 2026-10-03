extends "res://tests/vertical_slice.gd"
## Real optics, level transitions, delayed/persistent burning and both endings.

var published_inputs: Dictionary = {}


func move_tool(name: String, position: Vector3, yaw_degrees: float = 0.0) -> void:
	var tool: Node3D = scene.get_node("Tools/" + name)
	tool.get_node("Draggable").move_to(position, scene.get_node("InteractionManager").desk_bounds)
	tool.rotation.y = deg_to_rad(yaw_degrees)
	tool.force_update_transform()


func solve_case(index: int) -> void:
	if scene.get_node("Tools/CeilingLight").is_on:
		scene.get_node("Tools/CeilingLight").toggle()
	if index == 0:
		solve()
	elif index == 1:
		move_tool("Torch", Vector3(-4.7, 0, -0.5625))
		move_tool("Torch2", Vector3(-4.7, 0, 0.855))
		move_tool("Paperweight", Vector3(1.18, 0, -1.245))
		move_tool("Paperweight2", Vector3(1.18, 0, 1.6675))
	else:
		move_tool("Torch", Vector3(-0.3, 0, -3.7), -90.0)
		move_tool("ReadingGlasses", Vector3(-0.15, 0, 1.7))
		if index >= 3:
			move_tool("MagnifyingGlass", Vector3(1.4825, 0, 1.71625))


func record_clicks(key_name: String, result: Control) -> void:
	var data := {}
	for action in ["back", "replay", "next"]:
		var point: Vector2 = result.get(action + "_button").get_global_rect().get_center()
		data[action] = [point.x, point.y]
	published_inputs[key_name] = data


func run() -> void:
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
	var level: LevelManager = scene.get_node("LevelManager")
	var evaluator: LightEvaluator = scene.get_node("LightEvaluator")
	var glasses: Node3D = scene.get_node("Tools/ReadingGlasses")
	var magnifier: Node3D = scene.get_node("Tools/MagnifyingGlass")
	var ceiling: Node3D = scene.get_node("Tools/CeilingLight")
	var focus: Focuser = magnifier.get_node("Focuser")
	var redirector: Redirector = glasses.get_node("Redirector")
	check(scene.campaign.size() == 5, "Campaign must contain all five cases")
	click(scene.story.publish_button)
	await settle(6)
	check(scene.result.reaction.score == 0 and not scene.result.next_button.disabled, "Publishing a bad page must not block campaign progress")
	click(scene.result.back_button)
	await settle()
	for index in 5:
		check(scene.case_index == index, "Next-case button must load campaign data in order")
		check(get_nodes_in_group("evidence_pois").size() == 8, "Changing cases must replace POIs instead of accumulating them")
		for panel in level.panels:
			check(panel.data.texture.get_size() == Vector2(768, 640), "New source photographs retain swap-compatible dimensions")
		check(level.counts()["DAMNING"] == 4, "Ceiling-on case must expose every photograph's evidence")
		composition_test()
		await screenshot("case-%d-initial" % (index + 1))
		var input := {"tools": []}
		for tool in scene.get_node("Tools").get_children():
			if tool.visible and tool.has_node("Draggable"):
				var point := camera.unproject_position(tool.global_position + Vector3(0, 0.2, 0))
				input.tools.append({"name": String(tool.name), "from": [point.x, point.y], "initial_yaw": tool.rotation.y})
		solve_case(index)
		await settle(5)
		for tool_input in input.tools:
			var point := camera.unproject_position(scene.get_node("Tools/" + tool_input.name).global_position + Vector3(0, 0.2, 0))
			tool_input["to"] = [point.x, point.y]
			tool_input["yaw"] = -90.0 if index >= 2 and tool_input.name == "Torch" else 0.0
			if index >= 2 and tool_input.name == "Torch":
				var tool: Node3D = scene.get_node("Tools/Torch")
				var direction := Vector3(cos(tool_input.initial_yaw), 0, -sin(tool_input.initial_yaw))
				var from := camera.unproject_position(tool.global_position + direction * 0.95)
				var to := camera.unproject_position(tool.global_position + tool.global_basis.x * 0.95)
				tool_input["handle_from"] = [from.x, from.y]
				tool_input["handle_to"] = [to.x, to.y]
		input["publish"] = [scene.story.publish_button.get_global_rect().get_center().x, scene.story.publish_button.get_global_rect().get_center().y]
		published_inputs["case%d" % index] = input
		for panel in level.panels:
			print("Case ", index + 1, " / ", panel.data.title, ": ", panel.state, " ", panel.data.pois[0].current_light, " / ", panel.data.pois[1].current_light)
		print("Optics: input/output ", redirector.incoming, " / ", redirector.output, " focus ", focus.incoming, " / ", focus.output)
		check(level.counts()["SPUN"] == 4, "Every documented case solution must reach 4/4 SPUN")
		if index == 1:
			var torch: Node3D = scene.get_node("Tools/Torch")
			torch.toggle()
			await settle()
			check(level.counts()["SPUN"] < 4, "The factory's second row needs its narrow torch")
			torch.toggle()
			scene.get_node("Tools/Torch2").toggle()
			move_tool("Torch", Vector3(-3.5, 0, 0.5), 27.0)
			await settle()
			check(level.panels[0].data.pois[0].current_light >= evaluator.visible_threshold and level.panels[1].data.pois[0].current_light < evaluator.hidden_threshold, "A narrow torch must isolate one hero from its neighbour")
			scene.get_node("Tools/Torch2").toggle()
			solve_case(index)
		elif index == 2:
			glasses.hide()
			await settle()
			check(level.panels[3].state != &"SPUN", "The protest solution needs its redirected beam")
			glasses.show()
			glasses.rotation.y = PI / 2
			await settle()
			check(level.panels[3].state != &"SPUN", "Turning glasses must turn their outgoing beam")
			glasses.rotation.y = 0
			await settle()
			move_tool("Paperweight", Vector3(0.85, 0, 1.71))
			await settle()
			check(level.panels[3].state != &"SPUN", "Paperweights must block redirected rays too")
			move_tool("Paperweight", Vector3(-4.55, 0, 0.9))
		elif index >= 3:
			magnifier.hide()
			await settle()
			check(level.panels[3].state != &"SPUN", "The weak reflected beam must need the magnifier")
			magnifier.show()
		await settle()
		check(level.counts()["SPUN"] == 4, "Restore optics to restore the solution")
		await screenshot("case-%d-solved" % (index + 1))
		if index == 4:
			break
		click(scene.story.publish_button)
		await settle(6)
		check(scene.result != null and scene.result.reaction.score == 100, "Each solved case must publish ADORING")
		check(not scene.result.next_button.disabled, "Publishing unlocks the next case")
		record_clicks("result%d" % index, scene.result)
		click(scene.result.back_button)
		await settle()
		check(level.counts()["SPUN"] == 4, "Back keeps optics and tool poses")
		click(scene.story.publish_button)
		await settle(6)
		click(scene.result.next_button)
		await settle(5)

	# Final choice is modal and cancels without losing the current desk.
	click(scene.story.publish_button)
	await settle()
	check(scene.choice_ui != null and scene.result == null, "Final publishing must present both choices first")
	var choices := {}
	for name in ["edited", "original", "cancel"]:
		var point: Vector2 = scene.choice_ui.get(name + "_button").get_global_rect().get_center()
		choices[name] = [point.x, point.y]
	published_inputs["choices"] = choices
	key(KEY_L, true)
	key(KEY_L, false)
	check(not ceiling.is_on, "Choice dialog freezes desk input")
	click(scene.choice_ui.cancel_button)
	await settle()
	check(scene.choice_ui == null and level.counts()["SPUN"] == 4, "Cancel keeps the solved desk")
	click(scene.story.publish_button)
	await settle()
	click(scene.choice_ui.edited_button)
	await settle(6)
	check(scene.result.reaction.score == 100 and scene.snapshot.ending.choice == &"edited", "Edited choice creates the heroic ending")
	check(scene.snapshot.ending.headline.contains("FAITH"), "Edited ending needs its own headline")
	check(scene.result.reaction.comments[0].text == level.data.endings.edited.comments[0], "Edited ending needs its own public comments")
	record_clicks("ending", scene.result)
	await create_timer(3.9).timeout
	await screenshot("ending-edited")
	click(scene.result.back_button)
	await settle()

	# Burning requires sustained strong input, warns first and survives Back.
	ceiling.toggle()
	await settle()
	check(focus.incoming >= focus.burn_input_threshold, "Ceiling plus reflected light must provide strong input")
	focus.reset_heat()
	await create_timer(0.4).timeout
	check(magnifier.get_node("Warning").visible and not level.panels[3].data.burned, "Warn before any permanent burn")
	move_tool("MagnifyingGlass", Vector3(1.50, 0, 1.71625))
	await settle()
	check(focus.heat_seconds < 0.1, "Moving the lens resets the stillness timer")
	await create_timer(1.9).timeout
	check(not level.panels[3].data.burned, "Burning must not happen before about 2.5 seconds")
	await screenshot("heat-warning")
	await create_timer(0.8).timeout
	await settle()
	check(level.panels[3].data.burned and level.panels[3].state == &"TAMPERED", "Sustained heat must permanently tamper with the panel")
	check(level.panels[3].data.pois[0].burned, "Burning a hero must prevent a SPUN result")
	var centre: Vector3 = level.panels[3].poi_nodes[0].global_position
	check(scene.get_node("InkPreview").burn_at(centre) > 0.9, "Scorch must appear on the desk mask")
	await screenshot("burned")
	click(scene.story.publish_button)
	await settle()
	click(scene.choice_ui.edited_button)
	await settle(6)
	check(scene.snapshot.panels[3].burned, "Edited comic retains permanent burns")
	check(scene.snapshot.burn_values.count(1.0) > 0, "Burn marks must appear in the frozen comic")
	var burn_comment := false
	for comment in scene.result.reaction.comments:
		burn_comment = burn_comment or comment.text.contains("BURN MARK")
	check(burn_comment, "Comments must call out a burned print")
	click(scene.result.back_button)
	await settle()
	check(level.panels[3].data.burned, "Back must preserve burns")
	var evidence_uv: Vector2 = level.panels[3].data.pois[1].position_uv
	var photo: MeshInstance3D = level.panels[3].photo
	var evidence_position := photo.to_global(Vector3((evidence_uv.x - 0.5) * photo.mesh.size.x, 0, (evidence_uv.y - 0.5) * photo.mesh.size.y))
	move_tool("MagnifyingGlass", evidence_position)
	await settle()
	await create_timer(2.7).timeout
	await settle()
	check(level.panels[3].data.pois[1].burned and level.panels[3].state == &"TAMPERED", "Burned evidence must remain tampering and never become a hidden-evidence win")

	# Originals use source photos without censorship or scorch overlays.
	click(scene.story.publish_button)
	await settle()
	click(scene.choice_ui.original_button)
	await settle(6)
	check(scene.snapshot.ending.choice == &"original", "Original choice creates the exposure ending")
	check(scene.snapshot.ending.headline.contains("EXPOSE"), "Original ending needs a distinct headline")
	check(scene.snapshot.light_values.count(1.0) == scene.snapshot.light_values.size(), "Originals must show the whole evidence page")
	check(scene.snapshot.burn_values.count(0.0) == scene.snapshot.burn_values.size(), "Originals must omit damage to desk copies")
	check(level.panels[3].data.burned, "Original publishing must not erase runtime damage")
	check(scene.result.reaction.counts.DAMNING == 4, "Uncensored evidence must expose all four crimes")
	await create_timer(3.9).timeout
	await screenshot("ending-original")
	click(scene.result.next_button)
	await settle()
	check(scene.case_index == 0 and not level.panels[3].data.burned, "Start again resets the campaign and all scorch data")
	var file := FileAccess.open("/tmp/shift-zero-campaign-inputs.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(published_inputs))
	print("PASS: five data-driven cases, real solutions and required optics, transitions, heat warning/timing/persistence, final choices and both endings.")
	quit(1 if failed else 0)
