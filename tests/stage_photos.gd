extends SceneTree
## Runtime regression for PNG content, POIs, layouts, tool switching and printing.
var failures := 0
const COUNTS := [1, 1, 1, 2, 2, 4, 6, 5]
const TOOLS := [
 ["Torch"], ["Torch"], ["Torch", "Paperweight"],
 ["Torch", "ReadingGlasses"], ["Torch", "MagnifyingGlass"],
 ["Torch", "Torch2"],
]
func _initialize() -> void:
 call_deferred("run")
func verify(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func run() -> void:
 var scene = load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 await physics_frame
 for index in 8:
  var source: LevelData = scene.campaign[index]
  scene.load_case(index)
  await physics_frame
  await process_frame
  verify(scene.level.panels.size() == COUNTS[index], "Photo count for stage %d" % (index+1))
  verify(get_nodes_in_group("evidence_panels").size() == COUNTS[index], "Active slots match stage")
  verify("CeilingLight" in source.available_tools, "Ceiling light available in every stage")
  var ceiling = scene.get_node("Tools/CeilingLight")
  ceiling.toggle()
  await physics_frame
  scene.get_node("LightEvaluator").refresh()
  for panel in scene.level.panels:
   for poi in panel.poi_nodes:
    verify(poi.data.current_light >= .55, "Ceiling illuminates the whole page")
  ceiling.toggle()
  var expected_pois := 0
  for panel in scene.level.panels:
   var data: PanelData = panel.data
   expected_pois += data.pois.size()
   if index < 6:
    verify(data.texture.resource_path.begins_with("res://Assets/evidence_assets/stages/"), "PNG source selected")
    var size: Vector2 = panel.photo.mesh.size
    var pixels := data.texture.get_size()
    verify(absf(size.x / size.y - pixels.x / pixels.y) < .0001, "Photo preserves aspect ratio")
   for poi in panel.poi_nodes:
    verify(poi.sample_points().size() == 9, "Hitbox has nine light samples")
    verify(poi.data.position_uv.x > 0 and poi.data.position_uv.x < 1 and poi.data.position_uv.y > 0 and poi.data.position_uv.y < 1, "Hitbox lies on photo")
    poi.data.current_light = 1.0 if poi.data.desired == POIData.Desired.VISIBLE else 0.0
   verify(Interpretation.evaluate(data, .3, .55) == &"SPUN", "Desired evidence produces SPUN even with a hidden hero")
   for poi in data.pois:
    if poi.desired == POIData.Desired.HIDDEN:
     poi.current_light = 1
     verify(Interpretation.evaluate(data, .3, .55) == &"DAMNING", "Exposing each hidden target is damning")
     poi.current_light = 0
   data.burned = true
   verify(Interpretation.evaluate(data, .3, .55) == &"TAMPERED", "Burning never hides evidence")
   data.burned = false
  verify(get_nodes_in_group("evidence_pois").size() == expected_pois, "No stale hitboxes after switching")
  if index < 6:
   verify(Array(source.available_tools) == ["CeilingLight"] + TOOLS[index], "Requested tool counts")
   verify(is_equal_approx(float(source.reaction_config.state_weights["SPUN"]) * COUNTS[index], 100), "Perfect score remains 100")
  for tool in scene.get_node("Tools").get_children():
   verify(tool.visible == (String(tool.name) in source.available_tools), "Unused tool hidden")
   if tool.has_node("PickBody"):
    verify((tool.get_node("PickBody").collision_layer != 0) == tool.visible, "Unused tool cannot intercept input")
  if index == 3 or index == 4:
   verify(source.photo_layouts[0].position.y == source.photo_layouts[1].position.y, "Side-by-side photos")
  if index == 5:
   verify(source.photo_layouts[0].position.y == source.photo_layouts[1].position.y and source.photo_layouts[2].position.y == source.photo_layouts[3].position.y, "Bank 2 by 2 grid")
  var snapshot: Dictionary = scene.get_node("ComicRenderer").capture(scene.level, scene.get_node("InkPreview"), scene.get_node("LightEvaluator"))
  verify(snapshot.panels.size() == COUNTS[index], "Printed comic includes all active photos")
  for i in snapshot.panels.size():
   verify(snapshot.panels[i].photo == scene.level.panels[i].data.texture, "Printing uses replacement textures")
  if index == 5:
   await scene.publish()
   verify(scene.result != null, "Four-photo PNG comic opens successfully")
   verify(scene.snapshot.panels.size() == 4, "Published bank page keeps all four photos")
   scene.back_to_desk()
   await process_frame
 var glasses = scene.get_node("Tools/ReadingGlasses")
 for child in glasses.get_children():
  if child is MeshInstance3D:
   verify(child.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Glasses do not cast visual shadows")
 verify(glasses.get_node("PickBody").collision_layer & 2 == 0, "Glasses do not block gameplay rays")
 var optic: Redirector = glasses.get_node("Redirector")
 glasses.show()
 optic.visual_light.show()
 optic.output = .7
 optic.refresh()
 var target := optic.origin - optic.visual_light.global_basis.z.normalized() * 4.0
 verify(optic.contribution_at(target) >= .55, "Redirected beam lights a subject four units away")
 print("Stage photo regression: ", failures, " failures")
 scene.queue_free()
 await process_frame
 quit(1 if failures else 0)
