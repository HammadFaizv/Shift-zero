class_name LevelManager
extends Node

@export var data: LevelData
@export var page: Node3D
@export var tools: Node3D
@export var interaction_manager: Node

var panels: Array[EvidencePanel] = []
var _slots: Array[EvidencePanel] = []
var _tool_defaults: Dictionary = {}
var _setting_defaults: Dictionary = {}


func _enter_tree() -> void:
	# Assign the level's content before the authored photo slots run _ready().
	var index := 0
	for child in page.get_children():
		if child is EvidencePanel:
			child.data = data.panels[index] if index < data.panels.size() else null
			if index < data.photo_layouts.size():
				child.configure_layout(data.photo_layouts[index])
			child.number = index + 1
			index += 1


func _ready() -> void:
	for child in page.get_children():
		if child is EvidencePanel:
			_slots.append(child)
	for tool in tools.get_children():
		if tool.has_node("PickBody"):
			_tool_defaults[String(tool.name)] = tool.get_node("PickBody").collision_layer
	load_data(data)


func load_data(source: LevelData) -> void:
	data = source.duplicate(true) as LevelData
	panels.clear()
	for i in _slots.size():
		if i < data.panels.size():
			if i < data.photo_layouts.size():
				_slots[i].configure_layout(data.photo_layouts[i])
			_slots[i].set_content(data.panels[i], i + 1)
			panels.append(_slots[i])
			data.panels[i] = _slots[i].data
		else:
			_slots[i].set_content(null, i + 1)
	_apply_tools()
	_apply_page()


func _apply_tools() -> void:
	for key in _setting_defaults:
		_set_tool_property(key, _setting_defaults[key])
	for key in data.tool_settings:
		var split := String(key).split(":", true, 1)
		if not _setting_defaults.has(key):
			_setting_defaults[key] = tools.get_node(split[0]).get(split[1])
		_set_tool_property(key, data.tool_settings[key])
	for tool in tools.get_children():
		if tool.name == &"CeilingLight":
			tool.visible = "CeilingLight" in data.available_tools
			tool.process_mode = Node.PROCESS_MODE_INHERIT if tool.visible else Node.PROCESS_MODE_DISABLED
			tool.get_node("PullCord/Handle").collision_layer = 8 if tool.visible else 0
			if tool.is_on != (tool.visible and data.ceiling_starts_on):
				tool.toggle()
			continue
		tool.visible = String(tool.name) in data.available_tools
		tool.process_mode = Node.PROCESS_MODE_INHERIT if tool.visible else Node.PROCESS_MODE_DISABLED
		tool.get_node("PickBody").collision_layer = _tool_defaults[String(tool.name)] if tool.visible else 0
		if tool.has_method("toggle") and not tool.is_on:
			tool.toggle()
		if data.tool_positions.has(String(tool.name)):
			tool.get_node("Draggable").move_to(data.tool_positions[String(tool.name)], interaction_manager.desk_bounds)
		tool.rotation.y = deg_to_rad(float(data.tool_yaws.get(String(tool.name), 0.0)))
		tool.force_update_transform()
		if tool.has_node("Focuser"):
			tool.get_node("Focuser").reset_heat()


func _set_tool_property(key: String, value: Variant) -> void:
	var split := key.split(":", true, 1)
	tools.get_node(split[0]).set(split[1], value)


func _apply_page() -> void:
	page.get_node("CaseHeader").text = "CASE FILE / " + data.title
	page.get_node("Time").text = data.incident.to_upper()
	page.get_node("Footer").text = "BEACON ARCHIVE / %02d - ORIGINAL PRINTS" % data.case_number
	page.get_parent().get_node("Props/EditorNote/Message").text = data.editor_note
	page.get_parent().get_node("Props/EditorNote2/Message").text = data.mechanic_hint
	interaction_manager.idle_hint = "Click and drag a tool  /  Q/E: aim" if not "CeilingLight" in data.available_tools else "L / red cord: ceiling light    |    Click and drag a tool"
	interaction_manager.deselect()


func counts() -> Dictionary:
	var result := {"SPUN": 0, "DAMNING": 0, "MURKY": 0, "TAMPERED": 0}
	for panel in panels:
		result[String(panel.state)] += 1
	return result


func passed() -> bool:
	return counts()["SPUN"] >= data.required_spun
