class_name ReactionConfig
extends Resource

@export var starting_score: float = 50.0
@export var state_weights: Dictionary = {"SPUN": 12.5, "DAMNING": -20.0, "TAMPERED": -12.0, "MURKY": -4.0}
@export var band_minima: PackedInt32Array = PackedInt32Array([0, 20, 40, 60, 80])
@export var band_names: PackedStringArray = PackedStringArray(["FURIOUS", "SUSPICIOUS", "DIVIDED", "CHARMED", "ADORING"])
@export var band_summaries: PackedStringArray = PackedStringArray(["Readers are calling for his arrest.", "People are zooming in on the panels.", "The city can't decide what it read.", "Most love him. A few keep zooming in.", "The city is in love with its hero."])
@export var fan_reply_minimum: int = 30
@export var displayed_comments: int = 9
@export var generic_comment_count: int = 7
@export var likes_base: int = 632
@export var likes_per_score: int = 74
@export var comments_base: int = 100
@export var comments_per_outrage: int = 4
@export var shares_base: int = 70
@export var shares_per_score: int = 9
@export var comment_likes_min: int = 30
@export var comment_likes_max: int = 580
