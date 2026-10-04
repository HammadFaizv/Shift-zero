#!/usr/bin/env python3
"""Write the authored comic text and per-hitbox reputation weights into the panel resources.

Idempotent: run it again after editing CONTENT. Unlike apply_stage_photos.py (which
regenerates generic captions), this file is the source of truth for story text.
Weights are reputation points: a hidden hitbox that shows costs them, a visible
hitbox that stays dark forgoes them. Tiers: >=3 serious, >=5 devastating.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OOPS = "Oops! This panel went up in smoke."


def panel(rationale, spun, damning, murky, comments, pois):
    """spun/damning/murky are (caption, balloon, sfx); pois is {description: (weight, [lines])}."""
    return {
        "rationale": rationale,
        "captions": {"SPUN": spun[0], "DAMNING": damning[0], "MURKY": murky[0], "TAMPERED": OOPS},
        "balloons": {"SPUN": spun[1], "DAMNING": damning[1], "MURKY": murky[1], "TAMPERED": ""},
        "sound_effects": {"SPUN": spun[2], "DAMNING": damning[2], "MURKY": murky[2], "TAMPERED": "FZZT!"},
        "comments": comments,
        "pois": pois,
    }


CONTENT = {
    "hero/01_panel": panel(
        "Nothing to hide here. A man, a cape and a lot of sky.",
        ("Captain Halcyon rises over First City, and the sun rises with him!", "Up, up and away!", "WHOOSH!"),
        ("Captain Halcyon takes to the sky.", "", "WHOOSH!"),
        ("Somewhere in the glare, our hero rises...", "", ""),
        {"SPUN": "\"Up, up and away!\" Panel {n} gave me goosebumps. That is my hero.",
         "DAMNING": "Halcyon takes to the sky in panel {n}.",
         "MURKY": "I can barely see Halcyon in panel {n}. Is he even there?"},
        {"Hero": (4, [])}),

    "fans/01_panel": panel(
        "One angry voice is not a city. Why print noise?",
        ("Captain Halcyon, loved by every citizen of First City!", "Don't thank me. It's what heroes do!", "HOORAY!"),
        ("Not everyone in First City is cheering today...", "", "BOO!"),
        ("Halcyon, loved by... somebody, somewhere in the shade.", "", ""),
        {"SPUN": "The kids cheering in panel {n} are exactly my family on a Saturday. Hero!",
         "DAMNING": "Wait, who is shouting on the left in panel {n}?",
         "MURKY": "I can't see who is cheering in panel {n}. Too dark!"},
        {"Hero": (3, []), "Cheering woman": (1, []), "Cheering man": (1, []), "Cheering child": (1, []),
         "Accusing man": (3, ["Who is the furious man on the left of panel {n}? He looks upset."]),
         "Murderer accusation": (5, ["Hold on. Does that say \"Murderer\" in panel {n}?! Who is he shouting at?"])}),

    "lake/01_panel": panel(
        "Eyes don't always catch everything. People make mistakes, even heroes.",
        ("Halcyon patrols the skies above the lake. All is calm!", "Lovely day for a flight!", "WHOOSH!"),
        ("Halcyon soars past, and the lake is not as calm as it looks.", "", "SPLASH!"),
        ("Halcyon flies somewhere over the lake... probably.", "", ""),
        {"SPUN": "\"All is calm\" over the lake in panel {n}. What a view. Thank you, Halcyon!",
         "DAMNING": "Panel {n} has a lot going on at that lake.",
         "MURKY": "Is that Halcyon over the lake in panel {n}? Can't tell."},
        {"Hero": (3, []),
         "Girl on shore": (3, ["Why is the girl on the shore in panel {n} pointing at the water? Did she call to him?"]),
         "Drowning woman": (6, ["Is that a person waving for help in the water in panel {n}?! And Halcyon just flies on?"])}),

    "peace/01_panel": panel(
        "A cop on the beat, a hero overhead. Nothing here needs hiding.",
        ("Halcyon patrols above. The police keep the peace.", "Stay safe down there!", "SWOOSH!"),
        ("A quiet street in First City.", "", ""),
        ("A quiet street, and nobody quite visible...", "", ""),
        {"SPUN": "Halcyon and the police working together in panel {n}. This is why I feel safe.",
         "DAMNING": "A quiet street in panel {n}.",
         "MURKY": "Panel {n} is too dark. Where are the police?"},
        {"Hero": (2, []), "Officer": (1, []), "Civilian": (1, [])}),

    "peace/02_panel": panel(
        "Chaos at the scene. A hero's name shouldn't get tangled in someone else's mistake.",
        ("Another dangerous criminal stopped by Halcyon!", "Justice is served.", "BAM!"),
        ("A very tense moment on the street...", "", "BANG!"),
        ("Something happened here, but the light has gone.", "", ""),
        {"SPUN": "\"Justice is served.\" Panel {n} is why I trust Halcyon.",
         "DAMNING": "Panel {n} is really tense. What happened?",
         "MURKY": "I can't make out panel {n} at all."},
        {"Hero": (2, []), "Dead civilian": (1, []),
         "Officer": (4, ["Why is the officer in panel {n} holding a gun over that man?"]),
         "Officer dialogue": (3, ["\"He was just a civilian\"?! Who said that in panel {n}?"])}),

    "rescue/01_panel": panel(
        "Fires start all the time. Who was standing nearby is nobody's business.",
        ("A fire in First City! Brave citizens call for help!", "Somebody, help!", "CRACKLE!"),
        ("The fire starts, and so does a bright beam from the sky.", "", "ZZZAP!"),
        ("Something is burning in the dark...", "", ""),
        {"SPUN": "\"Somebody, help!\" Panel {n} had me shaking. Where is Halcyon?!",
         "DAMNING": "What is that red line pointing at the burning building in panel {n}?",
         "MURKY": "I can't tell what is burning in panel {n}."},
        {"Hero": (6, ["Wait. Is Halcyon shooting a laser AT the building in panel {n}?!"]),
         "Witness": (1, []), "Burning building": (1, [])}),

    "rescue/02_panel": panel(
        "One child saved is the story. The rest is smoke.",
        ("Halcyon saves a child from the flames!", "You're safe now, little one.", "SAVED!"),
        ("The rescue was a success. Mostly.", "", "..."),
        ("Halcyon carries someone out of the dark...", "", ""),
        {"SPUN": "A rescued child in panel {n}. I am sobbing. This is why we love him.",
         "DAMNING": "Panel {n} has more going on than the caption says.",
         "MURKY": "I can barely see the rescue in panel {n}."},
        {"Hero": (2, []), "Rescued child": (1, []),
         "Dead witness": (4, ["Who is lying by the rubble in panel {n}? Is that the man from panel 1?"])}),

    "robbery/01_panel": panel(
        "Runaway cars happen. Nobody needs to know where this one came from.",
        ("A runaway car hits First City Bank!", "", "KRAKA-BOOM!"),
        ("Panic at the bank. Halcyon is right there.", "Ha! Too slow!", "KRAKA-BOOM!"),
        ("Something crashes into the bank in the dark...", "", ""),
        {"SPUN": "A runaway car in broad daylight in panel {n}?! Terrible. Glad help is coming.",
         "DAMNING": "Panel {n} is chaos outside the bank.",
         "MURKY": "I can't see what hit the bank in panel {n}."},
        {"Hero": (5, ["Is Halcyon... THROWING that car in panel {n}?!"]),
         "Fleeing man": (1.5, ["Why is everyone in panel {n} running from the bank?"]),
         "Fleeing woman": (1.5, []),
         "Fleeing child": (2, ["A child is running for their life in panel {n}. From what?"]),
         "Car hitting bank": (1, [])}),

    "robbery/02_panel": panel(
        "Vaults crack. Old steel, bad day. A hole is just a hole.",
        ("The vault is open. Too late for the guard!", "I'll find whoever did this.", "GRRR!"),
        ("The vault door looks... oddly fist-shaped.", "", "KRAKA-BOOM!"),
        ("Halcyon stands in the dark by the vault...", "", ""),
        {"SPUN": "\"I'll find whoever did this.\" Panel {n} says it all. He really is our hero.",
         "DAMNING": "Panel {n}: what a strange hole.",
         "MURKY": "Panel {n} is too dark to read."},
        {"Hero": (2, []), "Dead guard": (1, []),
         "Broken bank vault": (3, ["Why is the hole in the vault exactly fist-shaped in panel {n}?"])}),

    "robbery/03_panel": panel(
        "A man leaning on a desk. A shadow is just a shadow.",
        ("The manager gives his statement.", "Thank goodness Halcyon came!", "SIGH..."),
        ("The manager looks very nervous.", "", "GULP!"),
        ("The manager waits, hard to see.", "", ""),
        {"SPUN": "\"Thank goodness Halcyon came!\" The manager in panel {n} says it for all of us.",
         "DAMNING": "The manager in panel {n} looks terrified. Of what?",
         "MURKY": "I can't see the manager in panel {n}."},
        {"Hero head": (5, ["Is Halcyon... grabbing the manager in panel {n}?!"]),
         "Hero dialogue": (4, ["\"Better not speak\"?! Who is saying that to the manager in panel {n}?"]),
         "Manager": (1, [])}),

    "robbery/04_panel": panel(
        "Wind, confetti, paper. Some things just fall from the sky.",
        ("The robbers flee! Halcyon is right behind them!", "Stop right there, robbers!", "ZOOM!"),
        ("Is it raining money over First City?", "See ya, suckers!", "FLUTTER!"),
        ("Someone flies over the rooftops in the dark.", "", ""),
        {"SPUN": "Halcyon chasing the robbers over the rooftops in panel {n}. What a pursuit!",
         "DAMNING": "Why is money falling out of the sky behind Halcyon in panel {n}?",
         "MURKY": "I can't see anyone in panel {n}."},
        {"Hero": (3, []),
         "Falling bill 1": (0.6, ["Why is money falling out of the sky in panel {n}?"]),
         "Falling bill 2": (0.6, []),
         "Falling bill 3": (0.6, ["Panel {n}: those are dollar bills falling behind Halcyon. Just saying."]),
         "Falling bill 4": (0.6, []), "Falling bill 5": (0.6, [])}),

    "greatest/01_panel": panel(
        "Heroes fight bad guys. Collateral is never the headline.",
        ("Halcyon charges into danger!", "First City can count on me.", "WHOOSH!"),
        ("A mighty blast tears through the street.", "", "KRAKA-BOOM!"),
        ("Where did our hero go?", "", ""),
        {"SPUN": "\"First City can count on me.\" I do count on him. Panel {n}!",
         "DAMNING": "Panel {n}: that is a lot of damage for a rescue.",
         "MURKY": "Panel {n} is too dark to read."},
        {"Hero": (3, []),
         "Attack": (4, ["Why is Halcyon blasting the street in panel {n}?"]),
         "Damage": (3, ["That building in panel {n} is in pieces. What happened?"])}),

    "greatest/02_panel": panel(
        "People run when they're scared. It doesn't say who scared them.",
        ("Civilians escape as Halcyon holds the line!", "Everyone's safe!", "SAFE NOW!"),
        ("The crowd runs. Nobody looks safe.", "", "SCREAM!"),
        ("Footsteps in the dark. Is anyone there?", "", ""),
        {"SPUN": "\"Everyone's safe!\" Panel {n} is why my kids look up to him.",
         "DAMNING": "Panel {n}: the crowd looks terrified.",
         "MURKY": "I can't see anyone in panel {n}."},
        {"Hero": (3, []),
         "Fleeing": (4, ["Why are they running away from him in panel {n}?"]),
         "Injured": (5, ["There is someone on the ground in panel {n}. Is nobody helping?"])}),

    "greatest/03_panel": panel(
        "He's standing in the ruins like a hero. The rest is background.",
        ("Halcyon stands tall over the aftermath.", "Another day saved.", "STAND TALL!"),
        ("The smoke clears. Nobody looks safe.", "", "CRUMBLE..."),
        ("Smoke, shadows and somebody standing in them.", "", ""),
        {"SPUN": "\"Another day saved.\" Panel {n} made me tear up. Best hero ever.",
         "DAMNING": "Panel {n}: the whole street is wrecked.",
         "MURKY": "Panel {n} is too dark. What am I looking at?"},
        {"Hero": (3, []),
         "Witnesses": (3, ["Why are the people in panel {n} pointing at him?"]),
         "Victims": (5, ["Is that a body in panel {n}? Where are the medics?"]),
         "Police": (3, ["The police are in panel {n} too. Why do they look so grim?"]),
         "Damage": (3, ["That car in panel {n} is flattened. Who did that?"])}),
}


def q(value):
    return json.dumps(value, ensure_ascii=False)


def apply(path_key, spec):
    path = ROOT / "data/levels" / (path_key + ".tres")
    text = path.read_text()
    # PanelData dictionaries and the rationale. Blocks may be single-line or multi-line.
    for key in ("captions", "balloons", "sound_effects", "comments"):
        block = re.compile(rf"^{key} = \{{.*?\}}[ \t]*$", re.S | re.M)
        if not block.search(text):
            raise SystemExit(f"{path_key}: missing {key}")
        text = block.sub(lambda _m, key=key: f"{key} = {q(spec[key])}", text, count=1)
    text = re.sub(r"^rationale = .*\n?", "", text, flags=re.M)
    text = text.rstrip("\n") + f"\nrationale = {q(spec['rationale'])}\n"
    # POI weights and exposure lines.
    seen = set()

    def poi(match):
        body = match.group(0)
        desc = re.search(r'^description = "(.*)"$', body, re.M)
        if not desc:
            return body
        name = desc.group(1)
        weight, lines = spec["pois"][name]
        seen.add(name)
        body = re.sub(r"^importance = .*\n?", "", body, flags=re.M)
        body = re.sub(r"^comment_lines = .*\n?", "", body, flags=re.M)
        body = body.rstrip("\n") + f"\nimportance = {float(weight)}\n"
        if lines:
            body += f"comment_lines = PackedStringArray({', '.join(q(line) for line in lines)})\n"
        return body

    text = re.sub(r"\[sub_resource type=\"Resource\" id=\"[^\"]+\"\]\n.*?(?=\n\[sub_resource|\n\[resource\])", poi, text, flags=re.S)
    missing = set(spec["pois"]) - seen
    if missing:
        raise SystemExit(f"{path_key}: POIs not found: {missing}")
    path.write_text(text)


for key, spec in CONTENT.items():
    apply(key, spec)
print(f"Authored {len(CONTENT)} panels.")
