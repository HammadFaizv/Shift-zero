extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func click(screen: Node, text: String) -> void:
	for button in screen.column.find_children("*", "Button", true, false):
		if button.text == text:
			button.pressed.emit()
			return
	check(false, "Missing button: " + text)

func run() -> void:
	var screen = load("res://scenes/ui/start_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await physics_frame
	check(screen.page == "menu", "Game opens at main menu")
	check(not screen.desk.can_process(), "Desk paused behind menu")
	check(not screen.desk.get_node("Overlay/Frame").visible, "Desk controls hidden behind menu")
	click(screen, "SETTINGS")
	check(screen.page == "settings", "Settings button opens settings")
	var sliders = screen.column.find_children("*", "HSlider", true, false)
	var original_music := PlayerSettings.music_volume
	sliders[0].value = 0.31
	check(is_equal_approx(PlayerSettings.music_volume, 0.31), "Slider changes music preference")
	var config := ConfigFile.new()
	check(config.load(PlayerSettings.PATH) == OK, "Settings saved locally")
	check(is_equal_approx(float(config.get_value("audio", "music")), 0.31), "Saved volume matches slider")
	sliders[0].value = original_music
	click(screen, "BACK")
	click(screen, "PLAY")
	for index in 4:
		check(screen.page == "tutorial" and screen.lesson == index, "Tutorial step %d" % index)
		check(screen.illustration.texture.get_width() > 0, "Diagram imported")
		check(not screen.desk.can_process(), "Tutorial blocks gameplay")
		click(screen, "START MY SHIFT" if index == 3 else "NEXT")
	check(screen.started and not screen.modal.visible, "Tutorial enters game")
	check(screen.desk.can_process(), "Desk resumes")
	check(screen.desk.get_node("Overlay/Frame").visible, "Desk controls restored after settings and tutorial")
	screen.desk.load_case(2)
	await physics_frame
	var pose: Transform3D = screen.desk.get_node("Tools/Torch").transform
	screen.show_menu()
	click(screen, "HOW TO PLAY")
	click(screen, "RETURN TO DESK")
	check(screen.desk.case_index == 2 and screen.desk.get_node("Tools/Torch").transform == pose, "Replaying tutorial preserves case and tool pose")
	await screen.desk.publish()
	check(screen.desk.result != null, "Publishing works after tutorial")
	screen.show_menu()
	click(screen, "RESUME")
	check(not screen.desk.get_node("Overlay/Frame").visible and screen.desk.get_node("ResultsLayer").visible, "Returning from menu preserves results view")
	print("Start screen regression: ", failures, " failures")
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)
