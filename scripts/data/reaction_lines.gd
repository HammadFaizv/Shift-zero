class_name ReactionLines
extends RefCounted
## Fallback reader comments by hitbox type, for exposed evidence that has no authored line.
## {n} is the panel number and {what} the lower-case hitbox description.

const EVIDENCE: Dictionary = {
	POIData.Type.HERO: ["Is that Halcyon doing that in panel {n}?! Somebody explain.", "Panel {n}: why is he standing there like that?"],
	POIData.Type.WEAPON: ["Is that a weapon in panel {n}? Why is it in a hero comic?", "Panel {n} shows a weapon. Nobody is asking about it?"],
	POIData.Type.VICTIM: ["Someone is hurt in panel {n}. Where was the rescue?", "Look at the {what} in panel {n}. Why is that in the paper?"],
	POIData.Type.MONEY: ["Is that money in panel {n}? Why is cash anywhere near a hero?", "Panel {n}: those are banknotes. Just saying."],
	POIData.Type.WITNESS: ["Who is that in the corner of panel {n}? They look terrified.", "The {what} in panel {n} knows something. Look at their face."],
	POIData.Type.DAMAGE: ["Who paid for the {what} in panel {n}?", "Panel {n} shows a lot of damage for a day with no villains."],
	POIData.Type.POLICE: ["Why are the police in panel {n} acting like that?", "Is that the {what} in panel {n}? Why was that left in?"],
	POIData.Type.FIRE: ["Why is there a fire hazard in panel {n}? Did anyone check?", "Panel {n}: {what}. Does anyone else find that worrying?"],
	POIData.Type.EXIT: ["Where does that way out in panel {n} lead? Was anyone trapped?"],
	POIData.Type.SPEECH_BUBBLE: ["Who is saying that in panel {n}?", "Read the speech bubble in panel {n} again. Slowly."],
}

const REPLIES: Dictionary = {
	POIData.Type.HERO: ["You are blaming the man for being in his own photo?", "Halcyon was working. Let him work."],
	POIData.Type.WEAPON: ["He took it away from somebody. That's the point."],
	POIData.Type.VICTIM: ["You are only seeing who was hurt. Halcyon is the reason it wasn't worse.", "He got there as fast as anyone could."],
	POIData.Type.MONEY: ["Of course there's money around a bank. Halcyon never took a cent."],
	POIData.Type.WITNESS: ["That's a witness who was saved. Halcyon cleared the scene."],
	POIData.Type.DAMAGE: ["Buildings can be rebuilt. People can't. Halcyon chose people.", "You should see what the city would look like without him."],
	POIData.Type.POLICE: ["The police and Halcyon were on the same side that day."],
	POIData.Type.FIRE: ["Halcyon is the one who put the fire out."],
	POIData.Type.EXIT: ["That's the exit he got everyone through."],
	POIData.Type.SPEECH_BUBBLE: ["Out of context. Halcyon said nothing of the sort."],
}
