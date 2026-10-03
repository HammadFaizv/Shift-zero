# Steps 11–15: optics, the five-case campaign and endings

All five cases now play through the same desk → publish → comic/reaction →
return loop. **NEXT CASE** is available after every publication, including a
bad edition; spin goals grade the result rather than blocking the story.
The final case offers **PUBLISH EDITED STORY** and **PUBLISH ORIGINAL PHOTOS**.
Each has its own headline, comic-panel captions, ending text and comments.

The earlier low, narrow torch, 24° angled camera and green ceiling fixture
are retained. The existing bank case still uses the torch replacement requested
earlier, rather than reintroducing the broad desk lamp.

## Mechanics

- **Torch:** source GLB, drag, Q/E or wheel, Space/double-click, plus a projected
  gold handle that can be dragged to aim continuously. A factory test lights
  one hero while leaving its neighbour below 30%. Paperweights block the beam.
- **Reading glasses:** draggable/rotatable frames receive direct torch or
  ceiling light and emit a controlled beam along their facing direction.
  A translucent green guide shows the outgoing cone. Paperweights block it.
  Glasses cannot power one another: there is one redirect per direct source.
- **Magnifier:** the supplied GLB is centred on its actual lens. Its translucent
  lens receives direct or redirected light and adds a small circular boost.
  Its rim does not create gameplay occlusion. The museum's weak reflected beam
  is capped in level data and needs the magnifier to light its fourth hero in
  the recorded solution.
- **Heat:** incoming light at least 1.1 starts a 2.5-second stillness timer.
  Movement, rotation or dim light resets it. A glowing spot, smoke, desk label
  and readable screen-space **TOO HOT — MOVE IT!** warning appear before burning.
  Scorches persist through publishing and returning. **RESTART CASE** resets
  tool positions and damage.
- **Burned evidence:** a scorch never reduces the light evaluator's reading.
  Burned POIs cannot make a photo SPUN. Museum/train data checks burns first,
  so any burned photo is TAMPERED even when other evidence is exposed.
  Other cases retain their existing rule priority.

`light_at(point)` remains the single entry point for POIs, preview and edited
publication. It adds direct, redirected and focused contributions with the
same physics occlusion checks. The order is direct → glasses → magnifier;
there is no optical feedback loop. POIs refresh before panel interpretation,
which also works after replacing a case's POI nodes.

Burns live in runtime panel data as photo-UV centres and world radii. The desk
and comic receive matching burn masks. Source textures remain intact.
Original-photo publication uses the source textures fully visible, without
ink, scorch overlays, colour filtering or invented balloons/effects. It does
not erase damage to the copies on the desk.

## Cases and working solutions

All positions below are **tool-root world X/Z** coordinates. Drag support
automatically sets height. Root yaw 0° faces right (+X); −90° faces toward the
bottom of the page (+Z). Switch the ceiling **off** for each solution and keep
the torch(es) on. The gold aim handle allows exact directions between wheel
steps.

| Case | Tools and introduction | Goal |
| --- | --- | --- |
| 1 Bank robbery | Torch replacement and two paperweights; original bank content | 3/4 |
| 2 Factory fire | Two narrow torches isolate separate rows | 3/4 |
| 3 City protest | One upright torch beam and reading glasses | 4/4 |
| 4 Museum incident | Weak reflected light needs magnifier focus; introduces heat | 4/4 |
| 5 Train disaster | All introduced tool types; final publishing decision | 4/4 |

1. **Bank:** torch **(−4.7, 0.15), yaw 0°**; paperweight **(1.18, −1.245)**;
   second weight **(1.18, 1.6675)**. The outer evidence falls outside the beam;
   the weights hide the vault and cash.
2. **Factory:** first torch **(−4.7, −0.5625), yaw 0°**; second torch
   **(−4.7, 0.855), yaw 0°**. Use the same weight positions as the bank.
   The top and bottom hero pairs receive separate 10° beams.
3. **Protest:** torch **(−0.3, −3.7), yaw −90°**; glasses **(−0.15, 1.7),
   yaw 0°**. The direct beam catches the three inner heroes and powers the
   glasses. Their outgoing beam reaches the lower-right hero. Weights may
   stay at their initial positions.
4. **Museum:** the same torch/glasses poses, plus magnifier lens centre
   **(1.4825, 1.71625), yaw 0°**. The reflected input is weak enough to avoid
   heat and strong enough for the focus boost.
5. **Train:** use the museum arrangement. Publish, then choose either edition.

All five arrangements were verified as **4/4 SPUN**, all evidence at the
ambient **0.05**, and **ADORING 100/100** for their edited publications.
Protest hero readings are about 0.624 / 0.624 / 1.0 / 0.687; museum/train
readings are about 0.624 / 0.624 / 1.0 / 0.680. Turning or removing the glasses
loses the fourth protest hero; removing the magnifier loses the fourth hero
in the museum and train arrangements. These are recorded physical solutions,
not a claim that every alternative arrangement has been exhaustively searched.

The new photos use the same **768×640** texture size. Their POI positions,
pixel coordinates and radii are in [campaign-pois.md](campaign-pois.md).
Content and tool tuning live in the individual level Resources, so loading a
new case needs no case-specific rules in the game systems.

## Controls and testing

Run with **F5**. **L/red cord** toggles the ceiling. **Left-drag** moves a tool;
**Q/E**, **wheel**, or the **gold handle** rotates it. **Space/double-click**
toggles the selected torch. **Esc/right-click** deselects. The target checkbox
enables POI rings; cases 2–5 start with them off. **F1** shows light readings.
**RESTART CASE** clears the current attempt, including scorches. Publish any
edition, use **Replay printing**, **BACK TO THE DESK** or **NEXT CASE**.
At the train case, the final-choice dialog also lets you keep working.
Both endings allow returning to the train or **START AGAIN** at the bank.

```sh
# Godot 4.7.2; use your executable path if Godot is not on PATH.
godot --headless --path . --script tests/vertical_slice.gd
godot --headless --path . --script tests/campaign.gd
# Rendered campaign previews, using a fixed simulation timestep:
godot --path . --fixed-fps 60 --script tests/campaign.gd

# After campaign.gd generates /tmp/shift-zero-campaign-inputs.json:
python3 tools/serve_web.py
WEB_GPU=hardware NODE_PATH=/tmp/shift-zero-browser/node_modules node tests/web_campaign.cjs
```

Headless and rendered tests verify all five solutions, loading fresh POIs,
camera framing, redirected-ray occlusion and rotation, required focus, modal
choice/cancel, warning before burning, movement reset, permanent damage,
burned-hero/evidence rejection, frozen comic burns, both endings and restarting.
The bank regression additionally checks shared light samples, actual controls,
return poses and desktop resizing. Chrome exercises the release through real
drags, the rotation handle, case transitions, replay/return, real-time heat and
both final choices. See [Web export](web-export.md) for the release and timings.

## Files and scene trees

New files:

- `scripts/lighting/redirector.gd`, `focuser.gd`.
- `scripts/tools/reading_glasses.gd`, `magnifying_glass.gd`.
- `scripts/ui/rotation_handle.gd`, `heat_warning.gd`, `final_choice_ui.gd`.
- `scenes/tools/reading_glasses.tscn`, `magnifying_glass.tscn`;
  `scenes/ui/final_choice.tscn`.
- `data/levels/{factory,protest,museum,train}/`: four panel Resources,
  comment templates and LevelData per case.
- `Assets/evidence/{factory,protest,museum,train}/`: sixteen editable SVGs.
- `tools/build_campaign_content.py`: optional authoring helper; regenerating
  overwrites these new case Resources/SVGs, so preserve manual edits first.
- `tests/campaign.gd`, `tests/web_campaign.cjs`, these notes, POI inventory
  and campaign previews.

Changed: `scenes/main.tscn`; game/level managers; panel/level data; evidence
panel/POI scripts; light evaluator and ink preview; comic renderer/result UI;
story/targets/debug UI; dragging/interaction; both ink shaders; tuning helper;
the bank regression; export preset; README, credits, tuning and Web notes.
The Web build and ZIP were rebuilt; generated imports/UIDs accompany assets.

```text
ReadingGlasses (Node3D)
├── LeftFrame / RightFrame (TorusMesh)
├── LeftLens / RightLens (transparent CylinderMesh)
├── Bridge / LeftTemple / RightTemple
├── Receiver (Node3D)
├── Beam / VisualLight (SpotLight3D)
├── BeamGuide (MeshInstance3D)
├── PickBody / CollisionShape3D
├── Draggable / Rotatable
└── Redirector (Node3D)

MagnifyingGlass (Node3D)
├── Model (supplied GLB, lens centred at runtime)
├── Receiver (Node3D)
├── FocusSpot (MeshInstance3D)
├── Warning (Label3D)
├── PickBody / CollisionShape3D
├── Draggable / Rotatable
├── Focuser (Node3D)
└── Three smoke meshes (created at runtime)

FinalChoice (Control)
├── Scrim (ColorRect, captures desk mouse input)
└── Panel / Column (created at runtime)
    ├── Deadline / heading / explanation
    ├── Publish edited story
    ├── Publish original photos
    └── Keep working at the desk
```

Main also gains Torch2, both optical tools, RotationHandle and HeatWarning.
The existing result scene displays both endings; there is no separate ending
scene to duplicate the comic/social-feed system.

## Previews and remaining work

[Factory](previews/campaign-factory.png), [protest](previews/campaign-protest.png),
[museum](previews/campaign-museum.png), [train](previews/campaign-train.png),
[heat warning](previews/campaign-heat.png), [scorch](previews/campaign-burn.png),
[final choice](previews/campaign-choice.png),
[edited ending](previews/campaign-ending-edited.png), and
[original ending](previews/campaign-ending-original.png).

Inspector tuning, including each case's tool overrides, is collected in
[tuning.md](tuning.md). The new artwork remains simple replaceable illustration.
Campaign progress is in memory for this play session. Audio and the title,
level-select/settings/credits polish remain **Steps 16–17**; no new audio was
added in this batch. Desktop mouse/keyboard controls remain required.
