extends Node
## One persistent node that owns every AudioStreamPlayer. Reached through Sfx.

const CLICK: AudioStream = preload("res://Assets/sounds/computer-mouse-click-universfield.mp3")
const POPS: Array[AudioStream] = [
	preload("res://Assets/sounds/bubble-pop-1-pixabay-Universfield.mp3"),
	preload("res://Assets/sounds/bubble-pop-2-universfield.mp3"),
]
const SWOOSH: AudioStream = preload("res://Assets/sounds/universfield-fast-swoosh-06-567195.mp3")
const SHOT: AudioStream = preload("res://Assets/sounds/mrfriends-pistol-shot.mp3")
const NOIR: AudioStream = preload("res://Assets/sounds/alex-morgan-noir-jazz-detective.mp3")
## One loop plays everywhere; screens may name their own track later and the hub will cross-fade.
const TRACKS: Dictionary = {&"desk": NOIR, &"result": NOIR}

@export var voices: int = 8
@export var sfx_db: float = -4.0
@export var music_db: float = -10.0
@export var fade_seconds: float = 1.6
@export var pitch_jitter: float = 0.06

var _voices: Array[AudioStreamPlayer] = []
var _music: Array[AudioStreamPlayer] = []
var _track: StringName = &""
var _active: int = 0
var _fade: Tween
var _muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in voices:
		_voices.append(_player(sfx_db))
	for i in 2:
		_music.append(_player(-80.0))
	for stream in TRACKS.values():
		stream.loop = true
	Sfx._hub_ready(self)


func _player(volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = volume
	add_child(player)
	return player


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		_muted = not _muted
		AudioServer.set_bus_mute(0, _muted)


func play(stream: AudioStream, pitch: float = 1.0, offset_db: float = 0.0) -> void:
	var voice := _voices[0]
	for candidate in _voices:
		if not candidate.playing:
			voice = candidate
			break
	voice.stream = stream
	voice.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	voice.volume_db = sfx_db + offset_db
	voice.play()


func pop(pitch: float = 1.0) -> void:
	play(POPS[randi() % POPS.size()], pitch)


func music(track: StringName) -> void:
	if track == _track or not TRACKS.has(track):
		return
	_track = track
	# Same loop already playing (desk -> comic): keep it running, no restart.
	if _music[_active].playing and _music[_active].stream == TRACKS[track]:
		return
	var outgoing := _music[_active]
	_active = 1 - _active
	var incoming := _music[_active]
	incoming.stream = TRACKS[track]
	incoming.volume_db = -80.0
	incoming.play()
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(incoming, "volume_db", music_db, fade_seconds)
	_fade.tween_property(outgoing, "volume_db", -80.0, fade_seconds)
	_fade.chain().tween_callback(outgoing.stop)
