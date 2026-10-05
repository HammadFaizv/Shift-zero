class_name PlayerSettings
extends RefCounted
## Local audio preferences shared by the menu and the persistent audio hub.
const PATH := "user://settings.cfg"
static var music_volume: float = 0.7
static var effects_volume: float = 0.8
static var muted: bool = false
static var _loaded := false

static func load_preferences() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		music_volume = clampf(float(config.get_value("audio", "music", 0.7)), 0.0, 1.0)
		effects_volume = clampf(float(config.get_value("audio", "effects", 0.8)), 0.0, 1.0)
		muted = bool(config.get_value("audio", "muted", false))

static func save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("audio", "muted", muted)
	config.save(PATH)
	apply_audio()

static func apply_audio() -> void:
	AudioServer.set_bus_mute(0, muted)
	if is_instance_valid(Sfx._hub):
		Sfx._hub.apply_preferences()
