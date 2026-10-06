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
	if counts["DAMNING"] > 0 and not templates.page_critic.is_empty():
		_add(comments, _comment(templates.page_critic, templates, config, rng, comments.size()), 0, config.comment_likes_max, templates.page_critic_reply, templates)
	if counts["SPUN"] * 2 >= snapshot.panels.size() and not templates.page_praise.is_empty():
		_add(comments, _comment(templates.page_praise, templates, config, rng, comments.size()), 0, config.comment_likes_max, "", templates)
	if counts["SPUN"] == snapshot.panels.size() and not templates.twist.is_empty():
		var twist := _comment(templates.twist, templates, config, rng, comments.size())
		twist["reply"] = templates.twist_reply
		twist["likes"] = config.comment_likes_max + 1
		comments.append(twist)
	var skeptical := value < config.fan_reply_minimum
	var remaining: Array = Array(templates.skeptic_comments if skeptical else templates.fan_comments)
	for i in config.generic_comment_count:
		if remaining.is_empty():
			break
		var generic := _comment(remaining.pop_at(rng.randi_range(0, remaining.size() - 1)), templates, config, rng, comments.size())
		# Doubters get an answer from the fan club; fans need none.
		_add(comments, generic, 0, 0, _pick(_defences(templates), rng) if skeptical else "", templates)
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
		_add(comments, _comment(templates.burned_comment % number, templates, config, rng, comments.size()), number, config.comment_likes_max, "", templates)
		return
	var used := PackedStringArray()
	if state == "DAMNING":
		var exposed: Array = []
		for poi in panel.pois:
			if poi.desired == POIData.Desired.HIDDEN and not poi.burned and poi.light >= snapshot.hidden_threshold \
					and (not poi.comment_lines.is_empty() or poi.type != POIData.Type.HERO):
				exposed.append(poi)
		exposed.sort_custom(func(a: Dictionary, b: Dictionary): return a.weight > b.weight)
		for poi in exposed.slice(0, config.evidence_comments_per_panel):
			var line := _evidence_line(poi, number, rng)
			if line in used:
				continue
			used.append(line)
			var extra: int = config.comment_likes_max + int(poi.weight * 40.0)
			_add(comments, _comment(line, templates, config, rng, comments.size()), number, extra, _defence(poi, number, templates, rng), templates)
	if used.is_empty():
		var text := String(panel.comments.get(state, "")).replace("{n}", str(number))
		if not text.is_empty():
			_add(comments, _comment(text, templates, config, rng, comments.size()), number, config.comment_likes_max, "", templates)
	_praise_comment(snapshot, panel, number, templates, config, rng, comments)


## Positive comment when Halcyon himself is lit and readable (unless he is the evidence).
static func _praise_comment(snapshot: Dictionary, panel: Dictionary, number: int, templates: CommentTemplates, config: ReactionConfig,
		rng: RandomNumberGenerator, comments: Array[Dictionary]) -> void:
	for poi in panel.pois:
		if poi.type != POIData.Type.HERO or poi.burned or poi.light < snapshot.visible_threshold or not poi.comment_lines.is_empty():
			continue
		var pool: PackedStringArray = poi.praise_lines if not poi.praise_lines.is_empty() else templates.praise_comments
		if pool.is_empty():
			return
		var line: String = _pick(pool, rng).replace("{n}", str(number))
		var comment := _comment(line, templates, config, rng, comments.size())
		_add(comments, comment, number, config.comment_likes_max + rng.randi_range(0, 250), "", templates)
		return


static func _evidence_line(poi: Dictionary, number: int, rng: RandomNumberGenerator) -> String:
	var line: String = poi.comment_lines[0] if not poi.comment_lines.is_empty() else _pick(ReactionLines.EVIDENCE.get(poi.type, ["Something is off in panel {n}."]), rng)
	return line.replace("{n}", str(number)).replace("{what}", String(poi.description).to_lower())


## A fan's answer to the evidence comment: this hitbox's own, else one for its type, else a general one.
static func _defence(poi: Dictionary, number: int, templates: CommentTemplates, rng: RandomNumberGenerator) -> String:
	var line: String
	if not poi.reply_lines.is_empty():
		line = poi.reply_lines[0]
	else:
		var pool: Array = ReactionLines.REPLIES.get(poi.type, [])
		line = _pick(pool if not pool.is_empty() else _defences(templates), rng)
	return line.replace("{n}", str(number)).replace("{what}", String(poi.description).to_lower())


static func _defences(templates: CommentTemplates) -> Array:
	var pool: Array = Array(templates.defender_replies)
	if not templates.fan_reply.is_empty():
		pool.append(templates.fan_reply)
	return pool


static func _pick(pool, rng: RandomNumberGenerator) -> String:
	return String(pool[rng.randi_range(0, pool.size() - 1)])


static func _add(comments: Array[Dictionary], comment: Dictionary, number: int, extra_likes: int, reply: String, templates: CommentTemplates) -> void:
	comment["panel"] = number
	comment["likes"] += extra_likes
	comment["reply"] = reply
	if not reply.is_empty() and not templates.defender_names.is_empty():
		comment["reply_user"] = templates.defender_names[comments.size() % templates.defender_names.size()]
	comments.append(comment)


static func _comment(text: String, templates: CommentTemplates, config: ReactionConfig, rng: RandomNumberGenerator, index: int) -> Dictionary:
	return {"user": templates.usernames[index % templates.usernames.size()], "text": text,
		"likes": rng.randi_range(config.comment_likes_min, config.comment_likes_max), "reply": "", "reply_user": "", "panel": 0}
