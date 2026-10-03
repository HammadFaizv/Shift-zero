class_name UIStyle
extends Resource
## Shared visual tuning for dynamically built desk and results controls.

@export var paper: Color = Color("eee7d2")
@export var dark: Color = Color("10171d")
@export var gold: Color = Color("e4b85c")
@export var muted: Color = Color("a8b0af")
@export var state_colors: Dictionary = {"SPUN": Color("85c5b1"), "DAMNING": Color("f17e72"), "MURKY": Color("dfb967"), "TAMPERED": Color("c0a0e8")}
@export var default_font_size: int = 16
@export var corner_radius: int = 8
@export var border_width: int = 1
@export var panel_padding: int = 12
@export var button_height: int = 40
@export var button_color: Color = Color("26353e")
@export var button_hover_lighten: float = 0.12
@export var button_pressed_darken: float = 0.12
