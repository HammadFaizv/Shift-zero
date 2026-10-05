extends Node3D

signal published(snapshot: Dictionary)
signal returned_to_desk

@export var results_scene: PackedScene = preload("res://scenes/ui/comic_result.tscn")
@export var restart_button_rect: Rect2 = Rect2(-220, 24, 194, 40)
@export var ending_scene: PackedScene = preload("res://scenes/ui/ending_comic.tscn")
@export var divided_band: int = 2
@export var passing_band: int = 3
## The first stages are forgiving: a sour reception there only offers a retry. Stage number (1-based) from which a bad ending can happen.
@export var bad_ending_from_stage: int = 4
@export var campaign: Array[LevelData] = [preload("res://data/levels/hero/level.tres"), preload("res://data/levels/fans/level.tres"), preload("res://data/levels/lake/level.tres"), preload("res://data/levels/peace/level.tres"), preload("res://data/levels/rescue/level.tres"), preload("res://data/levels/robbery/level.tres"), preload("res://data/levels/protest/level.tres"), preload("res://data/levels/factory/level.tres")]

@onready var level: LevelManager = $LevelManager
@onready var story: PanelContainer = $Overlay/Frame/StoryStatus
@onready var rings: Control = $Overlay/Frame/TargetRings
@onready var debug_panel: PanelContainer = $Overlay/Frame/LightDebugPanel

var result: Control
var snapshot: Dictionary = {}
var publishing: bool = false
var case_index: int = 0
var _frozen_modes: Dictionary = {}
var ending: Control
var is_proof := false
var cleared_cases: Dictionary = {}
var last_reaction: Dictionary = {}
## Web builds render the 3D desk at no more than this many pixels tall; the UI stays sharp.
const WEB_RENDER_HEIGHT := 810.0
const WEB_MIN_RENDER_SCALE := 0.5


func _ready() -> void:
	if OS.has_feature("web"):
		get_window().size_changed.connect(_fit_web_render_scale)
		_fit_web_render_scale()
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


func _fit_web_render_scale() -> void:
	var height := float(get_window().size.y)
	if height > 0.0:
		get_viewport().scaling_3d_scale = clampf(WEB_RENDER_HEIGHT / height, WEB_MIN_RENDER_SCALE, 1.0)


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
	$Overlay/Frame.hide()
	result = results_scene.instantiate()
	$ResultsLayer.add_child(result)
	result.back_requested.connect(back_to_desk)
	result.confirm_requested.connect(confirm_publish)
	snapshot["next_available"] = false
	snapshot["campaign_complete"] = case_index == campaign.size() - 1
	is_proof = true
	result.configure(snapshot, {}, true)
	publishing = false


func confirm_publish() -> void:
	if not is_proof or result == null or ending != null:
		return
	is_proof = false
	last_reaction = ReactionGenerator.generate(snapshot, level.data.comment_templates, level.data.reaction_config)
	cleared_cases.erase(case_index)
	if last_reaction.band >= passing_band:
		cleared_cases[case_index] = last_reaction.score
	snapshot["next_available"] = last_reaction.band >= passing_band
	result.queue_free()
	result = results_scene.instantiate()
	$ResultsLayer.add_child(result)
	result.back_requested.connect(back_to_desk)
	result.next_requested.connect(next_case)
	result.configure(snapshot, last_reaction)
	Sfx.music(&"result")
	published.emit(snapshot)
	if last_reaction.band < divided_band and case_index + 1 >= bad_ending_from_stage:
		$DeskStage/Props/Nameplate.change_editor()
		_show_ending(false)
	elif case_index == campaign.size() - 1 and cleared_cases.size() == campaign.size():
		_show_ending(true)


func _show_ending(good: bool) -> void:
	ending = ending_scene.instantiate()
	$ResultsLayer.add_child(ending)
	ending.retry_requested.connect(retry_stage)
	ending.replay_requested.connect(replay_campaign)
	ending.configure(good, last_reaction.mood, last_reaction.score)


func retry_stage() -> void:
	# Keep the failed stage's exact tool positions, burns and earlier clears.
	if ending != null:
		ending.queue_free()
		ending = null
	back_to_desk()


func replay_campaign() -> void:
	if ending != null:
		ending.queue_free()
		ending = null
	cleared_cases.clear()
	load_case(0)


func _freeze_desk() -> void:
	$InteractionManager.deselect()
	for node in [$InteractionManager, $Tools, $DeskStage, $LightEvaluator, $InkPreview]:
		_frozen_modes[node] = node.process_mode
		node.process_mode = Node.PROCESS_MODE_DISABLED


func back_to_desk() -> void:
	if result == null or ending != null:
		return
	is_proof = false
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
	if ending != null:
		ending.queue_free()
		ending = null
	is_proof = false
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
	if result == null or is_proof or ending != null or not snapshot.get("next_available", false):
		return
	Sfx.swoosh()
	if case_index == campaign.size() - 1:
		if cleared_cases.size() == campaign.size(): _show_ending(true)
		else: back_to_desk()
	else:
		load_case(case_index + 1)
