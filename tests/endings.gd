extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

# Isolate mood routing from puzzle balance by weighting two captured POIs.
func set_score(scene: Node, value: float) -> void:
	var source: Dictionary = scene.snapshot.panels[0].pois[0].duplicate(true)
	for panel in scene.snapshot.panels:
		panel.pois.clear()
		panel.state = &"SPUN"
	var lit := source.duplicate(true)
	lit.merge({"id": &"lit", "desired": POIData.Desired.VISIBLE, "light": 1.0, "weight": value, "burned": false}, true)
	var dark := source.duplicate(true)
	dark.merge({"id": &"dark", "desired": POIData.Desired.VISIBLE, "light": 0.0, "weight": 100.0 - value, "burned": false}, true)
	scene.snapshot.panels[0].pois = [lit, dark]

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var plate = scene.get_node("DeskStage/Props/Nameplate")
	check(plate.names.size() == 15, "Fifteen editor names")
	var initial_name: String = plate.editor_name
	var tool = scene.get_node("Tools/Torch")
	var pose: Transform3D = tool.transform
	await scene.publish()
	check(scene.is_proof and scene.result.is_proof, "Publish first opens unpublished proof")
	check(scene.cleared_cases.is_empty() and scene.ending == null, "Proof does not commit outcomes")
	scene.next_case()
	check(scene.case_index == 0, "Cannot advance from proof")
	scene.back_to_desk()
	check(tool.transform == pose and plate.editor_name == initial_name, "Keep editing preserves desk and identity")
	# The first three stages only ever offer a retry, even for a furious city.
	for early in 3:
		scene.load_case(early)
		await physics_frame
		await scene.publish()
		set_score(scene, 0)
		scene.confirm_publish()
		check(scene.ending == null and plate.editor_name == initial_name, "Stage %d: no bad ending, just a retry" % (early + 1))
		check(not scene.snapshot.next_available and scene.result.next_button.text == "TRY AGAIN", "Stage %d: failing offers TRY AGAIN" % (early + 1))
		scene.back_to_desk()
	scene.load_case(3)
	await physics_frame
	pose = tool.transform
	for boundary in [40, 59, 60, 39]:
		await scene.publish()
		set_score(scene, boundary)
		scene.confirm_publish()
		if boundary < 40:
			check(scene.ending != null and not scene.ending.good, "Below Divided triggers bad ending")
			check(plate.editor_name != initial_name, "Bad ending changes editor")
			check(scene.ending.revealed == 1, "Bad ending starts with 2A")
			await create_timer(1.15).timeout
			check(scene.ending.revealed == 2 and scene.ending.complete, "2B appears after one second")
			scene.retry_stage()
			check(scene.case_index == 3 and tool.transform == pose, "Bad retry preserves stage and tool pose")
		else:
			check(scene.ending == null, "No bad ending at Divided or above")
			check(scene.snapshot.next_available == (boundary >= 60), "Only above Divided clears stage")
			check(plate.editor_name == initial_name, "Name stable without bad ending")
			scene.back_to_desk()
	var retry_name: String = plate.editor_name
	scene.load_case(scene.campaign.size() - 1)
	await physics_frame
	await scene.publish()
	set_score(scene, 100)
	scene.confirm_publish()
	check(scene.ending == null, "Final stage alone cannot earn good ending")
	scene.back_to_desk()
	scene.cleared_cases.clear()
	for index in scene.campaign.size():
		scene.load_case(index)
		await physics_frame
		await scene.publish()
		set_score(scene, 100)
		scene.confirm_publish()
		check(plate.editor_name == retry_name, "Editor persists between stages")
		if index < scene.campaign.size() - 1:
			check(scene.ending == null, "Good ending waits until last stage")
			scene.next_case()
		else:
			check(scene.ending != null and scene.ending.good, "Clearing every stage triggers good ending")
			var ending = scene.ending
			for i in range(1, 5):
				ending.advance()
				check(ending.revealed == i + 1 and ending.page_index == 0, "1A–1E reveal in alphabetical order on page 1")
			ending.advance()
			check(ending.page_index == 1 and ending.images[5].visible and not ending.images[0].visible, "1F occupies page 2")
			check(ending.complete and ending.finish_button.visible and ending.thanks.visible, "Thanks and replay after good ending")
			scene.replay_campaign()
			check(scene.case_index == 0 and scene.cleared_cases.is_empty(), "Replay starts a new campaign")
			check(plate.editor_name == retry_name, "Replay does not replace editor")
	# Prior clears and burns survive a bad-ending retry.
	scene.cleared_cases[0] = 80
	scene.load_case(3)
	await physics_frame
	scene.level.panels[0].add_burn(Vector2(.8,.8), .1)
	await scene.publish()
	set_score(scene, 0)
	scene.confirm_publish()
	scene.ending.skip()
	check(scene.ending.complete, "Skip completes ending immediately")
	scene.retry_stage()
	check(scene.cleared_cases.has(0) and scene.level.panels[0].data.burned, "Bad retry preserves earlier clears and scorch marks")
	print("Ending regression: ", failures, " failures")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
