class_name Reputation
extends RefCounted
## Per-hitbox reputation maths. Every POI is worth its `importance` points: a
## hidden POI that is exposed costs that many, a visible POI that stays dark
## forgoes them. Heavier crimes therefore hurt more when exposed.

enum Tier { MINOR, SERIOUS, DEVASTATING }

const SERIOUS_FROM: float = 3.0
const DEVASTATING_FROM: float = 5.0
const TIER_WORDS: PackedStringArray = ["minor", "serious", "devastating"]


static func tier(weight: float) -> int:
	if weight >= DEVASTATING_FROM:
		return Tier.DEVASTATING
	return Tier.SERIOUS if weight >= SERIOUS_FROM else Tier.MINOR


static func tier_word(weight: float) -> String:
	return TIER_WORDS[tier(weight)]


## 0..1 share of a POI's points that the current lighting earns.
static func credit(desired: int, light: float, burned: bool, hidden: float, visible: float) -> float:
	if burned:
		return 0.0
	if desired == POIData.Desired.HIDDEN:
		return 0.0 if light >= hidden else 1.0
	if light >= visible:
		return 1.0
	return 0.5 if light >= hidden else 0.0


static func poi_credit(poi: POIData, hidden: float, visible: float) -> float:
	return credit(poi.desired, poi.current_light, poi.burned, hidden, visible)


static func is_satisfied(poi: POIData, hidden: float, visible: float) -> bool:
	return poi_credit(poi, hidden, visible) >= 1.0


static func is_exposed(poi: POIData, hidden: float) -> bool:
	return poi.desired == POIData.Desired.HIDDEN and not poi.burned and poi.current_light >= hidden


## Reputation 0..100 from POI records ({desired, light, burned, weight}).
static func score(records: Array, hidden: float, visible: float) -> float:
	var total := 0.0
	var earned := 0.0
	for record in records:
		var weight: float = record.weight
		total += weight
		earned += weight * credit(record.desired, record.light, record.burned, hidden, visible)
	return 100.0 * earned / total if total > 0.0 else 0.0


## Silent pass rules: enough of what must be lit is lit, and enough of what must stay dark is dark.
## Returns {lit: share of visible hitboxes fully lit, dark: share of hidden hitboxes safely hidden}.
## A group with no hitboxes counts as fully satisfied.
static func shares(records: Array, hidden: float, visible: float) -> Dictionary:
	var lit_total := 0
	var lit_ok := 0
	var dark_total := 0
	var dark_ok := 0
	for record in records:
		var done: bool = credit(record.desired, record.light, record.burned, hidden, visible) >= 1.0
		if record.desired == POIData.Desired.HIDDEN:
			dark_total += 1
			dark_ok += int(done)
		else:
			lit_total += 1
			lit_ok += int(done)
	return {"lit": float(lit_ok) / lit_total if lit_total > 0 else 1.0, "dark": float(dark_ok) / dark_total if dark_total > 0 else 1.0}


static func gate_passed(records: Array, hidden: float, visible: float, min_lit: float, min_dark: float) -> bool:
	var found := shares(records, hidden, visible)
	return found.lit >= min_lit - 0.0001 and found.dark >= min_dark - 0.0001


static func records_from(panels: Array[PanelData]) -> Array:
	var records: Array = []
	for panel in panels:
		for poi in panel.pois:
			records.append({"desired": poi.desired, "light": poi.current_light, "burned": poi.burned, "weight": poi.importance})
	return records


## The editor's one-line read of the page, written so that something is always
## "left". Returns {text, tone} where tone is one of calm/warn/bad/good.
static func headline(panels: Array[PanelData], hidden: float, visible: float) -> Dictionary:
	var hidden_total := 0.0
	var exposed_total := 0.0
	var heaviest := 0.0
	var heaviest_exposed := false
	var unlit := false
	var scorched := false
	for panel in panels:
		scorched = scorched or panel.burned
		for poi in panel.pois:
			scorched = scorched or poi.burned
			if poi.desired == POIData.Desired.HIDDEN:
				hidden_total += poi.importance
				var exposed := is_exposed(poi, hidden)
				if exposed:
					exposed_total += poi.importance
				if poi.importance > heaviest:
					heaviest = poi.importance
					heaviest_exposed = exposed
				elif is_equal_approx(poi.importance, heaviest):
					heaviest_exposed = heaviest_exposed or exposed
			elif not is_satisfied(poi, hidden, visible):
				unlit = true
	if scorched:
		return {"text": "The prints are scorched. Nothing here can run.", "tone": "bad"}
	if exposed_total <= 0.0:
		if unlit:
			return {"text": "His greatness is still in the dark.", "tone": "calm"}
		return {"text": "Our superhero's greatness knows no bound.", "tone": "good"}
	if exposed_total >= hidden_total * 0.75:
		return {"text": "Everything is exposed.", "tone": "bad"}
	if heaviest_exposed:
		return {"text": "The elephant in the room is left.", "tone": "warn"}
	return {"text": "Some things are still left.", "tone": "warn"}
