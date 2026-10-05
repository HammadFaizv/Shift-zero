extends Control
signal retry_requested
signal replay_requested

@export var reveal_seconds: float = 1.0
@export var panel_gap: float = 10.0
@export var margin: float = 24.0
@export var paper_color := Color("eee4ce")
const GOOD := [preload("res://Assets/Endings/ending1A.png"), preload("res://Assets/Endings/ending1B.png"), preload("res://Assets/Endings/ending1C.png"), preload("res://Assets/Endings/ending1D.png"), preload("res://Assets/Endings/ending1E.png"), preload("res://Assets/Endings/ending1F.png")]
const BAD := [preload("res://Assets/Endings/ending2A.png"), preload("res://Assets/Endings/ending2B.png")]
var good := false
var revealed := 0
var page_index := 0
var complete := false
var images: Array[TextureRect] = []
var sheet: Control
var timer: Timer
var next_button: Button
var skip_button: Button
var finish_button: Button
var status: Label
var thanks: Label

func configure(is_good: bool, mood: String, score: int) -> void:
	good = is_good
	var background := ColorRect.new()
	background.color = Color("090e14")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var padding := MarginContainer.new()
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, int(margin))
	add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	padding.add_child(column)
	column.add_child(NewsroomTheme.label("THE RIGHT ANGLE / " + ("FINAL EDITION" if good else "A NEW NIGHT DESK"), 22, NewsroomTheme.GOLD))
	column.add_child(NewsroomTheme.label("PUBLIC MOOD: %s / %d" % [mood, score], 14, NewsroomTheme.PAPER))
	sheet = Control.new()
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.clip_contents = true
	column.add_child(sheet)
	sheet.draw.connect(func(): sheet.draw_style_box(NewsroomTheme.box(paper_color, 4, NewsroomTheme.GOLD, 0), Rect2(Vector2.ZERO, sheet.size)))
	sheet.resized.connect(_layout)
	for texture in GOOD if good else BAD:
		var image := TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.visible = false
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sheet.add_child(image)
		images.append(image)
	status = NewsroomTheme.label("", 13, NewsroomTheme.MUTED)
	column.add_child(status)
	thanks = NewsroomTheme.label("Thank you for playing The Right Angle." if good else "A new editor takes the desk. Your stage and tools are still here.", 19, NewsroomTheme.PAPER, true)
	thanks.hide()
	column.add_child(thanks)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	next_button = NewsroomTheme.button("NEXT PANEL", true)
	next_button.pressed.connect(advance)
	buttons.add_child(next_button)
	skip_button = NewsroomTheme.button("SKIP")
	skip_button.pressed.connect(skip)
	buttons.add_child(skip_button)
	finish_button = NewsroomTheme.button("REPLAY GAME" if good else "REPLAY STAGE", true)
	finish_button.hide()
	finish_button.pressed.connect(func():
		if good: replay_requested.emit()
		else: retry_requested.emit())
	buttons.add_child(finish_button)
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = reveal_seconds
	timer.timeout.connect(advance)
	add_child(timer)
	advance()
	_layout.call_deferred()

func advance() -> void:
	if complete:
		return
	timer.stop()
	if good and revealed == 5:
		page_index = 1
		for image in images: image.hide()
	images[revealed].show()
	revealed += 1
	_layout()
	status.text = "PAGE %d / PANEL %d OF %d" % [page_index + 1, revealed, images.size()]
	if revealed == images.size():
		complete = true
		next_button.hide()
		skip_button.hide()
		thanks.show()
		finish_button.show()
	else:
		timer.start()

func skip() -> void:
	timer.stop()
	while not complete: advance()

func _layout() -> void:
	if images.is_empty() or sheet.size.y <= 0:
		return
	sheet.queue_redraw()
	# Fit a portrait comic page; preserve each supplied image inside its panel.
	var height := sheet.size.y - panel_gap * 2
	var width := minf(sheet.size.x - panel_gap * 2, height * (0.80 if good else 1.35))
	var origin := Vector2((sheet.size.x - width) / 2, panel_gap)
	if good and page_index == 0:
		var half := (width - panel_gap) / 2
		var row := (height - panel_gap * 2) / 3
		var rects := [Rect2(0, 0, half, row), Rect2(0, row + panel_gap, half, row), Rect2(half + panel_gap, 0, half, row * 2 + panel_gap), Rect2(0, (row + panel_gap) * 2, half, row), Rect2(half + panel_gap, (row + panel_gap) * 2, half, row)]
		for i in 5:
			images[i].position = origin + rects[i].position
			images[i].size = rects[i].size
	elif good:
		images[5].position = origin
		images[5].size = Vector2(width, height)
	else:
		var half := (width - panel_gap) / 2
		for i in 2:
			images[i].position = origin + Vector2(i * (half + panel_gap), 0)
			images[i].size = Vector2(half, height)
