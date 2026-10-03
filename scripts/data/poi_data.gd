class_name POIData
extends Resource

enum Type { HERO, WEAPON, VICTIM, MONEY, WITNESS, DAMAGE, POLICE, FIRE, EXIT, SPEECH_BUBBLE }
enum Desired { VISIBLE, HIDDEN }

@export var id: StringName
@export var type: Type = Type.HERO
@export_multiline var description: String
@export var desired: Desired = Desired.VISIBLE
@export var position_uv: Vector2 = Vector2(0.5, 0.5)
@export_range(0.001, 0.5) var radius_uv: float = 0.055
@export var importance: float = 1.0
@export var comment_lines: PackedStringArray

var current_light: float = 0.0
var burned: bool = false
