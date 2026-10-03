extends SceneTree
## Render the composed SVGs with Godot's actual SVG loader.
func _initialize() -> void:
	var specs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/evidence_compositions.json"))
	var cases: Array[String] = []
	for spec in specs:
		var case_id: String = spec.resource.get_slice("/", 2)
		if not case_id in cases:
			cases.append(case_id)
	var sheet := Image.create(768 * 3, 640 * cases.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("121c24"))
	var columns: Dictionary = {}
	for index in specs.size():
		var data: PanelData = load("res://" + specs[index].resource)
		var source := Image.new()
		var error := source.load_svg_from_string(FileAccess.get_file_as_string(data.texture.resource_path))
		if error != OK:
			push_error("Could not render " + data.texture.resource_path)
			quit(1)
			return
		var case_id: String = specs[index].resource.get_slice("/", 2)
		var column: int = columns.get(case_id, 0)
		sheet.blit_rect(source, Rect2i(0, 0, 768, 640), Vector2i(column * 768, cases.find(case_id) * 640))
		source.save_png("res://docs/previews/evidence-%s-%02d.png" % [case_id, column + 1])
		columns[case_id] = column + 1
	sheet.save_png("res://docs/previews/evidence-scenes.png")
	quit()
