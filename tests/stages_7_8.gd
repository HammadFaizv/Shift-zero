extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check(scene.campaign.size() == 8, "Eight cases in campaign")
	for index in [6, 7, 0, 6, 7]:
		scene.load_case(index)
		await process_frame
		await physics_frame
		var count: int = 6 if index == 6 else 5 if index == 7 else 1
		check(scene.level.panels.size() == count, "Active photo count")
		check(get_nodes_in_group("evidence_panels").size() == count, "Unused slots disabled")
		for rect in scene.level.data.photo_layouts:
			check(absf(rect.position.x) + rect.size.x / 2 <= 2.35 and rect.position.y - rect.size.y / 2 >= -2.15 and rect.position.y + rect.size.y / 2 <= 2.55, "Photos fit playable page")
		var ceiling = scene.get_node("Tools/CeilingLight")
		ceiling.toggle()
		await physics_frame
		scene.get_node("LightEvaluator").refresh()
		for panel in scene.level.panels:
			for poi in panel.data.pois:
				check(poi.current_light >= .55, "Inspection light reaches every new target")
		ceiling.toggle()
		var poi_count := 0
		for panel in scene.level.panels:
			poi_count += panel.data.pois.size()
			var pixels: Vector2 = panel.data.texture.get_size()
			check(absf(panel.photo.mesh.size.aspect() - pixels.aspect()) < .001, "Image proportions preserved")
			check(panel.photo.material_overlay != null, "Every slot has live ink overlay")
			for poi in panel.data.pois:
				poi.current_light = 1.0 if poi.desired == POIData.Desired.VISIBLE else 0.0
			check(Interpretation.evaluate(panel.data, .3, .55) == &"SPUN", "Requested targets produce SPUN")
			for poi in panel.data.pois:
				if poi.desired == POIData.Desired.HIDDEN:
					poi.current_light = 1.0
					check(Interpretation.evaluate(panel.data, .3, .55) == &"DAMNING", "Each hidden clue affects interpretation")
					poi.current_light = 0.0
		check(get_nodes_in_group("evidence_pois").size() == poi_count, "No stale targets on case changes")
		for tool in scene.get_node("Tools").get_children():
			check(tool.visible == (String(tool.name) in scene.level.data.available_tools), "Correct tool availability")
			if tool.has_node("PickBody"):
				check((tool.get_node("PickBody").collision_layer > 0) == tool.visible, "Hidden tools cannot intercept mouse")
		if index == 0:
			continue
		var panels: Array[PanelData] = []
		for panel in scene.level.panels: panels.append(panel.data)
		check(is_equal_approx(Reputation.score(Reputation.records_from(panels), .3, .55), 100.0), "Perfect targets score 100")
		check(scene.level.data.comic_columns == (3 if index == 6 else 2), "Requested column count")
		if index == 7:
			check(scene.level.data.photo_layouts[4].size.x > scene.level.data.photo_layouts[0].size.x * 2, "Factory final image spans both columns")
		await scene.publish()
		await process_frame
		check(scene.snapshot.panels.size() == count, "All photos included in published comic")
		check(scene.result.panel_views.size() == count, "All comic views created")
		for record in scene.result.panel_views:
			check(record.view.size.x > 0 and record.view.size.y > 0, "Comic panels laid out")
		var views: Array = scene.result.panel_views
		if index == 6:
			var centre_a: float = views[0].view.position.y + views[0].view.size.y / 2
			var centre_c: float = views[2].view.position.y + views[2].view.size.y / 2
			check(absf(centre_a - centre_c) < 1.0 and views[0].view.position.x < views[1].view.position.x and views[1].view.position.x < views[2].view.position.x and views[3].view.position.y > views[2].view.position.y, "Comic uses three columns and two rows")
		else:
			check(views[4].view.size.x > views[0].view.size.x * 2 and views[4].view.position.y > views[3].view.position.y, "Comic bottom photograph spans both columns")
		scene.back_to_desk()
		await process_frame
	scene.load_case(6)
	await scene.publish()
	for panel in scene.snapshot.panels:
		for poi in panel.pois:
			poi.light = 1.0 if poi.desired == POIData.Desired.VISIBLE else 0.0
	scene.confirm_publish()
	scene.next_case()
	check(scene.case_index == 7, "Stage 7 advances to Stage 8")
	await scene.publish()
	check(scene.snapshot.campaign_complete, "Stage 8 is last available case")
	print("Stages 7–8 regression: ", failures, " failures")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
