extends SceneTree
## Hill-climbs tool placements for every stage and reports the best reputation each can reach.
##   godot --headless --path . --script tools/solve_stages.gd -- [stage 1-8] [restarts] [steps]
## Scores include the silent pass rules (capped when they fail). Instant lighting only: magnifier scorching over time is not simulated.

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	Engine.physics_ticks_per_second = 1000
	Engine.max_physics_steps_per_frame = 64
	rng.seed = 7
	var args := OS.get_cmdline_user_args()
	var only := int(args[0]) if args.size() > 0 else 0
	var restarts := int(args[1]) if args.size() > 1 else 6
	var steps := int(args[2]) if args.size() > 2 else 150
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	for i in 4:
		await physics_frame
	var bounds: Rect2 = scene.get_node("InteractionManager").desk_bounds
	for index in scene.campaign.size():
		if only != 0 and index + 1 != only:
			continue
		scene.load_case(index)
		for i in 4:
			await physics_frame
		var tools: Array[Node3D] = []
		for tool in scene.get_node("Tools").get_children():
			if tool.name != &"CeilingLight" and tool.visible and tool.has_node("Draggable") and String(tool.name) in scene.level.data.available_tools:
				tools.append(tool)
		var start_state := _state(tools)
		var best_score := -1.0
		var best_state: Array = start_state
		for restart in restarts:
			var current: Array = start_state if restart == 0 else _random_state(tools, bounds)
			var current_score: float = await _evaluate(scene, tools, current, bounds)
			for step in steps:
				var candidate := _mutate(current, bounds)
				var score: float = await _evaluate(scene, tools, candidate, bounds)
				if score >= current_score:
					current = candidate
					current_score = score
			if current_score > best_score:
				best_score = current_score
				best_state = current
		await _evaluate(scene, tools, best_state, bounds)
		var counts: Dictionary = scene.level.counts()
		print("STAGE %d  best %.1f  (SPUN %d DAMNING %d MURKY %d)  %s" % [index + 1, best_score, counts["SPUN"], counts["DAMNING"], counts["MURKY"], _describe(tools, best_state)])
	quit()


func _state(tools: Array[Node3D]) -> Array:
	var state: Array = []
	for tool in tools:
		state.append({"x": tool.global_position.x, "z": tool.global_position.z, "yaw": tool.rotation.y})
	return state


func _random_state(tools: Array[Node3D], bounds: Rect2) -> Array:
	var state: Array = []
	for tool in tools:
		state.append({"x": rng.randf_range(bounds.position.x + 0.5, bounds.end.x - 0.5), "z": rng.randf_range(bounds.position.y + 0.5, bounds.end.y - 0.5), "yaw": rng.randf_range(-PI, PI)})
	return state


func _mutate(state: Array, bounds: Rect2) -> Array:
	var next := state.duplicate(true)
	var item: Dictionary = next[rng.randi() % next.size()]
	match rng.randi() % 4:
		0:
			item.x = clampf(item.x + rng.randfn(0.0, 0.5), bounds.position.x + 0.5, bounds.end.x - 0.5)
			item.z = clampf(item.z + rng.randfn(0.0, 0.5), bounds.position.y + 0.5, bounds.end.y - 0.5)
		1:
			item.yaw += rng.randfn(0.0, 0.4)
		2:
			item.x = clampf(item.x + rng.randfn(0.0, 0.15), bounds.position.x + 0.5, bounds.end.x - 0.5)
			item.z = clampf(item.z + rng.randfn(0.0, 0.15), bounds.position.y + 0.5, bounds.end.y - 0.5)
			item.yaw += rng.randfn(0.0, 0.1)
		_:
			item.x = rng.randf_range(bounds.position.x + 0.5, bounds.end.x - 0.5)
			item.z = rng.randf_range(bounds.position.y + 0.5, bounds.end.y - 0.5)
			item.yaw = rng.randf_range(-PI, PI)
	return next


func _evaluate(scene: Node, tools: Array[Node3D], state: Array, bounds: Rect2) -> float:
	for i in tools.size():
		tools[i].get_node("Draggable").move_to(Vector3(state[i].x, 0, state[i].z), bounds)
		tools[i].rotation.y = state[i].yaw
		tools[i].force_update_transform()
	await physics_frame
	await physics_frame
	scene.get_node("LightEvaluator").refresh()
	var panels: Array[PanelData] = []
	for panel in scene.level.panels:
		panels.append(panel.data)
	var evaluator: LightEvaluator = scene.get_node("LightEvaluator")
	var records := Reputation.records_from(panels)
	var score := Reputation.score(records, evaluator.hidden_threshold, evaluator.visible_threshold)
	var data: LevelData = scene.level.data
	if not Reputation.gate_passed(records, evaluator.hidden_threshold, evaluator.visible_threshold, data.min_lit_share, data.min_dark_share):
		score = minf(score, float(data.reaction_config.gate_fail_cap))
	return score


func _describe(tools: Array[Node3D], state: Array) -> String:
	var parts := PackedStringArray()
	for i in tools.size():
		parts.append("%s(%.2f, %.2f, %d deg)" % [tools[i].name, state[i].x, state[i].z, roundi(rad_to_deg(state[i].yaw))])
	return " ".join(parts)
