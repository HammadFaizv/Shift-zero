class_name Interpretation
extends RefCounted


static func evaluate(data: PanelData, hidden: float, visible: float) -> StringName:
	for rule in data.rule_order:
		match rule:
			PanelData.Rule.EXPOSED_EVIDENCE:
				for poi in data.pois:
					if poi.desired == POIData.Desired.HIDDEN and not poi.burned and poi.current_light >= hidden:
						return &"DAMNING"
			PanelData.Rule.BURN_MARK:
				if data.burned:
					return &"TAMPERED"
				for poi in data.pois:
					if poi.burned:
						return &"TAMPERED"
			PanelData.Rule.LIT_HEROES:
				var has_hero := false
				var lit := true
				for poi in data.pois:
					if poi.desired == POIData.Desired.VISIBLE:
						has_hero = true
						lit = lit and not poi.burned and poi.current_light >= visible
				if has_hero and lit:
					return &"SPUN"
	return data.fallback_state
