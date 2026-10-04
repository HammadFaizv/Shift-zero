extends SceneTree
## Music follows the screen; sfx hooks fire. godot --headless --path . --script tests/audio.gd
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func verify(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func playing_track(hub: Node) -> AudioStream:
	for player in hub._music:
		if player.playing and player.volume_db > -40.0:
			return player.stream
	return null


func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(2.0).timeout
	var hub: Node = Sfx._hub
	verify(hub != null and hub.is_inside_tree(), "Audio hub joins the tree")
	verify(playing_track(hub) == hub.TRACKS[&"desk"], "Desk music plays at start")
	Sfx.click()
	Sfx.pop()
	Sfx.swoosh()
	var busy := 0
	for voice in hub._voices:
		busy += int(voice.playing)
	verify(busy >= 2, "Click, pop and swoosh take voices")
	await scene.publish()
	await create_timer(2.5).timeout
	verify(playing_track(hub) == hub.NOIR, "The noir jazz loop keeps playing on the comic")
	scene.back_to_desk()
	await create_timer(2.5).timeout
	verify(playing_track(hub) == hub.NOIR, "The noir jazz loop keeps playing at the desk")
	for stream in hub.TRACKS.values():
		verify(stream.loop, "Music loops")
	print("Audio regression: ", failures, " failures")
	quit(1 if failures else 0)
