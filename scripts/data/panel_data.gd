class_name PanelData
extends Resource

enum Rule { EXPOSED_EVIDENCE, BURN_MARK, LIT_HEROES }

@export var id: StringName
@export var title: String
@export var texture: Texture2D
@export var pois: Array[POIData]
@export var rule_order: PackedInt32Array = PackedInt32Array([0, 1, 2])
@export var fallback_state: StringName = &"MURKY"
@export var captions: Dictionary
@export var balloons: Dictionary
@export var sound_effects: Dictionary
@export var comments: Dictionary

var burned: bool = false
var burn_marks: Array[Vector3] = [] # Photo UV centre and radius in world units.
