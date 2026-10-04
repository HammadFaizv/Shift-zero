extends Node
## Frozen higher-resolution samples of the same light_at() used at the desk.

@export var print_grid_multiplier: int = 2
@export var print_ink_color: Color = Color("2a1f5c")
@export var posterize_steps: float = 5.0
@export var color_boost: float = 2.4
@export var comic_brightness: float = 1.25
@export var edge_strength: float = 2.2
@export var halftone_spacing: float = 5.0
@export var edge_threshold: float = 0.13

var last_capture_usec: int = 0


func capture(level: LevelManager, ink: Node, evaluator: LightEvaluator) -> Dictionary:
	var start := Time.get_ticks_usec()
	var resolution: Vector2i = ink.grid_resolution * maxi(print_grid_multiplier, 1)
	var page: MeshInstance3D = ink.page_mesh
	var size: Vector3 = page.mesh.get_aabb().size
	var values := PackedFloat32Array()
	var burns := PackedFloat32Array()
	values.resize(resolution.x * resolution.y)
	burns.resize(values.size())
	var has_burns := false
	for panel in level.panels:
		has_burns = has_burns or panel.data.burned
	for y in resolution.y:
		for x in resolution.x:
			var local := Vector3(((float(x) + 0.5) / resolution.x - 0.5) * size.x, ink.sample_height, ((float(y) + 0.5) / resolution.y - 0.5) * size.z)
			values[y * resolution.x + x] = evaluator.light_at(page.to_global(local))
			burns[y * resolution.x + x] = ink.burn_at(page.to_global(local)) if has_burns else 0.0
	var image := Image.create_from_data(resolution.x, resolution.y, false, Image.FORMAT_RF, values.to_byte_array())
	var light_map := ImageTexture.create_from_image(image)
	var burn_map := ImageTexture.create_from_image(Image.create_from_data(resolution.x, resolution.y, false, Image.FORMAT_RF, burns.to_byte_array()))
	var records: Array[Dictionary] = []
	for panel in level.panels:
		var photo_size := (panel.photo.mesh as PlaneMesh).size
		var position := page.to_local(panel.photo.global_position)
		var uv_rect := Vector4((position.x - photo_size.x * 0.5) / size.x + 0.5, (position.z - photo_size.y * 0.5) / size.z + 0.5, photo_size.x / size.x, photo_size.y / size.z)
		var pois: Array[Dictionary] = []
		for poi in panel.poi_nodes:
			pois.append({"id": poi.data.id, "description": poi.data.description, "desired": poi.data.desired, "light": poi.data.current_light,
				"light_state": poi.light_state, "burned": poi.data.burned, "weight": poi.data.importance, "type": poi.data.type,
				"position_uv": poi.data.position_uv, "comment_lines": poi.data.comment_lines})
		records.append({"id": panel.data.id, "title": panel.data.title, "state": panel.state, "photo": panel.data.texture,
			"caption": panel.caption(), "balloon": panel.data.balloons.get(String(panel.state), ""),
			"sfx": panel.data.sound_effects.get(String(panel.state), ""), "comments": panel.data.comments.duplicate(true),
			"pois": pois, "uv_rect": uv_rect, "burned": panel.data.burned})
	var counts := level.counts()
	var subtitle_key := "murky"
	if counts["SPUN"] == level.panels.size():
		subtitle_key = "perfect"
	elif counts["TAMPERED"] > 0:
		subtitle_key = "tampered"
	elif counts["DAMNING"] >= 3:
		subtitle_key = "damning"
	elif counts["DAMNING"] > 0:
		subtitle_key = "mixed"
	last_capture_usec = Time.get_ticks_usec() - start
	return {"case_id": level.data.id, "case_number": level.data.case_number, "title": level.data.title, "required_spun": level.data.required_spun,
		"panels": records, "subtitle": level.data.subtitles[subtitle_key], "light_map": light_map, "light_values": values,
		"resolution": resolution, "burn_map": burn_map, "burn_values": burns, "hidden_threshold": evaluator.hidden_threshold, "visible_threshold": evaluator.visible_threshold,
		"ink_color": print_ink_color, "hidden_opacity": ink.hidden_opacity, "murky_opacity": ink.murky_opacity,
		"posterize_steps": posterize_steps, "color_boost": color_boost, "comic_brightness": comic_brightness, "edge_strength": edge_strength,
		"edge_threshold": edge_threshold, "halftone_spacing": halftone_spacing}

