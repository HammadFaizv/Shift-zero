class_name LevelData
extends Resource

@export var id: StringName = &"bank"
@export var title: String = "FIRST CITY SAVINGS"
@export var incident: String = "Bank robbery / Friday, 2:14 PM"
@export var case_number: int = 1
@export_multiline var mechanic_hint: String = "Pull the red cord\nor press L to study\nthe prints - Marlon."
@export var tool_settings: Dictionary
@export var final_case: bool = false
@export var endings: Dictionary
@export var panels: Array[PanelData]
## Rect x/y is the image center on the page; width/height is its world size.
@export var photo_layouts: Array[Rect2] = []
@export_range(1, 3) var comic_columns: int = 2
@export var comic_wide_last: bool = false
@export var ceiling_starts_on: bool = true
@export var required_spun: int = 3
@export var available_tools: PackedStringArray = PackedStringArray(["Torch", "Paperweight", "Paperweight2"])
@export var tool_positions: Dictionary
@export var tool_yaws: Dictionary
@export var subtitles: Dictionary
@export var target_rings_default: bool = true
@export_multiline var editor_note: String = "Make him a hero. Prints 6am — Ed."
@export var comment_templates: CommentTemplates
@export var reaction_config: ReactionConfig
## Silent pass rules (never shown to the player): the share of lit-able hitboxes that must be lit and of
## hidden hitboxes that must stay dark before the public can warm to the page, whatever the score says.
@export_range(0.0, 1.0) var min_lit_share: float = 0.5
@export_range(0.0, 1.0) var min_dark_share: float = 0.5
