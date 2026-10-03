class_name ReactionGenerator
extends RefCounted
## Deterministic local templates; no network or generated dialogue.


static func generate(snapshot: Dictionary, templates: CommentTemplates, config: ReactionConfig) -> Dictionary:
	var score := config.starting_score
	var fingerprint := String(snapshot.case_id)
	var counts := {"SPUN": 0, "DAMNING": 0, "MURKY": 0, "TAMPERED": 0}
	var damning_titles := PackedStringArray()
	for panel in snapshot.panels:
		var state := String(panel.state)
		counts[state] += 1
		score += float(config.state_weights.get(state, 0.0))
		fingerprint += "|" + state
		for poi in panel.pois:
			fingerprint += "|" + String(poi.id) + ":" + String(poi.light_state) + ":" + str(poi.burned)
		if state == "DAMNING":
			damning_titles.append(panel.title)
	var value := clampi(roundi(score), 0, 100)
	var band := 0
	for i in config.band_minima.size():
		if value >= config.band_minima[i]:
			band = i
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fingerprint)
	var comments: Array[Dictionary] = []
	for i in snapshot.panels.size():
		var panel: Dictionary = snapshot.panels[i]
		var text := String(panel.comments.get(String(panel.state), ""))
		if panel.state == &"TAMPERED":
			text = templates.burned_comment % (i + 1)
		if not text.is_empty():
			var comment := _comment(text, templates, config, rng, i)
			comment["panel"] = i + 1
			comment["likes"] += config.comment_likes_max
			if panel.state == &"DAMNING" and value >= config.fan_reply_minimum:
				comment["reply"] = templates.fan_reply
			comments.append(comment)
	if counts["MURKY"] >= 3:
		comments.append(_comment(templates.murky_group, templates, config, rng, comments.size()))
	if counts["SPUN"] == snapshot.panels.size() and not templates.twist.is_empty():
		var twist := _comment(templates.twist, templates, config, rng, comments.size())
		twist["reply"] = templates.twist_reply
		twist["likes"] = config.comment_likes_max + 1
		comments.append(twist)
	var pool := templates.fan_comments if value >= config.fan_reply_minimum else templates.skeptic_comments
	for i in config.generic_comment_count:
		comments.append(_comment(pool[rng.randi_range(0, pool.size() - 1)], templates, config, rng, comments.size()))
	comments.sort_custom(func(a: Dictionary, b: Dictionary): return a.likes > b.likes)
	var verdict := "Excellent work."
	if not damning_titles.is_empty():
		verdict = "Check the composition in %s. Keep the focus on Halcyon." % ", ".join(damning_titles)
	if counts["TAMPERED"] > 0:
		if damning_titles.is_empty():
			verdict = "The prints are damaged. Try a fresh set."
		verdict += " Never touch the prints."
	elif damning_titles.is_empty() and counts["SPUN"] < snapshot.required_spun:
		verdict = "Too much shadow. Readers need a hero they can see."
	return {"score": value, "band": band, "mood": config.band_names[band], "summary": config.band_summaries[band], "counts": counts,
		"verdict": verdict, "passed": counts["SPUN"] >= snapshot.required_spun,
		"likes": config.likes_base + value * config.likes_per_score,
		"comment_count": config.comments_base + (100 - value) * config.comments_per_outrage,
		"shares": config.shares_base + value * config.shares_per_score,
		"comments": comments, "displayed_comments": config.displayed_comments, "post_caption": templates.post_caption}


static func _comment(text: String, templates: CommentTemplates, config: ReactionConfig, rng: RandomNumberGenerator, index: int) -> Dictionary:
	return {"user": templates.usernames[index % templates.usernames.size()], "text": text,
		"likes": rng.randi_range(config.comment_likes_min, config.comment_likes_max), "reply": "", "panel": 0}
