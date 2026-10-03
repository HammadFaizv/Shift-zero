# Level asset guide

Folders (same layout in svg/ and png/):
- backgrounds/   640x640, each in *_day and *_night
- characters/    hero poses, citizens, police, witnesses
- props/         vault, money, buildings, vehicles, fire items
- effects/       flames, smoke, splashes, cracks, confetti
- comic/         speech bubbles and sound-effect bursts

Characters and props have 12px of padding so outlines never clip.
Bubble text is live text in the SVG (edit it in Inkscape). In the PNG it is baked in.

## 1 - The Hero
Background: backgrounds/rooftops_day or _night (or street_*)
Hero:       characters/hero_dramatic
Extras:     effects/dust_cloud

## 2 - The People's Hero
Background: backgrounds/plaza_day or _night
Hero:       characters/hero_waving
Crowd:      citizen_cheer_man, citizen_cheer_woman, citizen_cheer_kid (reuse and mirror for a bigger crowd)
Props:      props/banner_we_love_halcyon, effects/confetti
Bubble:     comic/speech_bubble_hooray

## 3 - The Drowning
Background: backgrounds/lake_day or _night
Hero:       characters/hero_flying_arms_crossed (ignoring her)
Evidence:   characters/drowning_woman  (hide this)
Extras:     effects/water_splash, effects/water_ripples, props/life_ring
Bubble:     comic/speech_bubble_help

## 4 - He Was Innocent
Background: backgrounds/street_day or _night
Hero:       characters/hero_standing
Evidence:   characters/body_citizen_lying, characters/cop_shouting (hide upper body)
Bubble:     comic/speech_bubble_he_was_innocent (hide this)
Extras:     props/police_car, props/police_tape

## 5 - The Fire
Background: backgrounds/street_day or _night
Photo A:    hero_dramatic + props/burning_building + survivor_blanket_woman + survivor_blanket_man
            effects/flame_big, flame_small, smoke_cloud
Photo B:    witness_man_blue (hide) + props/gas_can_with_hero_emblem + props/hero_lighter (hide)
            comic/speech_bubble_he_did_this

## 6 - The Bank
Background: backgrounds/bank_front_day or _night
Photo A:    hero_attack + characters/robber_hands_up + props/money_bag + props/bank_building
            comic/burst_blank_yellow for "KA-POW!"
Photo B:    hero_running + props/cash_bill (scatter several behind him) + characters/guard_pointing_shouting
            comic/speech_bubble_stop_thief

## 7 - The Truth
Background: backgrounds/ruined_city_day or _night
Hero:       characters/hero_attack (+ effects/energy_blast)
Fleeing:    citizen_fleeing_a, citizen_fleeing_b, citizen_fleeing_c
Witnesses:  witness_woman_red, witness_man_blue, witness_woman_green
Wreckage:   props/ruined_building, props/wrecked_car, props/rubble_pile, props/bent_lamppost,
            effects/ground_crack, effects/scorch_mark, effects/smoke_cloud, effects/flame_big
Bubbles:    comic/speech_bubble_he_did_this, speech_bubble_run

## Also included from the first batch
props/vault_door_intact, vault_door_broken_fist_hole, cash_pile, cash_stacks, city_skyline_strip
characters/hero_flying, guard_knocked_out, teller_pointing, civilian_red/green/purple
comic/speech_bubble_blank, speech_bubble_it_was_him, burst_blank_orange
