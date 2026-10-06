#!/usr/bin/env python3
"""Adds reader reactions to the eight campaign cases (safe to re-run).

* POI `reply_lines`:  a Halcyon fan answering the comment about an exposed hitbox.
* POI `praise_lines`: a comment when Halcyon himself is lit and readable.
* POI `comment_lines`: only for exposed hitboxes that had no authored line yet.
* comments.tres: extra generic fan/skeptic comments and the page-wide comments.

{n} is replaced by the panel number at runtime. Existing comment_lines written by
author_content.py are never touched.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def q(value):
    return json.dumps(value, ensure_ascii=False)


# (case folder, panel file number) -> hitbox description -> {comment, reply, praise}
POIS = {
    ("hero", "01"): {
        "Hero": {"praise": ["That is a hero. Perfectly lit, perfectly Halcyon.", "Captain Halcyon looks magnificent in panel {n}!"]},
    },
    ("fans", "01"): {
        "Hero": {"praise": ["There he is. Halcyon with the whole square cheering. Panel {n} is gold."]},
        "Accusing man": {"reply": ["That man is angry at the wrong person. Ask the crowd who actually shows up for them."]},
        "Murderer accusation": {"reply": ["Anyone can shout a word. Shouting is not proof. Halcyon has never hurt anyone."]},
    },
    ("fans", "02"): {
        "Hero": {"praise": ["The fans got their photo in panel {n}. Halcyon looks as humble as ever."]},
        "Crowd": {"comment": ["Why is the crowd in panel {n} packed so tightly? Is anyone checking on them?"],
                  "reply": ["They are cheering, not trapped. Not everything is a scandal."]},
    },
    ("lake", "01"): {
        "Hero": {"praise": ["Halcyon over the lake in panel {n}: serene, strong, watching over us."]},
        "Girl on shore": {"reply": ["A girl waves at a passing hero. Children wave at heroes. That is all."]},
        "Drowning woman": {"reply": ["He could not see everything from that height. He is one man, give him a break."]},
    },
    ("peace", "01"): {
        "Hero": {"praise": ["Panel {n}: Halcyon standing with First City's police. This is what trust looks like."]},
    },
    ("peace", "02"): {
        "Hero": {"praise": ["Halcyon in panel {n}: calm, composed, in control."]},
        "Officer": {"reply": ["The officer was doing his job in a dangerous moment. Halcyon was not holding that gun."]},
        "Officer dialogue": {"reply": ["You are quoting one line from a shouting match. Wait for the full story."]},
    },
    ("rescue", "01"): {
        "Hero": {"reply": ["He is cutting through a wall so people can get out. Read the next panel before you judge."]},
    },
    ("rescue", "02"): {
        "Hero": {"praise": ["Panel {n}: Halcyon carrying a child out of the fire. I'm crying."]},
        "Dead witness": {"reply": ["Not everyone could be saved. Halcyon carries that, so don't pile on."]},
    },
    ("robbery", "01"): {
        "Hero": {"reply": ["He stopped a getaway car. Throwing it away from the people is the heroic version."]},
        "Fleeing man": {"reply": ["People run from danger. Halcyon runs toward it."]},
        "Fleeing woman": {"comment": ["That woman in panel {n} is sprinting away from the bank. From what, exactly?"],
                          "reply": ["From the robbers. Halcyon is the reason she got out safe."]},
        "Fleeing child": {"reply": ["The child ran to safety. The bank was the danger, not the hero."]},
    },
    ("robbery", "02"): {
        "Hero": {"praise": ["Panel {n}: the vault is open and Halcyon is in control. What a pro."]},
        "Broken bank vault": {"reply": ["Do you know what it takes to open a vault from outside? Thank goodness he stopped them."]},
    },
    ("robbery", "03"): {
        "Hero head": {"reply": ["He is stopping the manager from running into danger. Look at the care in his hands."]},
        "Hero dialogue": {"reply": ["Nobody is threatening anyone. \"Better not speak\" means stay safe."]},
    },
    ("robbery", "04"): {
        "Hero": {"praise": ["Panel {n}: Halcyon chasing the getaway. Nobody escapes on his watch."]},
        "Falling bill 1": {"reply": ["Money flies when robbers panic. Halcyon did not take a cent."]},
        "Falling bill 2": {"comment": ["More banknotes in panel {n}. That's a lot of cash for a rescue."],
                           "reply": ["It is the bank's money, and Halcyon returned every bill."]},
        "Falling bill 3": {"reply": ["Cash falling from a bag the robbers dropped. Obviously."]},
        "Falling bill 4": {"comment": ["Panel {n}: a fourth banknote. I'm counting, even if the editor isn't."],
                           "reply": ["Counting banknotes while he is saving lives? Priorities."]},
        "Falling bill 5": {"comment": ["Is that bill in panel {n} falling out of Halcyon's cape?"],
                           "reply": ["Out of the robbers' bag. Read the caption."]},
    },
    ("protest", "01"): {
        "Hero": {"praise": ["Panel {n}: Halcyon watching over the gathering. Steady as ever."]},
        "Protesters": {"reply": ["People are allowed to gather. Halcyon is protecting that right."]},
        "Protest signs": {"reply": ["Everyone has opinions. Halcyon still keeps the square safe for them."]},
        "Protesting crowd": {"reply": ["A huge crowd and not one injury. Thank Halcyon."]},
    },
    ("protest", "02"): {
        "Hero": {"praise": ["Panel {n}: Halcyon making space for the people. A hero for everyone."]},
        "Citizen crushed by car": {"reply": ["Halcyon arrived after the car did. He is the one pulling people out."]},
    },
    ("protest", "03"): {
        "Hero": {"praise": ["Halcyon walking with the people in panel {n}. This is what leadership looks like."]},
        "Running citizen 1": {"reply": ["People ran, Halcyon stayed. That is the difference."]},
        "Running citizen 2": {"reply": ["Panic is human. Halcyon's calm is why nobody got hurt."]},
    },
    ("protest", "04"): {
        "Hero": {"praise": ["Panel {n}: Halcyon holding the line between the crowd and the police. Cool as ice."]},
        "Police officers": {"comment": ["Why are there so many police in panel {n}? Was the square under siege?"],
                            "reply": ["Halcyon is the one standing between them and the crowd. Thank him."]},
        "Nurse": {"reply": ["A nurse helping a stranger. That is who Halcyon inspires."]},
        "Dead citizen": {"reply": ["A tragedy Halcyon tried to stop. Show some respect."]},
    },
    ("protest", "05"): {
        "Hero": {"praise": ["Panel {n}: Halcyon on watch in the wreckage. First City can rest."]},
        "Destroyed car 1": {"reply": ["Cars are replaceable. Halcyon made sure people were not."]},
        "Destroyed car 2": {"reply": ["Insurance covers cars. Nothing covers what Halcyon saved."]},
        "Rubble": {"reply": ["Rubble is just rubble. Halcyon stayed to help dig through it."]},
    },
    ("protest", "06"): {
        "Hero": {"praise": ["Panel {n}: Halcyon still standing, still keeping the peace."]},
        "Police hitting citizens": {"reply": ["Halcyon had nothing to do with what the police did. He was not giving orders."]},
        "Citizen being hit": {"reply": ["He tried to shield them. Don't turn this on him."]},
        "Fleeing citizen": {"reply": ["Running from the police, not from Halcyon. Notice the difference."]},
        "Fallen citizen": {"reply": ["He is the one carrying people out. Show some gratitude."]},
    },
    ("factory", "01"): {
        "Hero": {"praise": ["Panel {n}: Halcyon inspects the factory. Always one step ahead."]},
        "Factory": {"comment": ["Is that the Reckon factory in panel {n}? Who signed off on its safety checks?"],
                    "reply": ["Halcyon is the only one who actually inspected it."]},
    },
    ("factory", "02"): {
        "Hero": {"praise": ["Panel {n}: safety first, hero always. Halcyon never cuts corners."]},
        "Oil cans": {"reply": ["Halcyon warned them about that oil. Ask the factory owners."]},
        "Oil spill": {"reply": ["He is the one who told them to clean it up!"]},
        "Lighter": {"reply": ["Who left that lighter there? Not Halcyon, that's for sure."]},
    },
    ("factory", "03"): {
        "Hero": {"praise": ["Panel {n}: Halcyon with the workers. They love him for a reason."]},
        "Worker 1": {"reply": ["Workers trust Halcyon. Look how safe they feel with him there."]},
        "Worker 2": {"reply": ["He showed up when management did not."]},
    },
    ("factory", "04"): {
        "Hero": {"praise": ["Panel {n}: Halcyon in the response. Steady hands in a hard moment."]},
        "Dead worker 1": {"reply": ["A tragedy. Halcyon did everything he could, so don't make it worse."]},
        "Dead worker 2": {"reply": ["Blame the factory owners, not the man who ran in to help."]},
    },
    ("factory", "05"): {
        "Hero": {"praise": ["Panel {n}: Halcyon rises above it all. That is a hero's silhouette."]},
        "Ruined factory": {"reply": ["A factory can be rebuilt. The people Halcyon saved can't be replaced."]},
        "Rubble left": {"reply": ["He pulled people out of that rubble with his own hands."]},
        "Rubble right": {"reply": ["Anything to blame Halcyon, huh? He was the first one there."]},
    },
}

SHARED_FANS = [
    "Best edition this week. Halcyon, the city is yours.",
    "I cut this page out for my fridge.",
    "Say what you like, First City is safer with him in it.",
    "My whole street is reading this together. Thank you, Halcyon!",
]
SHARED_SKEPTICS = [
    "Is it just me, or is something missing from these photos?",
    "Why does the editor keep zooming in on certain panels?",
    "I would like to see the unedited prints.",
]

# case folder -> page-wide comments (shown when most panels shine / when anything is showing)
LEVELS = {
    "hero": {"praise": "Halcyon's torchlight is the only light First City needs. Great edition!",
             "critic": "Why is the hero so hard to read here? Is something being hidden?",
             "reply": "A dark photo is not a conspiracy. Print another!",
             "fans": ["Captain Halcyon, always in the right light."], "skeptics": ["Is that really the whole photograph?"]},
    "fans": {"praise": "The People's Hero lives up to the name: the crowd, the cheer, the Captain. Perfect!",
             "critic": "There is something odd in these photos. Look closer, everyone.",
             "reply": "Do not invent trouble. Halcyon has always been the people's hero.",
             "fans": ["The crowd in panel 2 says it all."], "skeptics": ["Who was that man shouting in the crowd?"]},
    "lake": {"praise": "A calm lake and a calmer hero. The skies are in good hands.",
             "critic": "The lake is not as calm as the caption says. Look at the water.",
             "reply": "He cannot be everywhere. He has stopped more than he has missed.",
             "fans": ["Nothing says safe like Halcyon overhead."], "skeptics": ["Why does the caption say calm when I see splashing?"]},
    "peace": {"praise": "A hero and the police on the same page. This is how a city stays safe.",
              "critic": "Something is wrong in the second print. Why is no one saying it?",
              "reply": "You are reading a tense moment as a crime. Halcyon kept the peace.",
              "fans": ["Keeping the peace, one panel at a time."], "skeptics": ["Why was the officer's gun in the shot?"]},
    "rescue": {"praise": "The Rescue is the best comic we have had. Halcyon runs into fire so we don't have to.",
               "critic": "The prints do not match the caption. Check the fire again.",
               "reply": "He saved a child from a burning building. Show some decency.",
               "fans": ["A hero in the flames. I'm still shaking."], "skeptics": ["Why is a witness lying near the rubble?"]},
    "robbery": {"praise": "The bank is safe and the hero is smiling. Three cheers for Halcyon!",
                "critic": "A bank, a manager, a vault. Why does the story keep changing?",
                "reply": "The robbers changed the story. Halcyon only ever ended it.",
                "fans": ["He stopped a bank robbery before breakfast."], "skeptics": ["Why is there so much money in the air?"]},
    "protest": {"praise": "A steady hand for First City. Halcyon kept every voice safe in Assembly Square.",
                "critic": "Look at what is left in the square. Is this really a calm day?",
                "reply": "Halcyon was there to keep the peace. You were not.",
                "fans": ["Halcyon stood with the people and the people stood with him."], "skeptics": ["Why was the square so full of police?"]},
    "factory": {"praise": "Safety first, hero always. Halcyon's inspection saved the Reckon factory!",
                "critic": "A factory like that does not look safe. Who is checking?",
                "reply": "Halcyon is the one who checked. Where were the owners?",
                "fans": ["Halcyon never cuts corners."], "skeptics": ["Why does the factory look so run-down?"]},
}


def read(path):
    return path.read_text()


def apply_panel(case, number, specs):
    path = ROOT / "data/levels" / case / f"{number}_panel.tres"
    text = read(path)
    seen = set()

    def poi(match):
        body = match.group(0)
        desc = re.search(r'^description = "(.*)"$', body, re.M)
        if not desc or desc.group(1) not in specs:
            return body
        name = desc.group(1)
        spec = specs[name]
        seen.add(name)
        body = re.sub(r"^(reply_lines|praise_lines) = .*\n?", "", body, flags=re.M)
        body = body.rstrip("\n") + "\n"
        if "comment" in spec:
            line = f"comment_lines = PackedStringArray({', '.join(q(line) for line in spec['comment'])})\n"
            if "comment_lines = " in body and line not in body:
                raise SystemExit(f"{case}/{number}: {name} already has a different comment line")
            if line not in body:
                body += line
        if "reply" in spec:
            body += f"reply_lines = PackedStringArray({', '.join(q(line) for line in spec['reply'])})\n"
        if "praise" in spec:
            body += f"praise_lines = PackedStringArray({', '.join(q(line) for line in spec['praise'])})\n"
        return body

    text = re.sub(r"\[sub_resource type=\"Resource\" id=\"[^\"]+\"\]\n.*?(?=\n\[sub_resource|\n\[resource\])", poi, text, flags=re.S)
    missing = set(specs) - seen
    if missing:
        raise SystemExit(f"{case}/{number}: hitboxes not found: {missing}")
    path.write_text(text)


def apply_comments(case, spec):
    path = ROOT / "data/levels" / case / "comments.tres"
    text = read(path)
    for key in ("fan_comments", "skeptic_comments"):
        match = re.search(rf"^{key} = PackedStringArray\((.*)\)$", text, re.M)
        existing = json.loads("[" + match.group(1) + "]")
        base = [line for line in existing if line not in SHARED_FANS + SHARED_SKEPTICS + spec["fans"] + spec["skeptics"]]
        extra = (SHARED_FANS + spec["fans"]) if key == "fan_comments" else (SHARED_SKEPTICS + spec["skeptics"])
        text = text.replace(match.group(0), f"{key} = PackedStringArray({', '.join(q(line) for line in base + extra)})")
    text = re.sub(r"^(page_praise|page_critic|page_critic_reply) = .*\n?", "", text, flags=re.M)
    text = text.rstrip("\n") + f"\npage_praise = {q(spec['praise'])}\npage_critic = {q(spec['critic'])}\npage_critic_reply = {q(spec['reply'])}\n"
    path.write_text(text)


for (case, number), specs in POIS.items():
    apply_panel(case, number, specs)
for case, spec in LEVELS.items():
    apply_comments(case, spec)
print("Reactions authored for", len(LEVELS), "cases")
