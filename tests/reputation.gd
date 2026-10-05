extends SceneTree
## Per-hitbox reputation, headline wording, comic comments and enlarged layouts.
## godot --headless --path . --script tests/reputation.gd
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func verify(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func set_lights(scene: Node, hidden_light: float, visible_light: float, only: String = "") -> void:
	for panel in scene.level.panels:
		for poi in panel.data.pois:
			poi.current_light = hidden_light if poi.desired == POIData.Desired.HIDDEN else visible_light
			if only != "" and poi.description == only:
				poi.current_light = 1.0
		panel.state = Interpretation.evaluate(panel.data, 0.3, 0.55)


func score(scene: Node) -> float:
	var panels: Array[PanelData] = []
	for panel in scene.level.panels:
		panels.append(panel.data)
	return Reputation.score(Reputation.records_from(panels), 0.3, 0.55)


func headline(scene: Node) -> String:
	var panels: Array[PanelData] = []
	for panel in scene.level.panels:
		panels.append(panel.data)
	return Reputation.headline(panels, 0.3, 0.55).text



## Capture a snapshot and reaction for the forced POI lights (capture() re-reads the evaluator, so restate them).
func reaction_for(scene: Node) -> Dictionary:
	var snapshot: Dictionary = scene.get_node("ComicRenderer").capture(scene.level, scene.get_node("InkPreview"), scene.get_node("LightEvaluator"))
	for i in snapshot.panels.size():
		for j in snapshot.panels[i].pois.size():
			snapshot.panels[i].pois[j]["light"] = scene.level.panels[i].data.pois[j].current_light
	return ReactionGenerator.generate(snapshot, scene.level.data.comment_templates, scene.level.data.reaction_config)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for index in 7:
		scene.load_case(index)
		await process_frame
		var hidden_total := 0.0
		for panel in scene.level.panels:
			for poi in panel.data.pois:
				verify(poi.importance > 0.0, "Every hitbox is worth points (case %d %s)" % [index + 1, poi.description])
				if poi.desired == POIData.Desired.HIDDEN:
					hidden_total += poi.importance
			verify(not panel.data.rationale.is_empty(), "Every print has an editor rationale")
			for state in ["SPUN", "DAMNING", "MURKY", "TAMPERED"]:
				verify(not String(panel.data.captions.get(state, "")).is_empty(), "Caption for every state")
		set_lights(scene, 0.0, 1.0)
		verify(is_equal_approx(score(scene), 100.0), "Perfect lighting scores 100 (case %d)" % (index + 1))
		if hidden_total > 0.0:
			verify(headline(scene) == "Our superhero's greatness knows no bound.", "Perfect headline (case %d)" % (index + 1))
			set_lights(scene, 1.0, 1.0)
			verify(score(scene) < 60.0, "Exposing every crime hurts (case %d)" % (index + 1))
			verify(headline(scene) == "Everything is exposed.", "Everything-exposed headline (case %d)" % (index + 1))
		set_lights(scene, 0.0, 1.0)
		verify(reaction_for(scene).band >= 3, "The intended page clears stage %d" % (index + 1))
		set_lights(scene, 0.0, 0.0)
		var dark_reaction := reaction_for(scene)
		verify(dark_reaction.band < 3 and dark_reaction.score <= scene.level.data.reaction_config.gate_fail_cap, "A page with no lighting cannot pass stage %d" % (index + 1))
		verify(score(scene) < 100.0, "A dark page forgoes the hero's points")
		verify(headline(scene) == "His greatness is still in the dark.", "Unlit headline (case %d)" % (index + 1))
		# Page photos never leave the (unchanged) 4.7 x 5.85 case file.
		for rect in scene.level.data.photo_layouts:
			verify(absf(rect.position.x) + rect.size.x * 0.5 <= 2.35 and rect.position.y - rect.size.y * 0.5 >= -2.15 and rect.position.y + rect.size.y * 0.5 <= 2.55, "Photo fits the page (case %d)" % (index + 1))

	# Bank: striking a man (panel 3) is a bigger hit than money in the wind (panel 4).
	scene.load_case(5)
	await process_frame
	set_lights(scene, 0.0, 1.0)
	var perfect := score(scene)
	var drops := {}
	for panel in scene.level.panels:
		for poi in panel.data.pois:
			if poi.desired == POIData.Desired.HIDDEN:
				drops[poi.description] = poi.importance
	set_lights(scene, 0.0, 1.0, "Hero head")
	var head_hit := perfect - score(scene)
	set_lights(scene, 0.0, 1.0, "Falling bill 1")
	var bill_hit := perfect - score(scene)
	verify(head_hit > bill_hit * 5.0, "Exposing the hero hitting someone must cost far more than one falling bill")
	verify(Reputation.tier(drops["Hero head"]) == Reputation.Tier.DEVASTATING and Reputation.tier(drops["Falling bill 1"]) == Reputation.Tier.MINOR, "Severity tiers")
	set_lights(scene, 0.0, 1.0, "Hero head")
	verify(headline(scene) == "The elephant in the room is left.", "Heaviest exposed hitbox is the elephant")
	set_lights(scene, 0.0, 1.0, "Falling bill 1")
	verify(headline(scene) == "Some things are still left.", "A lesser exposure leaves something")

	# Comments describe what the printed page shows.
	set_lights(scene, 0.0, 1.0, "Hero head")
	var snapshot: Dictionary = scene.get_node("ComicRenderer").capture(scene.level, scene.get_node("InkPreview"), scene.get_node("LightEvaluator"))
	# capture() re-reads POI lights from the evaluator's last pass, so restate the forced lights.
	for i in snapshot.panels.size():
		for j in snapshot.panels[i].pois.size():
			snapshot.panels[i].pois[j]["light"] = scene.level.panels[i].data.pois[j].current_light
	var reaction := ReactionGenerator.generate(snapshot, scene.level.data.comment_templates, scene.level.data.reaction_config)
	var texts: PackedStringArray = []
	for comment in reaction.comments:
		texts.append(comment.text)
		verify(not comment.text.contains("{n}"), "Panel numbers are filled in")
	verify(", ".join(texts).contains("grabbing the manager in panel 3"), "Exposed hero head produces a panel-3 comment")
	verify(reaction.score < 100, "Exposure costs reputation in the reaction")
	print("Reputation regression: ", failures, " failures")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
