extends VBoxContainer

@export var meter_script: Script = preload("res://scripts/ui/mood_meter.gd")
@export var lettering: Font = preload("res://Assets/fonts/Caveat.ttf")
@export var sticky_fill: Color = Color("f6e27a")
@export var sticky_ink: Color = Color("2b2a24")
@export var chip_fill: Color = Color("e7dff5")
@export var chip_ink: Color = Color("4a3a78")
@export var meter_height: float = 76.0

var reaction: Dictionary
var comments_column: VBoxContainer
var more_button: Button
var expanded: bool = false


func configure(data: Dictionary) -> void:
	reaction = data
	add_theme_constant_override("separation", 10)
	_editor_note()
	_mood()
	_comments()
	_refresh_comments()


## The editor's reply, on a sticky note like the one on the desk.
func _editor_note() -> void:
	var note := PanelContainer.new()
	note.add_theme_stylebox_override("panel", NewsroomTheme.box(sticky_fill, 3, Color.TRANSPARENT, 12))
	add_child(note)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	note.add_child(column)
	column.add_child(NewsroomTheme.label("ED. 6:02 AM", 11, sticky_ink.lightened(0.25)))
	var words := NewsroomTheme.label("“%s”" % reaction.verdict, 24, sticky_ink, true)
	words.add_theme_font_override("font", lettering)
	column.add_child(words)


func _mood() -> void:
	var mood_panel := PanelContainer.new()
	mood_panel.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.PAPER, 10, Color.TRANSPARENT, 14))
	add_child(mood_panel)
	var mood_column := VBoxContainer.new()
	mood_column.add_theme_constant_override("separation", 4)
	mood_panel.add_child(mood_column)
	var heading := HBoxContainer.new()
	mood_column.add_child(heading)
	var title := NewsroomTheme.label("PUBLIC MOOD", 13, NewsroomTheme.DARK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(NewsroomTheme.label("%s  %d/100" % [reaction.mood, reaction.score], 21, Color("a14156") if reaction.score < 40 else Color("326b61")))
	var meter := Control.new()
	meter.set_script(meter_script)
	meter.custom_minimum_size.y = meter_height
	mood_column.add_child(meter)
	meter.animate(reaction.score, reaction.band)
	mood_column.add_child(NewsroomTheme.label(reaction.summary, 15, NewsroomTheme.DARK, true))
	mood_column.add_child(NewsroomTheme.label("♥  %d likes     ◌  %d comments     ↗  %d shares" % [reaction.likes, reaction.comment_count, reaction.shares], 12, Color("535b63"), true))


func _comments() -> void:
	var comments_panel := PanelContainer.new()
	comments_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	comments_panel.add_theme_stylebox_override("panel", NewsroomTheme.box(NewsroomTheme.PAPER, 10, Color.TRANSPARENT, 14))
	add_child(comments_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	comments_panel.add_child(column)
	column.add_child(NewsroomTheme.label("THE CITY IS TALKING", 12, Color("6c6577")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	comments_column = VBoxContainer.new()
	comments_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comments_column.add_theme_constant_override("separation", 10)
	scroll.add_child(comments_column)
	more_button = NewsroomTheme.button("View all %d comments" % reaction.comment_count)
	more_button.add_theme_font_size_override("font_size", 13)
	more_button.pressed.connect(func():
		expanded = not expanded
		_refresh_comments()
	)
	column.add_child(more_button)


func _refresh_comments() -> void:
	for child in comments_column.get_children():
		comments_column.remove_child(child)
		child.queue_free()
	var count: int = reaction.comments.size() if expanded else mini(reaction.displayed_comments, reaction.comments.size())
	for i in count:
		var comment: Dictionary = reaction.comments[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		comments_column.add_child(row)
		var avatar := NewsroomTheme.label(String(comment.user).left(1).to_upper(), 16, NewsroomTheme.DARK)
		avatar.custom_minimum_size = Vector2(28, 28)
		avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar.add_theme_stylebox_override("normal", NewsroomTheme.box(Color.from_hsv(fmod(float(i) * 0.17, 1.0), 0.35, 0.82), 14, Color.TRANSPARENT, 4))
		row.add_child(avatar)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 1)
		row.add_child(text)
		var byline := HBoxContainer.new()
		byline.add_theme_constant_override("separation", 6)
		text.add_child(byline)
		byline.add_child(NewsroomTheme.label(comment.user, 12, Color("34414a")))
		if int(comment.panel) > 0:
			var chip := NewsroomTheme.label("re: panel %d" % comment.panel, 10, chip_ink)
			chip.add_theme_stylebox_override("normal", NewsroomTheme.box(chip_fill, 7, Color.TRANSPARENT, 3))
			byline.add_child(chip)
		text.add_child(NewsroomTheme.label(comment.text, 14, NewsroomTheme.DARK, true))
		text.add_child(NewsroomTheme.label("2m  /  %d likes  /  Reply" % comment.likes, 10, Color("7c7681")))
		if not String(comment.reply).is_empty():
			text.add_child(NewsroomTheme.label("↳ cape_club: " + comment.reply, 12, Color("516960"), true))
	more_button.text = "Show top comments" if expanded else "View all %d comments" % reaction.comment_count
	more_button.visible = reaction.comments.size() > reaction.displayed_comments
