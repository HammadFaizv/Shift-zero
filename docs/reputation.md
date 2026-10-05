# Reputation points, desk guide and sound

## Every hitbox has its own points

Each evidence hitbox (`POIData.importance`) is worth reputation points:

* a **hidden** hitbox that is still lit (`>= 0.30`) costs its points;
* a **visible** hitbox that is lit enough (`>= 0.55`) earns them, half if it is only murky, none if dark;
* a scorched hitbox earns nothing.

The score is `100 x earned / total` over every hitbox in the case (`scripts/game/reputation.gd`),
so it drives the Public Mood meter, likes and the editor's reply. Weights of 3 or more are *serious* and
5 or more *devastating*; the pencil marks and the desk guide use those tiers instead of numbers.
Weights are authored in `tools/author_content.py`.

| Case | Hidden hitboxes (points) | Visible hitboxes |
| --- | --- | --- |
| 2 People's Hero | murderer accusation 5, accusing man 3 | hero 3, three cheerers 1 each |
| 3 Above the Lake | drowning woman 6, girl on shore 3 | hero 3 |
| 4 Keeping the Peace (print 2) | officer 4, officer dialogue 3 | hero 2, dead civilian 1 |
| 5 The Rescue | print 1 hero 6; print 2 dead witness 4 | witness, fire 1; hero 2, child 1 |
| 6 The Bank | print 1 hero 5, fleeing child 2, fleeing man/woman 1.5; print 2 vault 3; **print 3 hero head 5, hero dialogue 4**; **print 4 five falling bills 0.6 each** | hero 2-3, guard/manager/car 1 |
| 7 Our Greatest Hero | attack 4, damage 3, fleeing 4, injured 5, victims 5, witnesses/police/damage 3 | hero 3 |

So in the bank, letting the hero-hitting-the-manager print show costs far more than letting a banknote show.

## Silent pass rules (not shown to the player)

A page that is mostly dark or mostly exposed can never win the city over, whatever its points say. Each level
(`LevelData.min_lit_share`, `min_dark_share`, both 0.5 by default) needs at least half of its lit-able hitboxes fully
lit **and** at least half of its hidden hitboxes safely hidden. If either fails, the public score is capped at
`ReactionConfig.gate_fail_cap` (45, "Divided"), so the stage cannot be cleared. A page with no lighting therefore
fails every stage. `tools/solve_stages.gd` confirms each stage can still reach 80+ with the rules applied;
`tests/reputation.gd` checks the dark page fails and the intended page passes on all eight stages.

## Desk guide wording

The sidebar headline reads the page instead of counting panels: *Everything is exposed* (75% or more of
the hidden points show), *The elephant in the room is left* (the heaviest hidden hitbox shows),
*Some things are still left*, *His greatness is still in the dark* (nothing exposed but the hero is unlit) and
*Our superhero's greatness knows no bound* (perfect). Each clean print shows the editor's self-justification
(`PanelData.rationale`); an exposed print lists what still shows and how badly it would hurt.

## Comic page and comments

The published page (`comic_result_ui.gd`, `comic_grid.gd`, `comic_panel_view.gd`) fits every page size with no
scrolling. Each panel has a narration box (`captions`), a speech balloon pointing at the speaker (`balloons`)
and a sound-effect burst (`sound_effects`). Reader comments come from the printed panels: the panel's own
`comments` line for its state, plus each exposed hitbox's `comment_lines` (`{n}` is the panel number). Each
comment is tagged with the panel it is about.

## Sound

`Assets/sounds/`, played through `scripts/game/sfx.gd` (static `Sfx.click/pop/swoosh/music`) and one persistent
`audio_hub.gd` node: mouse click on buttons, tool selection and light switches; swoosh on publish, case change and
returning to the desk; bubble pops when a hitbox becomes settled (higher) or exposed (lower) and as comic
balloons appear. "Noir Jazz Detective" loops at the desk and on the published comic without restarting (the hub still cross-fades if a screen names a different track).
**M** mutes everything. Volumes are `@export`s on the hub.

## Tools

`godot --path . --script tools/shot.gd -- <case 0-6> <out_prefix> [real|perfect|exposed|dark]` saves desk and comic
screenshots. Tests: `tests/reputation.gd`, `tests/audio.gd`, `tests/stage_photos.gd`.

## Desk snail

`DeskSnail` (last child of Main, `scripts/props/desk_snail.gd`) has a `snail_on_table` bool. When true, a snail
with a "don't click" note spawns at a random spot in `spawn_zone` (left of the desk) and crawls a small
circle. Clicking it slides a pistol in, plays `mrfriends-pistol-shot`, flashes (muzzle star, light and a brief
white screen flash) and replaces the snail with green goo (`shaders/goo.gdshader`) that fades away. Setting the
bool false removes the snail; setting it true again brings back a fresh one. Test: `tests/snail.gd`;
screenshots of the sequence: `tools/shot_snail.gd`.
