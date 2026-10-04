class_name Sfx
extends RefCounted
## Static facade for sound. The first call lazily adds an AudioHub to the root;
## calls made before it is in the tree are queued and replayed in order.

static var _hub: Node
static var _pending: Array[Callable] = []
static var _creating: bool = false


static func click() -> void:
	_do(func(hub): hub.play(hub.CLICK))


static func pop(pitch: float = 1.0) -> void:
	_do(func(hub): hub.pop(pitch))


static func swoosh() -> void:
	_do(func(hub): hub.play(hub.SWOOSH, 1.0, -2.0))


static func shot() -> void:
	_do(func(hub): hub.play(hub.SHOT, 1.0, 2.0))


static func music(track: StringName) -> void:
	_do(func(hub): hub.music(track))


static func _do(action: Callable) -> void:
	if _hub != null and is_instance_valid(_hub):
		action.call(_hub)
		return
	_pending.append(action)
	if _creating:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_creating = true
	var hub: Node = load("res://scripts/game/audio_hub.gd").new()
	hub.name = "AudioHub"
	tree.root.add_child.call_deferred(hub)


static func _hub_ready(hub: Node) -> void:
	_hub = hub
	_creating = false
	var queued := _pending.duplicate()
	_pending.clear()
	for action in queued:
		action.call(hub)
