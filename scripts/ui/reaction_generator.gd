class_name ReactionGenerator
extends RefCounted
## Deterministic local templates; no network or generated dialogue.
## Reputation is the weighted sum of every hitbox (see Reputation); comments are
## written about what the printed page actually shows.

const VERDICTS: Array[String] = [
	"You printed the confession. Take another pass.",
	"That's a mess. Look at what is still in the frame.",
	"Half the city is asking questions. Close the gaps.",
	"Good. A few people squinting, nothing we can't ride out.",
	"Not one question in the comments. That is how it's done.",
]
const VERDICT_FLOORS: Array[int] = [0, 25, 50, 75, 95]


static func generate(snapshot: Dictionary, templates: CommentTemplates, config: ReactionConfig) -> Dictionary:
	var fingerprint := String(snapshot.case_id)
	var counts := {"SPUN": 0, "DAMNING": 0, "MURKY": 0, "TAMPERED": 0}
	var records: Array = []
	var worst: Dictionary = {}
	var hidden_total := 0.0
	var exposed_total := 0.0
	for panel in snapshot.panels:
		counts[String(panel.state)] += 1
		fingerprint += "|" + String(panel.state)
		for poi in panel.pois:
			fingerprint += "|" + String(poi.id) + ":" + String(poi.light_state) + ":" + str(poi.burned)
			records.append(poi)
			if poi.desired == POIData.Desired.HIDDEN:
				hidden_total += poi.weight
				if not poi.burned and poi.light >= snapshot.hidden_threshold:
					exposed_total += poi.weight
					if worst.is_empty() or poi.weight > worst.weight:
						worst = poi
	var value := clampi(roundi(Reputation.score(records, snapshot.hidden_threshold, snapshot.visible_threshold)), 0, 100)
	# Silent pass rules: a mostly dark (or mostly exposed) page can never win the city over.
	var gate_ok := Reputation.gate_passed(records, snapshot.hidden_threshold, snapshot.visible_threshold, snapshot.get("min_lit_share", 0.0), snapshot.get("min_dark_share", 0.0))
	if not gate_ok:
		value = mini(value, config.gate_fail_cap)
	var shares := Reputation.shares(records, snapshot.hidden_threshold, snapshot.visible_threshold)
	var band := 0
	for i in config.band_minima.size():
		if value >= config.band_minima[i]:
			band = i
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fingerprint)
	var comments: Array[Dictionary] = []
	for i in snapshot.panels.size():
		_panel_comments(snapshot, snapshot.panels[i], i + 1, templates, config, rng, value, comments)
	if counts["MURKY"] >= 3:
		comments.append(_comment(templates.murky_group, templates, config, rng, comments.size()))
	if hidden_total > 0.0 and exposed_total >= hidden_total * 0.75 and not templates.exposed_group.is_empty():
		var group := _comment(templates.exposed_group, templates, config, rng, comments.size())
		group["likes"] = config.comment_likes_max + 200
		comments.append(group)
	if counts["SPUN"] == snapshot.panels.size() and not templates.twist.is_empty():
		var twist := _comment(templates.twist, templates, config, rng, comments.size())
		twist["reply"] = templates.twist_reply
		twist["likes"] = config.comment_likes_max + 1
		comments.append(twist)
	var pool := templates.fan_comments if value >= config.fan_reply_minimum else templates.skeptic_comments
	for i in config.generic_comment_count:
		comments.append(_comment(pool[rng.randi_range(0, pool.size() - 1)], templates, config, rng, comments.size()))
	comments.sort_custom(func(a: Dictionary, b: Dictionary): return a.likes > b.likes)
	var verdict := VERDICTS[0]
	for i in VERDICT_FLOORS.size():
		if value >= VERDICT_FLOORS[i]:
			verdict = VERDICTS[i]
	if counts["TAMPERED"] > 0:
		verdict = "The prints are burnt. Keep the torch off the paper."
	elif not gate_ok and shares.lit < snapshot.get("min_lit_share", 0.0):
		verdict = "Too much shadow. Readers need a hero they can see."
	elif not worst.is_empty() and value < 95:
		verdict += " \"%s\" is still showing." % String(worst.description).to_lower()
	return {"score": value, "band": band, "mood": config.band_names[band], "summary": config.band_summaries[band], "counts": counts,
		"verdict": verdict, "passed": counts["SPUN"] >= snapshot.required_spun,
		"likes": config.likes_base + value * config.likes_per_score,
		"comment_count": config.comments_base + (100 - value) * config.comments_per_outrage,
		"shares": config.shares_base + value * config.shares_per_score,
		"comments": comments, "displayed_comments": config.displayed_comments, "post_caption": templates.post_caption}


## Comments about this very panel: what the caption says, and what the light left in view.
static func _panel_comments(snapshot: Dictionary, panel: Dictionary, number: int, templates: CommentTemplates, config: ReactionConfig,
		rng: RandomNumberGenerator, value: int, comments: Array[Dictionary]) -> void:
	var state := String(panel.state)
	if state == "TAMPERED":
		_add(comments, _comment(templates.burned_comment % number, templates, config, rng, comments.size()), number, config.comment_likes_max, "")
		return
	if state == "DAMNING":
		var exposed: Array = []
		for poi in panel.pois:
			if poi.desired == POIData.Desired.HIDDEN and not poi.burned and poi.light >= snapshot.hidden_threshold and not poi.comment_lines.is_empty():
				exposed.append(poi)
		exposed.sort_custom(func(a: Dictionary, b: Dictionary): return a.weight > b.weight)
		var used := PackedStringArray()
		for poi in exposed.slice(0, 2):
			var line: String = poi.comment_lines[0].replace("{n}", str(number))
			if line in used:
				continue
			used.append(line)
			var reply := templates.fan_reply if value >= config.fan_reply_minimum and used.size() == 1 else ""
			_add(comments, _comment(line, templates, config, rng, comments.size()), number, config.comment_likes_max + int(poi.weight * 40.0), reply)
		if not used.is_empty():
			return
	var text := String(panel.comments.get(state, "")).replace("{n}", str(number))
	if not text.is_empty():
		_add(comments, _comment(text, templates, config, rng, comments.size()), number, config.comment_likes_max, "")


static func _add(comments: Array[Dictionary], comment: Dictionary, number: int, extra_likes: int, reply: String) -> void:
	comment["panel"] = number
	comment["likes"] += extra_likes
	comment["reply"] = reply
	comments.append(comment)


static func _comment(text: String, templates: CommentTemplates, config: ReactionConfig, rng: RandomNumberGenerator, index: int) -> Dictionary:
	return {"user": templates.usernames[index % templates.usernames.size()], "text": text,
		"likes": rng.randi_range(config.comment_likes_min, config.comment_likes_max), "reply": "", "panel": 0}
