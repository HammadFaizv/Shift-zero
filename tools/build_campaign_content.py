#!/usr/bin/env python3
"""Author editable 768x640 SVGs and data-only cases 2–5. No runtime dependency."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CASES = [
    {
        'id': 'factory', 'number': 2, 'title': 'FOUNDRY NIGHT SHIFT',
        'incident': 'Factory fire / Monday, 11:46 PM',
        'hint': 'Two narrow torches.\nAim one at each row.\nKeep the exits dark.',
        'note': 'They need a rescuer.\nNot another question.\nPrints 6am - Ed.',
        'perfect': 'RESCUES THE NIGHT SHIFT!', 'damning': 'WHO STARTED THE FIRE?',
        'panels': [
            ('THE SPARK', 'Halcyon reaches the foundry before the flames spread.', 'A flame leaps from his hand into a pool of fuel.', 'a flame at his hand', 'FIRE'),
            ('THE EXIT', 'Halcyon clears a route for the trapped night shift.', 'His fist holds the emergency door shut from outside.', 'a chained emergency door', 'EXIT'),
            ('THE RESCUE', 'Halcyon guides a shaken worker out of the smoke.', 'A worker points past him toward colleagues behind the glass.', 'workers behind the window', 'VICTIM'),
            ('THE DEPARTURE', 'Halcyon carries the rescued workers to safety.', 'The case he carries is the payroll box, not a worker.', 'the foundry payroll box', 'MONEY'),
        ],
    },
    {
        'id': 'protest', 'number': 3, 'title': 'ASSEMBLY SQUARE',
        'incident': 'City protest / Wednesday, 5:32 PM',
        'hint': 'Catch the upright beam\nwith the reading glasses.\nAim their green beam.',
        'note': 'Keep the square calm.\nKeep his hands clean.\nPrints 6am - Ed.',
        'perfect': 'KEEPS THE PEACE!', 'damning': 'PEACE... AT WHAT PRICE?',
        'panels': [
            ('THE ARRIVAL', 'Halcyon arrives to protect a crowded public square.', 'He lands in the middle of an unarmed crowd with his fist raised.', 'unarmed marchers', 'VICTIM'),
            ('THE LINE', 'Halcyon keeps the police line from collapsing.', 'The shields face the marchers; he is directing the advance.', 'a line of riot shields', 'POLICE'),
            ('THE WITNESS', 'Halcyon helps a witness through the confusion.', 'The witness holds a photograph of the worker from the foundry.', 'the witness and a missing-worker print', 'WITNESS'),
            ('THE SWEEP', 'Halcyon escorts a dangerous ringleader from the square.', 'The person in his grip is carrying a first-aid bag.', 'a first-aid bag', 'VICTIM'),
        ],
    },
    {
        'id': 'museum', 'number': 4, 'title': 'CIVIC MUSEUM',
        'incident': 'Museum incident / Saturday, 1:08 AM',
        'hint': 'The reflected beam is weak.\nFocus it on the last hero.\nMove if it gets TOO HOT.',
        'note': 'Never touch the prints.\nNo scorch marks.\nPrints 6am - Ed.',
        'perfect': 'PROTECTS OUR TREASURES!', 'damning': 'THE MISSING MASTERPIECE?',
        'panels': [
            ('THE ENTRY', 'Halcyon follows an intruder into the museum.', 'The window has been broken inward beside his boot.', 'glass broken inward', 'DAMAGE'),
            ('THE DISPLAY', 'Halcyon secures the empty display against the thieves.', 'A matching sculpture is tucked under his cape.', 'the missing sculpture', 'MONEY'),
            ('THE GUARD', 'Halcyon reassures the guard after a frightening night.', 'The guard is pointing at him, not at the broken window.', 'the guard pointing at Halcyon', 'WITNESS'),
            ('THE ROOFTOP', 'Halcyon carries recovered treasures back to safety.', 'He climbs away with the museum collection in a sack.', 'a sack of tagged museum objects', 'MONEY'),
        ],
    },
    {
        'id': 'train', 'number': 5, 'title': 'NORTHLINE EXPRESS',
        'incident': 'Train disaster / Sunday, 4:51 AM',
        'hint': 'Redirect, focus, conceal.\nThen choose what prints.\nThe originals still exist.',
        'note': 'Last edition.\nGive the city its hero.\nPrints 6am - Ed.',
        'perfect': 'SAVES THE NORTHLINE!', 'damning': 'THE PHOTOS THEY DID NOT PRINT',
        'panels': [
            ('THE SIGNAL', 'Halcyon races to stop a runaway passenger train.', 'His hand is on the lever pointing the express toward a broken track.', 'a diverted railway signal', 'DAMAGE'),
            ('THE BREAK', 'Halcyon lifts wreckage to free the trapped passengers.', 'The severed rail bends around the shape of his fist.', 'a rail torn apart by a fist', 'DAMAGE'),
            ('THE PASSENGERS', 'Halcyon carries a shaken passenger away from danger.', 'The passenger reaches toward a child still inside the wreck.', 'a child inside the wrecked carriage', 'VICTIM'),
            ('THE CARGO', 'Halcyon protects the relief fund from looters.', 'He leaves with the relief fund while the rescue crews are still arriving.', 'stolen relief-fund crates', 'MONEY'),
        ],
    },
]

TYPES = {'VICTIM': 2, 'MONEY': 3, 'WITNESS': 4, 'DAMAGE': 5, 'POLICE': 6, 'FIRE': 7, 'EXIT': 8}
BANK_H = [(0.65, 0.72), (0.28, 0.72), (0.65, 0.22), (0.28, 0.22)]
BANK_E = [(0.25, 0.28), (0.76, 0.30), (0.23, 0.74), (0.76, 0.72)]
OPTIC_H = [(0.95, 0.65), (0.05, 0.65), (0.95, 0.12), (0.85, 0.75)]
OPTIC_E = [(0.22, 0.20), (0.75, 0.30), (0.22, 0.78), (0.76, 0.17)]


def quoted(value):
    return json.dumps(value, ensure_ascii=False)


def dictionary(value):
    return '{\n' + ',\n'.join(f'{quoted(k)}: {v}' for k, v in value.items()) + '\n}'


def hero(x, y):
    return f'''<g transform="translate({x} {y}) scale(1 1.7)" stroke="#293743" stroke-width="4" stroke-linejoin="round">
<path d="M-8-20L-34 37 10 30 19-20Z" fill="#42596d"/>
<path d="M-12 14L-20 43 -5 43 2 23 8 44 23 44 13 13Z" fill="#4d6878"/>
<path d="M-16-18L-30 3 -22 10 -9-2 9-2 24 10 31 3 17-18Z" fill="#ac935e"/>
<path d="M-13-20H13V17H-13Z" fill="#ac935e"/>
<circle cy="-31" r="13" fill="#b7ac94"/><path d="M-12-34H12V-28H-12Z" fill="#42596d"/>
<path d="M-4-9V7M4-9V7M-4-1H4" stroke="#42596d"/>
</g>'''


def evidence(kind, x, y, number, case_id):
    if case_id == 'train' and number == 0:
        shape = '<rect x="-53" y="-58" width="106" height="118" fill="#65736d"/><circle cx="-24" cy="-30" r="12" fill="#9c4940"/><circle cx="24" cy="-30" r="12" fill="#aaa06c"/><path d="M-10 47L40-12" stroke="#b4ac93" stroke-width="18"/><path d="M20-28H60V-1H20Z" fill="#ac935e"/><path d="M-82 80L73 59M-83 52L-12 42 10 45 71 28" stroke="#46535a" stroke-width="12"/>'
    elif case_id == 'train' and number == 1:
        shape = '<path d="M-91 26L-31 0 0-37 25-16 46-30 84-3M-90 67L-18 33 16 9 37 43 91 19" fill="none" stroke="#4a5660" stroke-width="19"/><path d="M-6-44H36V-11H-6Z" fill="#ac935e"/><path d="M-29 59L-11 45M24 74L40 53" stroke="#aeb0a1" stroke-width="8"/>'
    elif case_id == 'train' and number == 2:
        shape = '<rect x="-59" y="-61" width="118" height="131" fill="#455560"/><circle cy="-16" r="17" fill="#bba88e"/><path d="M-19 5H19V50H-19Z" fill="#86786b"/><path d="M-18 15L-48-19" stroke="#bba88e" stroke-width="12"/><path d="M-36-61V70M36-61V70" stroke="#8a969b" stroke-width="13"/>'
    elif kind == 'FIRE':
        shape = '<path d="M-64 39Q-85 0-42-33L-37-70Q-6-50-17-17Q29-55 37-15Q83 27 52 41Z" fill="#9e553c"/><path d="M-30 35Q-48 10-6-29Q0 1 17 8Q45 29 26 39Z" fill="#b99a55"/><ellipse cy="49" rx="83" ry="13" fill="#453e36"/>'
    elif kind == 'EXIT':
        shape = '<rect x="-60" y="-73" width="120" height="147" fill="#53605d"/><rect x="-52" y="-64" width="104" height="126" fill="#738178"/><path d="M-68-16L62 45M-64 36L58-27" stroke="#363f44" stroke-width="13"/><rect x="-14" y="-8" width="28" height="34" rx="4" fill="#9b8559"/>'
    elif kind == 'POLICE':
        shape = ''.join(f'<g transform="translate({a} 0)"><circle cy="-42" r="18" fill="#4c5964"/><path d="M-23-17H23V62H-23Z" fill="#65737d"/><path d="M-15 1H15V43H-15Z" fill="#a4aaa7"/></g>' for a in [-56, 0, 56])
    elif kind == 'WITNESS':
        shape = '<circle cy="-41" r="22" fill="#bba88e"/><path d="M-23-14H23V61H-23Z" fill="#816b63"/><path d="M18-1L73-33" stroke="#bba88e" stroke-width="16"/><rect x="-59" y="-9" width="43" height="52" fill="#c2bcaa"/><path d="M-53 0L-22 34M-22 0L-53 34" stroke="#725e56" stroke-width="5"/>'
    elif kind == 'VICTIM':
        shape = ''.join(f'<g transform="translate({a} {b})"><circle cy="-25" r="16" fill="#bba88e"/><path d="M-17-7H17V41H-17Z" fill="{c}"/><path d="M-8 40V62M8 40V62" stroke="#45515a" stroke-width="12"/></g>' for a, b, c in [(-45, 4, '#80786c'), (0, -9, '#786f64'), (44, 3, '#6f7c75')])
    elif kind == 'DAMAGE':
        shape = '<rect x="-92" y="-54" width="184" height="110" fill="#96968b"/><path d="M-72-40L-31-21-12-54 17-18 61-45 36-6 83 29 22 24 9 59-19 20-68 41-46 7Z" fill="#414d56"/><path d="M-75 66L-50 47-24 68M44 65L63 41 83 58" stroke="#c0baa4" stroke-width="8"/>'
    else:
        shape = '<path d="M-53-38L-39-61H39L53-38 70 46Q58 71 0 71Q-58 71-70 46Z" fill="#6b766b"/><path d="M-40-39H40" stroke="#aea286" stroke-width="8"/><rect x="-18" y="-10" width="36" height="45" fill="#b9ae87"/><path d="M0-6V31M-8 3H8M-8 21H8" stroke="#647067" stroke-width="6"/>'
    return f'<g transform="translate({x} {y})" stroke="#38434a" stroke-width="5" stroke-linejoin="round">{shape}</g>'


def photograph(case, index, h, e, kind):
    tone = ['#8c9694', '#919595', '#969188', '#85919a'][case['number'] - 2]
    backdrop = ''
    if case['id'] == 'factory':
        backdrop = '<path d="M30 310V115H195V260H330V65H388V310" fill="#66716f"/><path d="M392 310V130H730V310" fill="#a5a696"/><path d="M437 130V310M490 130V310M543 130V310M596 130V310M649 130V310" stroke="#687474" stroke-width="13"/>'
    elif case['id'] == 'protest':
        backdrop = '<path d="M0 180H768V330H0Z" fill="#a5a494"/><path d="M50 180V325M205 180V325M360 180V325M515 180V325M670 180V325" stroke="#778483" stroke-width="37"/><path d="M0 405H768M0 510H768" stroke="#8b8c80" stroke-width="3"/>'
    elif case['id'] == 'museum':
        backdrop = '<path d="M40 260L380 50 728 260Z" fill="#b1aa98"/><path d="M55 275H713V350H55Z" fill="#aaa694"/><path d="M99 273V506M290 273V506M478 273V506M670 273V506" stroke="#bab6a3" stroke-width="40"/>'
    else:
        backdrop = '<path d="M20 145H745V302H20Z" fill="#667883"/><path d="M50 168H719V241H50Z" fill="#afb4ae"/><path d="M100 168V241M225 168V241M350 168V241M475 168V241M600 168V241" stroke="#526371" stroke-width="17"/><path d="M5 610L754 339M10 540L670 299" stroke="#48565e" stroke-width="19"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="768" height="640" viewBox="0 0 768 640">
<rect width="768" height="640" fill="{tone}"/><rect y="330" width="768" height="310" fill="#797d76"/>
{backdrop}
{evidence(kind, e[0] * 768, e[1] * 640, index, case['id'])}
{hero(h[0] * 768, h[1] * 640)}
<path d="M5 5H763V635H5Z" fill="none" stroke="#545f61" stroke-width="6"/>
</svg>'''


def panel_resource(case, i, h, e):
    title, spun, damning, clue, kind = case['panels'][i]
    states = {'SPUN': spun, 'DAMNING': damning, 'MURKY': f'The {title.lower()} photograph is too dark to explain.', 'TAMPERED': f'The {title.lower()} photograph has been scorched. The print is damaged.'}
    comments = {'SPUN': f'Panel {i + 1}: {spun} Thank you, Captain!', 'DAMNING': f'Zoom into panel {i + 1}: {clue}. {damning}', 'MURKY': f'I cannot read panel {i + 1}. What happened at {case["title"].title()}?'}
    name = f'{i + 1:02d}_panel'
    return f'''[gd_resource type="Resource" script_class="PanelData" format=3]
[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]
[ext_resource type="Script" path="res://scripts/data/poi_data.gd" id="poi"]
[ext_resource type="Texture2D" path="res://Assets/evidence/{case['id']}/{name}.svg" id="photo"]
[sub_resource type="Resource" id="Hero"]
script = ExtResource("poi")
id = &"H{i + 1}"
description = "Captain Halcyon"
position_uv = Vector2({h[0]}, {h[1]})
radius_uv = {0.04 if case['number'] == 2 else 0.025}
[sub_resource type="Resource" id="Evidence"]
script = ExtResource("poi")
id = &"E{i + 1}"
type = {TYPES[kind]}
desired = 1
description = {quoted(clue)}
position_uv = Vector2({e[0]}, {e[1]})
radius_uv = 0.07
[resource]
script = ExtResource("panel")
id = &"{case['id']}_{name}"
title = {quoted(title)}
texture = ExtResource("photo")
pois = Array[ExtResource("poi")]([SubResource("Hero"), SubResource("Evidence")])
rule_order = PackedInt32Array({"1, 0, 2" if case['number'] >= 4 else "0, 1, 2"})
captions = {dictionary({k: quoted(v) for k, v in states.items()})}
balloons = {dictionary({k: quoted(v) for k, v in {'SPUN': 'You are safe with me.', 'DAMNING': 'Stand aside.', 'MURKY': '???', 'TAMPERED': 'Where is the rest?'}.items()})}
sound_effects = {dictionary({k: quoted(v) for k, v in {'SPUN': ['WHOOSH!', 'HOLD FAST!', 'SAFE NOW!', 'UP AND AWAY!'][i], 'DAMNING': ['CRASH!', 'KRAK!', 'NO!', 'KA-CHING!'][i], 'MURKY': '...', 'TAMPERED': 'FZZT!'}.items()})}
comments = {dictionary({k: quoted(v) for k, v in comments.items()})}
'''


def comments_resource(case):
    values = {
        'usernames': 'PackedStringArray("square_watch", "night_shift", "halcyon_fan", "first_city_mum", "railway_worker", "beacon_reader", "quiet_ledger")',
        'fan_comments': 'PackedStringArray("We need him now more than ever.", "My kid wants to be Captain Halcyon.", "The Beacon always gets the story right.", "Thank you for keeping our city safe.")',
        'skeptic_comments': 'PackedStringArray("The photographs do not match the headline.", "Why are the witnesses always in shadow?", "Go back and look at the earlier editions.", "Stop telling us what to see.")',
        'murky_group': quoted('Did they draw half of this with the lights off??'),
        'burned_comment': quoted('Is that a BURN MARK on panel %d? What is the Beacon hiding?'),
        'fan_reply': quoted('He was protecting them. Read the caption again.'),
        'twist': quoted('Same perfect light around him. Same darkness around everyone else. Who keeps doing that?'),
        'twist_reply': quoted('It is just the comic style. You are reading too much into it.'),
        'post_caption': quoted(f'A new edition from {case["title"].title()}. Your city. Your hero. #CaptainHalcyon #DailyBeacon'),
    }
    return '[gd_resource type="Resource" script_class="CommentTemplates" format=3]\n[ext_resource type="Script" path="res://scripts/data/comment_templates.gd" id="script"]\n[resource]\nscript = ExtResource("script")\n' + '\n'.join(f'{k} = {v}' for k, v in values.items()) + '\n'


def level_resource(case):
    optics = case['number'] >= 3
    tools = ['Torch', 'Paperweight', 'Paperweight2']
    if case['number'] == 2:
        tools += ['Torch2']
    if optics:
        tools += ['ReadingGlasses']
    if case['number'] >= 4:
        tools += ['MagnifyingGlass']
    positions = {'Torch': 'Vector3(-3.9, 0, -1.1)', 'Torch2': 'Vector3(-3.9, 0, 2.2)', 'Paperweight': 'Vector3(-4.55, 0, 0.9)', 'Paperweight2': 'Vector3(-3.1, 0, 1.7)', 'ReadingGlasses': 'Vector3(3.2, 0, 0.9)', 'MagnifyingGlass': 'Vector3(3.1, 0, 2.0)'}
    settings = {'Torch/Beam/VisualLight:spot_angle': '10.0', 'Torch2/Beam/VisualLight:spot_angle': '10.0'}
    if optics:
        settings = {'Torch/Beam/VisualLight:spot_angle': '8.5', 'Torch/Beam:rotation_degrees': 'Vector3(-3, -90, 0)', 'Torch/GameplayLight:intensity': '2.8', 'Torch/Beam/VisualLight:spot_range': '10.0', 'ReadingGlasses/Redirector:intensity': '2.0'}
    if case['number'] >= 4:
        settings['ReadingGlasses/Redirector:maximum_output'] = '0.22'
    endings = {}
    if case['number'] == 5:
        endings = {
            'edited': quoted({'headline': 'CITY RENEWS ITS FAITH IN HALCYON', 'subtitle': 'A HERO, AS PRINTED', 'message': 'The rescue becomes another cheerful edition. The originals return to the drawer. Tomorrow the desk will need you again.', 'comments': ['My kid wants to be just like him.', 'The Beacon says he saved everyone. That is enough for me.', 'My family was on that train. Why can I not see them in this comic?'], 'captions': ['A city is given a rescuer.', 'A broken rail becomes a battle won.', 'Those left in shadow do not make the headline.', 'The original photographs go back into the drawer.']}),
            'original': quoted({'headline': 'ORIGINAL PHOTOS EXPOSE HALCYON', 'subtitle': 'THE WHOLE PAGE, IN DAYLIGHT', 'message': 'The original evidence prints reach the city intact. Readers compare the train, the museum, the square and the foundry. The Beacon cannot put the story back in the drawer.', 'comments': ['That is his hand on the signal. Show every photograph.', 'Now look at the museum edition. We were told the same lie.', 'The railway families deserve the whole story.'], 'captions': [p[2] for p in case['panels']]}),
        }
    ext = '\n'.join(f'[ext_resource type="Resource" path="res://data/levels/{case["id"]}/{i:02d}_panel.tres" id="p{i}"]' for i in range(1, 5))
    return f'''[gd_resource type="Resource" script_class="LevelData" format=3]
[ext_resource type="Script" path="res://scripts/data/level_data.gd" id="level"]
[ext_resource type="Script" path="res://scripts/data/panel_data.gd" id="panel"]
[ext_resource type="Script" path="res://scripts/data/reaction_config.gd" id="reaction"]
[ext_resource type="Resource" path="res://data/levels/{case['id']}/comments.tres" id="comments"]
{ext}
[sub_resource type="Resource" id="Reaction"]
script = ExtResource("reaction")
[resource]
script = ExtResource("level")
id = &"{case['id']}"
title = {quoted(case['title'])}
incident = {quoted(case['incident'])}
case_number = {case['number']}
required_spun = {3 if case['number'] == 2 else 4}
panels = Array[ExtResource("panel")]([ExtResource("p1"), ExtResource("p2"), ExtResource("p3"), ExtResource("p4")])
available_tools = PackedStringArray({', '.join(quoted(t) for t in tools)})
tool_positions = {dictionary(positions)}
tool_yaws = {{"Torch": -12.0}}
tool_settings = {dictionary(settings)}
mechanic_hint = {quoted(case['hint'])}
editor_note = {quoted(case['note'])}
target_rings_default = false
subtitles = {dictionary({k: quoted(v) for k, v in {'perfect': case['perfect'], 'damning': case['damning'], 'mixed': 'HERO... OR VILLAIN?', 'murky': 'WHAT HAPPENED THAT NIGHT?', 'tampered': 'WHAT HAPPENED TO THE PRINTS?'}.items()})}
comment_templates = ExtResource("comments")
reaction_config = SubResource("Reaction")
final_case = {'true' if case['number'] == 5 else 'false'}
endings = {dictionary(endings)}
'''


def main():
    for case in CASES:
        data = ROOT / 'data/levels' / case['id']
        art = ROOT / 'Assets/evidence' / case['id']
        data.mkdir(parents=True, exist_ok=True)
        art.mkdir(parents=True, exist_ok=True)
        hs, es = (BANK_H, BANK_E) if case['number'] == 2 else (OPTIC_H, OPTIC_E)
        for i in range(4):
            (data / f'{i + 1:02d}_panel.tres').write_text(panel_resource(case, i, hs[i], es[i]))
            photo = art / f'{i + 1:02d}_panel.svg'
            if not photo.exists():
                photo.write_text(photograph(case, i, hs[i], es[i], case['panels'][i][4]))
        (data / 'comments.tres').write_text(comments_resource(case))
        (data / 'level.tres').write_text(level_resource(case))
    print('Authored 16 SVG evidence photographs and four data-only cases.')


if __name__ == '__main__':
    main()
