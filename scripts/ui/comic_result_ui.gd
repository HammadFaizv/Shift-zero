extends Control

signal back_requested
signal next_requested

@export var photo_hold_seconds: float = 0.22
@export var print_seconds: float = 0.45
@export var balloon_seconds: float = 0.15
@export var panel_pause_seconds: float = 0.10
@export var outer_margin: int = 24
@export var column_gap: int = 20
@export var comic_minimum_width: float = 510.0
@export var reaction_minimum_width: float = 430.0
@export var photo_minimum_size: Vector2 = Vector2(205, 170)
@export var caption_minimum_height: float = 40.0
@export var paper_shader: Shader = preload("res://shaders/comic_paper.gdshader")
@export var photo_shader: Shader = preload("res://shaders/comic_photo.gdshader")
@export var reaction_script: Script = preload("res://scripts/ui/public_reaction_ui.gd")

var snapshot: Dictionary
var reaction: Dictionary
var panel_views: Array[Dictionary] = []
var replay_button: Button
var back_button: Button
var next_button: Button
var _reveal_tween: Tween


func configure(frozen: Dictionary, public_reaction: Dictionary) -> void:
	snapshot = frozen
	reaction = public_reaction
	var background := ColorRect.new()
	background.color = Color("090e14")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, outer_margin)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	column.add_child(header)
	var intro := VBoxContainer.new()
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(intro)
	intro.add_child(NewsroomTheme.label("6:02 AM  /  THE MORNING AFTER", 12, NewsroomTheme.GOLD))
	var ending: Dictionary = snapshot.get("ending", {})
	intro.add_child(NewsroomTheme.label(ending.get("headline", "YOUR COMIC IS LIVE"), 24 if not ending.is_empty() else 28, NewsroomTheme.PAPER, true))
	intro.add_child(NewsroomTheme.label("Editor: “%s”  /  Spin rating %d/%d" % [reaction.verdict, reaction.counts["SPUN"], snapshot.panels.size()], 14, NewsroomTheme.PAPER, true))
	if not ending.is_empty():
		intro.add_child(NewsroomTheme.label(ending.message, 14, NewsroomTheme.GOLD, true))
	var actions := VBoxContainer.new()
	var buttons := HBoxContainer.new()
	actions.add_child(buttons)
	header.add_child(actions)
	replay_button = NewsroomTheme.button("Replay printing")
	replay_button.pressed.connect(replay)
	buttons.add_child(replay_button)
	back_button = NewsroomTheme.button("BACK TO THE DESK", true)
	back_button.pressed.connect(func(): back_requested.emit())
	buttons.add_child(back_button)
	next_button = NewsroomTheme.button("START AGAIN" if not ending.is_empty() else "NEXT EDITION" if snapshot.get("campaign_complete", false) else "NEXT CASE" if snapshot.get("next_available", false) else "LAST EDITION")
	next_button.disabled = ending.is_empty() and not snapshot.get("next_available", false)
	next_button.pressed.connect(func(): next_requested.emit())
	actions.add_child(next_button)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", column_gap)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(columns)
	var comic_scroll := ScrollContainer.new()
	comic_scroll.custom_minimum_size.x = comic_minimum_width
	comic_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comic_scroll.size_flags_stretch_ratio = 1.0
	comic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(comic_scroll)
	_build_comic(comic_scroll)
	var reaction_scroll := ScrollContainer.new()
	reaction_scroll.custom_minimum_size.x = reaction_minimum_width
	reaction_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reaction_scroll.size_flags_stretch_ratio = 1.05
	reaction_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(reaction_scroll)
	var feed := VBoxContainer.new()
	feed.set_script(reaction_script)
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reaction_scroll.add_child(feed)
	feed.configure(reaction)
	replay()


func _build_comic(parent: Control) -> void:
	var post := VBoxContainer.new()
	post.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	post.add_theme_constant_override("separation", 0)
	parent.add_child(post)
	var account := PanelContainer.new()
	account.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.PAPER, 8, Color.TRANSPARENT, 12))
	post.add_child(account)
	account.add_child(NewsroomTheme.label("BEACON SOCIAL   /   @thedailybeacon\nDaily Beacon Comics · First City", 13, NewsroomTheme.DARK))
	var paper := PanelContainer.new()
	var paper_material := ShaderMaterial.new()
	paper_material.shader = paper_shader
	paper.material = paper_material
	paper.add_theme_stylebox_override("panel", NewsroomTheme.box(Color("ffd84d"), 0, Color.TRANSPARENT, 14))
	post.add_child(paper)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	paper.add_child(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var badge := NewsroomTheme.label("No.\n%d" % snapshot.get("case_number", 1), 17, NewsroomTheme.DARK)
	badge.custom_minimum_size.x = 44
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("91d6bf"), 24, NewsroomTheme.DARK, 4))
	title_row.add_child(badge)
	var title := NewsroomTheme.label("CAPTAIN HALCYON", 29, Color("e45263"))
	title.add_theme_color_override("font_outline_color", Color("2a1f5c"))
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var subtitle := NewsroomTheme.label(snapshot.subtitle, 16, Color("fff4d6"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("7652ba"), 12, NewsroomTheme.DARK, 4))
	content.add_child(subtitle)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for panel in snapshot.panels:
		_build_panel(grid, panel)
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.PAPER, 8, Color.TRANSPARENT, 12))
	post.add_child(footer)
	var footer_column := VBoxContainer.new()
	footer_column.add_child(NewsroomTheme.label("♥   ◌   ↗      %d likes" % reaction.likes, 17, Color("a34158")))
	footer_column.add_child(NewsroomTheme.label("@thedailybeacon  " + reaction.post_caption, 12, NewsroomTheme.DARK, true))
	footer.add_child(footer_column)


func _build_panel(parent: Control, panel: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", NewsroomTheme.box(Color("fff4d6"), 10, Color("2a1f5c"), 5))
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var aspect := AspectRatioContainer.new()
	var photo_size: Vector2 = panel.photo.get_size()
	aspect.ratio = photo_size.x / photo_size.y
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.custom_minimum_size = photo_minimum_size
	column.add_child(aspect)
	var frame := Control.new()
	frame.clip_contents = true
	aspect.add_child(frame)
	var photo := TextureRect.new()
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	photo.texture = panel.photo
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(photo)
	var material := ShaderMaterial.new()
	material.shader = photo_shader
	material.set_shader_parameter("light_map", snapshot.light_map)
	material.set_shader_parameter("burn_map", snapshot.burn_map)
	material.set_shader_parameter("light_uv_rect", panel.uv_rect)
	for key in ["hidden_threshold", "visible_threshold", "hidden_opacity", "murky_opacity", "posterize_steps", "color_boost", "comic_brightness", "edge_strength", "edge_threshold", "halftone_spacing", "ink_color"]:
		material.set_shader_parameter(key, snapshot[key])
	photo.material = material
	var stage := NewsroomTheme.label("YOUR PHOTO", 10, Color("fff4d6"))
	stage.position = Vector2(5, 5)
	stage.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("2a1f5c"), 3, Color.TRANSPARENT, 3))
	frame.add_child(stage)
	var balloon := PanelContainer.new()
	balloon.anchor_left = 0.10
	balloon.anchor_right = 0.92
	balloon.anchor_top = 0.18
	balloon.anchor_bottom = 0.18
	balloon.add_theme_stylebox_override("panel", NewsroomTheme.box(Color("fffdf0"), 18, Color("2a1f5c"), 6))
	frame.add_child(balloon)
	var speech := NewsroomTheme.label(panel.balloon, 13, Color("2a1f5c"), true)
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balloon.add_child(speech)
	balloon.visible = not String(panel.balloon).is_empty()
	var sfx := NewsroomTheme.label(panel.sfx, 19, Color("ffea70"))
	sfx.anchor_left = 0.05
	sfx.anchor_right = 0.95
	sfx.anchor_top = 0.82
	sfx.anchor_bottom = 0.82
	sfx.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sfx.rotation = -0.09
	sfx.add_theme_color_override("font_outline_color", Color("2a1f5c"))
	sfx.add_theme_constant_override("outline_size", 5)
	frame.add_child(sfx)
	sfx.visible = not String(panel.sfx).is_empty()
	var caption := NewsroomTheme.label(panel.caption, 12, Color("2a1f5c"), true)
	caption.custom_minimum_size.y = caption_minimum_height
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	panel_views.append({"material": material, "stage": stage, "balloon": balloon, "sfx": sfx})


func replay() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
	for view in panel_views:
		view.material.set_shader_parameter("print_mix", 0.0)
		view.stage.text = "YOUR PHOTO"
		view.balloon.modulate.a = 0.0
		view.sfx.modulate.a = 0.0
	_reveal_tween = create_tween()
	for view in panel_views:
		_reveal_tween.tween_interval(photo_hold_seconds)
		var material: ShaderMaterial = view.material
		var original: bool = snapshot.get("ending", {}).get("choice", &"") == &"original"
		_reveal_tween.tween_method(func(value: float): material.set_shader_parameter("print_mix", value), 0.0, 0.0 if original else 1.0, print_seconds)
		_reveal_tween.tween_callback(func(): view.stage.text = "ORIGINAL EVIDENCE" if original else "PRINTED COMIC")
		_reveal_tween.tween_property(view.balloon, "modulate:a", 1.0, balloon_seconds)
		_reveal_tween.parallel().tween_property(view.sfx, "modulate:a", 1.0, balloon_seconds)
		_reveal_tween.tween_interval(panel_pause_seconds)
