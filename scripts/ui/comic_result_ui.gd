extends Control

signal back_requested
signal next_requested

@export var photo_hold_seconds: float = 0.22
@export var print_seconds: float = 0.45
@export var balloon_seconds: float = 0.15
@export var panel_pause_seconds: float = 0.10
@export var outer_margin: int = 16
@export var column_gap: int = 14
@export var comic_stretch: float = 0.88
@export var wide_stretch: float = 1.3
@export var reaction_stretch: float = 1.0
@export var paper_shader: Shader = preload("res://shaders/comic_paper.gdshader")
@export var photo_shader: Shader = preload("res://shaders/comic_photo.gdshader")
@export var reaction_script: Script = preload("res://scripts/ui/public_reaction_ui.gd")
@export var grid_script: Script = preload("res://scripts/ui/comic_grid.gd")
@export var panel_script: Script = preload("res://scripts/ui/comic_panel_view.gd")
@export var lettering: Font = preload("res://Assets/fonts/Caveat.ttf")
@export var page_color: Color = Color("ffd84d")
@export var ink: Color = Color("2a1f5c")

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
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	_build_header(column)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", column_gap)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(columns)
	_build_comic(columns)
	var feed := VBoxContainer.new()
	feed.set_script(reaction_script)
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed.size_flags_stretch_ratio = reaction_stretch
	columns.add_child(feed)
	feed.configure(reaction)
	replay()


func _build_header(parent: Control) -> void:
	var ending: Dictionary = snapshot.get("ending", {})
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	parent.add_child(header)
	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", 0)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(intro)
	intro.add_child(NewsroomTheme.label("6:02 AM  /  THE MORNING AFTER", 12, NewsroomTheme.GOLD))
	intro.add_child(NewsroomTheme.label(ending.get("headline", "YOUR COMIC IS LIVE"), 26, NewsroomTheme.PAPER, true))
	if not ending.is_empty():
		intro.add_child(NewsroomTheme.label(ending.message, 14, NewsroomTheme.GOLD, true))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	header.add_child(buttons)
	replay_button = NewsroomTheme.button("Replay printing")
	replay_button.pressed.connect(replay)
	buttons.add_child(replay_button)
	back_button = NewsroomTheme.button("BACK TO THE DESK")
	back_button.pressed.connect(func(): back_requested.emit())
	buttons.add_child(back_button)
	next_button = NewsroomTheme.button("START AGAIN" if not ending.is_empty() else "NEXT EDITION" if snapshot.get("campaign_complete", false) else "NEXT CASE" if snapshot.get("next_available", false) else "LAST EDITION", true)
	next_button.disabled = ending.is_empty() and not snapshot.get("next_available", false)
	next_button.pressed.connect(func(): next_requested.emit())
	buttons.add_child(next_button)


## A social post: account row, the yellow comic page, then the like bar.
func _build_comic(parent: Control) -> void:
	var post := PanelContainer.new()
	post.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	post.size_flags_stretch_ratio = wide_stretch if snapshot.panels.size() == 2 else comic_stretch
	post.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.PAPER, 10, Color.TRANSPARENT, 0))
	parent.add_child(post)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	post.add_child(stack)
	var account := HBoxContainer.new()
	account.add_theme_constant_override("separation", 8)
	stack.add_child(_padded(account, 8, 6))
	var avatar := NewsroomTheme.label("DB", 12, Color.WHITE)
	avatar.custom_minimum_size = Vector2(28, 28)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("e45263"), 14, Color.TRANSPARENT, 2))
	account.add_child(avatar)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -2)
	account.add_child(names)
	names.add_child(NewsroomTheme.label("thedailybeacon", 12, NewsroomTheme.DARK))
	names.add_child(NewsroomTheme.label("Daily Beacon Comics · First City", 10, Color("6b6f76")))
	var paper := PanelContainer.new()
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper_material := ShaderMaterial.new()
	paper_material.shader = paper_shader
	paper.material = paper_material
	paper.add_theme_stylebox_override("panel", NewsroomTheme.box(page_color, 0, Color.TRANSPARENT, 10))
	stack.add_child(paper)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	paper.add_child(content)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	content.add_child(title_row)
	var badge := NewsroomTheme.label("No.%d" % snapshot.get("case_number", 1), 15, ink)
	badge.custom_minimum_size = Vector2(54, 40)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("91d6bf"), 20, ink, 3))
	title_row.add_child(badge)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 1)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	var title := NewsroomTheme.label("CAPTAIN HALCYON", 27, Color("e45263"))
	title.add_theme_color_override("font_outline_color", ink)
	title.add_theme_constant_override("outline_size", 6)
	titles.add_child(title)
	var subtitle := NewsroomTheme.label(snapshot.subtitle, 12, Color("fff4d6"))
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	subtitle.add_theme_stylebox_override("normal", NewsroomTheme.box(Color("7652ba"), 10, ink, 3))
	titles.add_child(subtitle)
	var grid := Container.new()
	grid.set_script(grid_script)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	var original: bool = snapshot.get("ending", {}).get("choice", &"") == &"original"
	for panel in snapshot.panels:
		var view: ComicPanelView = panel_script.new()
		grid.add_child(view)
		view.setup(panel, snapshot, photo_shader, original)
		panel_views.append({"view": view, "material": view.photo_material, "stage": view.tag, "balloon": view.balloon, "sfx": view.burst, "narration": view.narration})
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 0)
	stack.add_child(_padded(footer, 8, 5))
	footer.add_child(NewsroomTheme.label("♥   ◌   ↗      %d likes" % reaction.likes, 14, Color("a34158")))
	footer.add_child(NewsroomTheme.label("@thedailybeacon  " + reaction.post_caption, 11, NewsroomTheme.DARK, true))


func _padded(content: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	margin.add_child(content)
	return margin


func replay() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
	for view in panel_views:
		view.material.set_shader_parameter("print_mix", 0.0)
		view.view.set_revealed(0.0)
	_reveal_tween = create_tween()
	var original: bool = snapshot.get("ending", {}).get("choice", &"") == &"original"
	for view in panel_views:
		_reveal_tween.tween_interval(photo_hold_seconds)
		var material: ShaderMaterial = view.material
		_reveal_tween.tween_callback(Sfx.swoosh)
		_reveal_tween.tween_method(func(value: float): material.set_shader_parameter("print_mix", value), 0.0, 0.0 if original else 1.0, print_seconds)
		_reveal_tween.tween_callback(func():
			view.view.pop_in(balloon_seconds)
			if view.balloon.visible or view.narration.visible:
				Sfx.pop())
		_reveal_tween.tween_interval(balloon_seconds + panel_pause_seconds)
