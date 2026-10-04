# First seven cases

Stages 1–6 now use the supplied PNGs in `Assets/evidence_assets/stages`.
Stage 7 retains its existing three SVG photographs and tools.

| Stage | Photos / layout | Visible subjects | Hidden subjects | Available tools |
| --- | --- | --- | --- | --- |
| 1 — The Hero | 1, centered | Hero | None | One torch |
| 2 — The People's Hero | 1, centered | Hero and three cheering people on the right | Left man and murderer accusation | One torch |
| 3 — Above the Lake | 1, centered | Hero | Shore girl and drowning woman | One torch, one paperweight |
| 4 — Keeping the Peace | 2, side by side | Photo 1: hero, cop, civilian. Photo 2: hero, dead civilian | Photo 2: cop and his dialogue | One torch, one pair of reading glasses |
| 5 — The Rescue | 2, side by side | Photo 1: witness and burning building. Photo 2: hero and child | Photo 1: hero. Photo 2: dead witness | One torch, one magnifying glass |
| 6 — The Bank | 4, 2 × 2 | Photo 1: car hitting bank. Photo 2: hero and dead guard. Photo 3: manager. Photo 4: hero | Photo 1: hero and three people. Photo 2: vault. Photo 3: hero head and dialogue. Photo 4: five falling bills | Two torches |
| 7 — Our Greatest Hero | 3, existing layout | Existing hero targets | Existing crime evidence | Existing desk lamp, two torches, three paperweights |

Every stage also provides the ceiling light, initially off.
Stage 6 provides two torches for four prints, plus the ceiling inspection light. Players may accept an imperfect
page and choose which crime evidence to expose to minimize damage. Publishing
an imperfect page still permits progression.

PNG proportions are preserved on the desk and in the published comic.
Each active photo has hand-placed circular evidence targets. See the
[hitbox preview](previews/stage-photo-hitboxes.png) and
[coordinates and radii](stage-photo-pois.md). Hidden targets have to read below
0.30 light; required visible targets need at least 0.55. A hero may itself be
hidden when the assignment calls for it. Burns still count as tampering.
Every perfect page scores 100, including the new one-photo stage 2 and
four-photo stage 6. Unused slots and tools are disabled when switching stages.

Press **F5** to play. Drag tools with the left mouse button. **Q/E**, the wheel,
or the aim handle rotates a selected torch or the glasses. **Space** or a
double-click switches the torch. The target checkbox shows evidence circles.
**Publish** prints the current lighting; **Back to desk** returns to the puzzle;
**Next case** advances; **Restart case** resets that stage. The ceiling light is available in every stage: **L** or its pull cord
illuminates the whole page for inspection; switch it off to shape the print. Glasses receive and redirect light; the magnifier
boosts light at its lens and can scorch a print if held in strong light.

No new scene is added: the existing four photo slots now accommodate the bank
page. Modified stage resources are under `data/levels/{hero,fans,lake,peace,rescue,robbery}`;
the comic aspect ratio is updated in `scripts/ui/comic_result_ui.gd`.

## Authoring and verification

`tools/apply_stage_photos.py` reproduces the PNG resources, loadouts, layouts,
reward normalization, hitbox table and annotated preview. It requires Pillow.
If regenerating the historical SVG data with `build_tutorial_cases.py`, run
`apply_stage_photos.py` afterwards to restore these PNG assignments.

```sh
python3 tools/apply_stage_photos.py
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/stage_photos.gd
```

`tests/stage_photos.gd` checks all seven stages in the real scene: active photo
counts, PNG texture assignment, proportions, POI replacement and sample counts,
visibility rules, burn rules, tool counts and colliders, normalized scores,
layouts and captured comic textures. The former `seven_cases.gd` and
`web_seven_cases.cjs` contain historical SVG dimensions and lamp-based solutions;
their stage 1–6 solutions no longer apply. Full mouse-driven puzzle solutions
with the new artwork and tool loadouts have not yet been verified.

The reading glasses cast no visual or gameplay shadow. Their redirected beam
has range 8, intensity 3, falloff 1, transfer efficiency 1.4 and output cap 2.
Paperweights use pale blue weights and lighter brass bases for visibility.

Use **+ / −** to zoom the desk camera in or out when small evidence details
are hard to read. This magnifies the actual photo without altering its hitboxes
or printed content; zoom out to see tools beyond the page.
