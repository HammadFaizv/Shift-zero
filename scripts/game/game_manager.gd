extends Node3D

signal published(snapshot: Dictionary)
signal returned_to_desk

@export var results_scene: PackedScene = preload("res://scenes/ui/comic_result.tscn")
@export var restart_button_rect: Rect2 = Rect2(-220, 24, 194, 40)
@export var campaign: Array[LevelData] = [preload("res://data/levels/hero/level.tres"), preload("res://data/levels/fans/level.tres"), preload("res://data/levels/lake/level.tres"), preload("res://data/levels/peace/level.tres"), preload("res://data/levels/rescue/level.tres"), preload("res://data/levels/robbery/level.tres"), preload("res://data/levels/greatest/level.tres")]

@onready var level: LevelManager = $LevelManager
@onready var story: PanelContainer = $Overlay/Frame/StoryStatus
@onready var rings: Control = $Overlay/Frame/TargetRings
@onready var debug_panel: PanelContainer = $Overlay/Frame/LightDebugPanel

var result: Control
var snapshot: Dictionary = {}
var publishing: bool = false
var case_index: int = 0
var _frozen_modes: Dictionary = {}


func _ready() -> void:
	story.bind(level)
	story.publish_requested.connect(publish)
	story.rings_toggled.connect(rings.set_enabled)
	rings.set_enabled(level.data.target_rings_default)
	debug_panel.hide()
	var restart := NewsroomTheme.button("RESTART CASE")
	restart.anchor_left = 1.0
	restart.anchor_right = 1.0
	restart.offset_left = restart_button_rect.position.x
	restart.offset_right = restart_button_rect.end.x
	restart.offset_top = restart_button_rect.position.y
	restart.offset_bottom = restart_button_rect.end.y
	restart.tooltip_text = "Reset this case's tool positions and scorch marks."
	restart.pressed.connect(func():
		Sfx.swoosh()
		load_case(case_index))
	$Overlay/Frame.add_child(restart)
	$LightEvaluator.refresh()
	Sfx.music(&"desk")


func _unhandled_input(event: InputEvent) -> void:
	if result != null or publishing:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
		debug_panel.visible = not debug_panel.visible
		story.visible = not debug_panel.visible
		get_viewport().set_input_as_handled()


func publish() -> void:
	if publishing or result != null:
		return
	publishing = true
	Sfx.swoosh()
	_freeze_desk()
	# Let the physics server commit the last drag. KEEP_ACTIVE preserves shadows.
	await get_tree().physics_frame
	await get_tree().physics_frame
	$LightEvaluator.refresh()
	snapshot = $ComicRenderer.capture(level, $InkPreview, $LightEvaluator)
	var reaction := ReactionGenerator.generate(snapshot, level.data.comment_templates, level.data.reaction_config)
	$Overlay/Frame.hide()
	result = results_scene.instantiate()
	$ResultsLayer.add_child(result)
	result.back_requested.connect(back_to_desk)
	result.next_requested.connect(next_case)
	# A bad edition has consequences in the feed, but never blocks the story.
	snapshot["next_available"] = true
	snapshot["campaign_complete"] = case_index == campaign.size() - 1
	result.configure(snapshot, reaction)
	publishing = false
	Sfx.music(&"result")
	published.emit(snapshot)


func _freeze_desk() -> void:
	$InteractionManager.deselect()
	for node in [$InteractionManager, $Tools, $DeskStage, $LightEvaluator, $InkPreview]:
		_frozen_modes[node] = node.process_mode
		node.process_mode = Node.PROCESS_MODE_DISABLED


func back_to_desk() -> void:
	if result == null:
		return
	result.queue_free()
	result = null
	_restore_desk()
	$Overlay/Frame.show()
	$LightEvaluator.refresh()
	Sfx.music(&"desk")
	Sfx.swoosh()
	returned_to_desk.emit()


func _restore_desk() -> void:
	for node in _frozen_modes:
		node.process_mode = _frozen_modes[node]
	_frozen_modes.clear()


func load_case(index: int) -> void:
	if publishing or index < 0 or index >= campaign.size():
		return
	if result != null:
		result.queue_free()
		result = null
	_restore_desk()
	$InteractionManager.deselect()
	Sfx.music(&"desk")
	case_index = index
	level.load_data(campaign[index])
	rings.refresh_sources()
	debug_panel.refresh_sources()
	story.bind(level)
	rings.set_enabled(level.data.target_rings_default)
	story.show()
	debug_panel.hide()
	$Overlay/Frame.show()
	$LightEvaluator.refresh()


func next_case() -> void:
	if result == null:
		return
	Sfx.swoosh()
	load_case((case_index + 1) % campaign.size())
