extends Node
## The desk remains visible behind the translucent menu, with input suspended.
@export var card_width: float = 860.0
@export var card_height: float = 620.0
@export var screen_margin: float = 32.0
@export var backdrop_color := Color(0.025, 0.035, 0.045, 0.72)
@export var card_color := Color(0.06, 0.09, 0.11, 0.94)
@export var illustration_height: float = 265.0
@export var menu_width: float = 520.0
@export var menu_height: float = 540.0
@export var title_size: int = 46

const LESSONS := [
	["MOVE & AIM THE LIGHT", "Click and drag the torch beside the photograph. Select it, then use Q/E, the mouse wheel, or the gold handle to aim. Space or a double-click switches it on and off.", preload("res://Assets/ui/tutorial/01_light.svg")],
	["PUT THE SUBJECT IN THE RIGHT LIGHT", "Light the subjects marked with a sun. Details marked with an eye should be in shadow. Purple areas print as darkness. Later, move a paperweight between the light and a detail to cast a shadow.", preload("res://Assets/ui/tutorial/02_shadow.svg")],
	["PUBLISH YOUR COMIC", "Click PUBLISH THIS EDITION to inspect the comic proof. Choose PUBLISH THIS COMIC to post it, or KEEP EDITING to adjust the light before it reaches the public.", preload("res://Assets/ui/tutorial/03_publish.svg")],
	["SEE WHAT THE CITY THINKS", "Aim for CHARMED or ADORING to clear each assignment. DIVIDED means another pass. If public opinion turns sour, things might not end up well for you. Clear every assignment to see the final edition.", preload("res://Assets/ui/tutorial/04_opinion.svg")],
]

@onready var desk: Node3D = $Desk
var modal: Control
var card: PanelContainer
var column: VBoxContainer
var illustration: TextureRect
var page := "menu"
var lesson := 0
var started := false
var overlay_was_visible := true
var results_were_visible := true

func _ready() -> void:
	PlayerSettings.load_preferences()
	PlayerSettings.apply_audio()
	var menu_button := NewsroomTheme.button("MENU")
	menu_button.name = "MenuButton"
	menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_button.offset_left = -330
	menu_button.offset_right = -236
	menu_button.offset_top = 24
	menu_button.offset_bottom = 64
	menu_button.pressed.connect(show_menu)
	desk.get_node("Overlay/Frame").add_child(menu_button)
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$MenuLayer.add_child(modal)
	var shade := ColorRect.new()
	shade.color = backdrop_color
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", NewsroomTheme.box(card_color, 16, Color("596555"), 28))
	modal.add_child(card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	get_viewport().size_changed.connect(_layout)
	show_menu()
	_layout()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var height := card_height if page == "tutorial" else (580.0 if page == "settings" else menu_height)
	var width := menu_width if page == "menu" else card_width
	card.size = Vector2(minf(width, view.x - screen_margin * 2), minf(height, view.y - screen_margin * 2))
	card.position = (view - card.size) * 0.5
	if is_instance_valid(illustration):
		illustration.custom_minimum_size.y = minf(illustration_height, view.y * 0.36)

func _clear(next_page: String) -> void:
	page = next_page
	illustration = null
	card.modulate.a = 1.0
	column.add_theme_constant_override("separation", 16)
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	_layout.call_deferred()

func _title(eyebrow: String, title: String, description: String) -> void:
	column.add_child(NewsroomTheme.label(eyebrow, 13, NewsroomTheme.GOLD))
	column.add_child(NewsroomTheme.label(title, 30, NewsroomTheme.PAPER, true))
	column.add_child(NewsroomTheme.label(description, 17, NewsroomTheme.PAPER, true))

func _button(text: String, action: Callable, primary: bool = false) -> Button:
	var button := NewsroomTheme.button(text, primary)
	button.pressed.connect(action)
	column.add_child(button)
	return button

func show_menu() -> void:
	if not modal.visible:
		overlay_was_visible = desk.get_node("Overlay/Frame").visible
		results_were_visible = desk.get_node("ResultsLayer").visible
	desk.get_node("InteractionManager").deselect()
	desk.process_mode = Node.PROCESS_MODE_DISABLED
	desk.get_node("Overlay/Frame").hide()
	desk.get_node("ResultsLayer").hide()
	modal.show()
	_clear("menu")
	_build_menu()

func _build_menu() -> void:
	column.add_theme_constant_override("separation", 10)
	var emblem := SunEmblem.new()
	emblem.custom_minimum_size = Vector2(120, 120)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(emblem)
	var eyebrow := NewsroomTheme.label("THE DAILY BEACON   /   NIGHT DESK", 13, NewsroomTheme.GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var title := NewsroomTheme.label("THE RIGHT ANGLE", title_size, NewsroomTheme.PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("0a0f14"))
	title.add_theme_constant_override("outline_size", 6)
	column.add_child(title)
	var rule := ColorRect.new()
	rule.color = NewsroomTheme.GOLD
	rule.custom_minimum_size = Vector2(90, 3)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(rule)
	var tagline := NewsroomTheme.label("Your desk. Your light. Tomorrow's front page.", 30, NewsroomTheme.PAPER, true)
	tagline.add_theme_font_override("font", preload("res://Assets/fonts/Caveat.ttf"))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	var brief := NewsroomTheme.label("Keep Halcyon in the right light.", 15, NewsroomTheme.MUTED, true)
	brief.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(brief)
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	column.add_child(gap)
	var main_button := _button("RESUME" if started else "PLAY", resume_game if started else func(): show_tutorial(0), true)
	main_button.custom_minimum_size.y = 58
	main_button.add_theme_font_size_override("font_size", 20)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for entry in [["SETTINGS", show_settings], ["HOW TO PLAY", func(): show_tutorial(0)]]:
		var option := NewsroomTheme.button(entry[0])
		option.custom_minimum_size.y = 46
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.pressed.connect(entry[1])
		row.add_child(option)
	var footer := NewsroomTheme.label("Mouse + keyboard   /   Eight assignments   /   M mutes sound", 12, NewsroomTheme.MUTED, true)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)
	# Settle the card in rather than snapping.
	card.modulate.a = 0.0
	create_tween().tween_property(card, "modulate:a", 1.0, 0.35)


## Halcyon's chest emblem: a slowly turning ring of sun rays round a gold disc.
class SunEmblem extends Control:
	var spin: float = 0.0

	func _process(delta: float) -> void:
		spin += delta * 0.25
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r * 0.95, Color(0.89, 0.72, 0.36, 0.12))
		for i in 16:
			var angle := spin + TAU * i / 16.0
			var long := i % 2 == 0
			var from := c + Vector2.from_angle(angle) * r * 0.62
			var to := c + Vector2.from_angle(angle) * r * (0.95 if long else 0.8)
			draw_line(from, to, Color("e4b85c"), 4.0 if long else 3.0, true)
		draw_circle(c, r * 0.5, Color("e4b85c"))
		draw_circle(c, r * 0.5, Color("10171d"), false, 3.0, true)
		draw_circle(c, r * 0.3, Color("f08a24"))
		draw_arc(c, r * 0.3, 0.0, TAU, 32, Color("10171d"), 3.0, true)
		draw_line(c + Vector2(-r * 0.15, 0), c + Vector2(r * 0.15, 0), Color("10171d"), 3.0, true)
		draw_line(c + Vector2(0, -r * 0.15), c + Vector2(0, r * 0.15), Color("10171d"), 3.0, true)


func resume_game() -> void:
	started = true
	modal.hide()
	desk.process_mode = Node.PROCESS_MODE_INHERIT
	desk.get_node("Overlay/Frame").visible = overlay_was_visible
	desk.get_node("ResultsLayer").visible = results_were_visible

func show_tutorial(index: int) -> void:
	lesson = index
	_clear("tutorial")
	_title("HOW TO PLAY / %d OF %d" % [index + 1, LESSONS.size()], LESSONS[index][0], LESSONS[index][1])
	illustration = TextureRect.new()
	illustration.texture = LESSONS[index][2]
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(illustration)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 12)
	column.add_child(navigation)
	var back := NewsroomTheme.button("BACK")
	back.pressed.connect(func():
		if lesson == 0: show_menu()
		else: show_tutorial(lesson - 1))
	navigation.add_child(back)
	var next := NewsroomTheme.button("START MY SHIFT" if index == LESSONS.size() - 1 else "NEXT", true)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(func():
		if lesson == LESSONS.size() - 1: resume_game()
		else: show_tutorial(lesson + 1))
	navigation.add_child(next)
	_button("SKIP TUTORIAL" if not started else "RETURN TO DESK", resume_game)
	_layout()

func show_settings() -> void:
	_clear("settings")
	_title("YOUR NIGHT DESK", "SETTINGS", "Adjust the sound. Your preferences are saved on this device.")
	_slider("MUSIC", PlayerSettings.music_volume, func(value: float):
		PlayerSettings.music_volume = value
		PlayerSettings.save_preferences())
	_slider("SOUND EFFECTS", PlayerSettings.effects_volume, func(value: float):
		PlayerSettings.effects_volume = value
		PlayerSettings.save_preferences())
	var mute := CheckBox.new()
	mute.text = "Mute all sound (M during play)"
	mute.button_pressed = PlayerSettings.muted
	mute.add_theme_font_size_override("font_size", 17)
	mute.toggled.connect(func(value: bool):
		PlayerSettings.muted = value
		PlayerSettings.save_preferences())
	column.add_child(mute)
	_button("HOW TO PLAY", func(): show_tutorial(0))
	_button("BACK", show_menu, true)

func _slider(title: String, value: float, action: Callable) -> void:
	var label := NewsroomTheme.label("%s  %d%%" % [title, roundi(value * 100)], 17)
	column.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect(func(next: float):
		label.text = "%s  %d%%" % [title, roundi(next * 100)]
		action.call(next))
	column.add_child(slider)
