class_name CommentTemplates
extends Resource

@export var usernames: PackedStringArray
@export var fan_comments: PackedStringArray
@export var skeptic_comments: PackedStringArray
@export var murky_group: String
@export var burned_comment: String
@export var fan_reply: String
@export var twist: String
@export var twist_reply: String
@export var post_caption: String
@export var exposed_group: String = "Okay, who is going to say it? This isn't a hero comic."
@export var perfect_group: String = "Not one thing out of place. Suspiciously perfect."
## Fans who answer comments that blame Halcyon.
@export var defender_names: PackedStringArray = PackedStringArray(["cape_club", "halcyon_forever", "captains_corner", "first_city_proud"])
@export var defender_replies: PackedStringArray = PackedStringArray([
	"Context, people. He was there to help.",
	"One photo is not the whole story. Halcyon has saved this city a hundred times.",
	"Easy to judge from a sofa. Where were you when he showed up?",
	"He never asked for the credit. Leave the man alone.",
])
## Praise for a panel where Halcyon is clearly lit ({n} is the panel number).
@export var praise_comments: PackedStringArray = PackedStringArray([
	"Panel {n}: look at him. First City sleeps soundly because of Halcyon.",
	"That's the Halcyon I know in panel {n}. Not a hair out of place.",
	"Panel {n} made my whole morning. Thank you, Captain!",
	"Frame panel {n} and hang it in the town hall.",
])
## Page-wide comments: when most panels shine, and when anything is showing.
@export var page_praise: String
@export var page_critic: String
@export var page_critic_reply: String
