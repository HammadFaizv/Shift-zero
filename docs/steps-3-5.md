# Steps 3–5: interaction, gameplay light and ink preview

This records the original desk-lamp implementation. The current scene uses a
lower torch with a narrower beam; [torch setup and current checks](torch.md)
supersede the lamp controls, positions, tuning and measurements below. The
integration check now exercises the torch.

Implemented against the existing Steps 0–2 scenes, using the visual references
in `ScreenShots/`. Tools keep their original meshes, lights and editable scene
structure. The evidence images remain 768×640 placeholders.

## Controls and manual checks

Run `scenes/main.tscn` with **F6**, or the project with **F5**.

1. Move the pointer over the **lamp base/head** or **paperweight**: a subtle
   warm highlight should appear. Left-click and hold to select and drag.
   A gold outline and the tool name should appear. Release to stop dragging;
   the tool stays selected.
2. Select the lamp, then hold **Q/E** or use the **mouse wheel** to rotate it.
   The lamp's light and shadows should follow its position and rotation. The
   paperweight is draggable only. **Right-click** or **Esc** deselects.
3. Try dragging past each desk edge. The whole tool footprint should remain
   inside the desk. Movement uses a plane and static collision bodies, without
   rigid-body simulation. Tools rise slightly when their base overlaps the page.
4. Press **L** or click the **red cord knob** to turn the ceiling off. The right
   panel should show lower readings for all four test POIs. Small H1/E2/E3/E4
   labels on the photos identify their positions. Each value averages the centre
   plus eight perimeter samples using an incremental mean, preserving uniform
   readings at the exact visibility thresholds.
5. Move the lamp closer to the lower-right photo while aiming at it. E4 should
   become brighter. For a known shadow arrangement, keep the lamp's initial
   yaw and place its base at approximately **X=-2, Z=0.2**, then move the
   paperweight to approximately **X=0.70, Z=1.06**. E4 should read **5.0% HIDDEN**,
   and the same spot should turn deep purple.
6. Move the weight away. The purple shadow and POI reading should update live.
   Turning the ceiling on should make unblocked POIs visible again.
7. Check framing at **1280×720** and **1920×1080**. The debug readout stays on the
   right and the control hint stays below the desk.

Purple is always on: strong tint below 30%, lighter tint from 30% to below 55%,
and no tint at or above 55%. It covers the original photo meshes rather than
altering their textures or tinting the case-file header and captions.

Saved previews: [lamp selected](previews/steps-3-5-selected.png),
[ceiling off](previews/steps-3-5-off.png), and
[E4 blocked](previews/steps-3-5-shadow.png).

## New and changed files

New scripts:

- `scripts/interaction/draggable_object.gd`: movement bounds, support height,
  hover tint and selection outline.
- `scripts/interaction/rotatable_object.gd`: held-key and stepped rotation.
- `scripts/interaction/interaction_manager.gd`: ray picking, dragging,
  selection, deselection and the current tool hint.
- `scripts/data/poi_data.gd`: POI Resource with type, desired visibility,
  normalized position/radius, importance, comments and current light.
- `scripts/evidence/evidence_poi.gd`: sample positions and averaged readings.
- `scripts/lighting/gameplay_light.gd`: cached origin/direction, range, cone,
  falloff and gameplay intensity using the corresponding visual light.
- `scripts/lighting/light_occluder.gd`: bounds around the real collision shapes
  for an inexpensive raycast rejection check.
- `scripts/lighting/light_evaluator.gd`: shared `light_at(point)` and thresholds.
- `scripts/lighting/ink_preview.gd`: a float light map sampled only on changes.
- `scripts/ui/light_debug_ui.gd`: POI names, percentages and visibility states.

New shader/scene/test files:

- `shaders/tool_outline.gdshader`, `shaders/ink_preview.gdshader`.
- `scenes/ui/light_debug_panel.tscn`.
- `tests/steps_3_5.gd`, with `.gdignore` to exclude tests from Godot imports.
- This document and its preview images in the existing ignored preview folder.
  Godot creates `.uid` sidecars for the new scripts and shaders.

Changed:

- `scenes/main.tscn`: interaction manager, evaluator, ink sampler and debug panel.
- `scenes/desk/case_file_page.tscn`: four local POI Resources, test nodes and
  markers, plus the ink-preview label.
- `scenes/tools/desk_lamp.tscn`: pick shapes, drag/rotation components and
  gameplay light.
- `scenes/tools/paperweight.tscn`: pick/occlusion shapes and drag component.
- `scenes/lighting/ceiling_light.tscn`: gameplay light linked to the visual light.
- `scripts/lighting/ceiling_light.gd`: comment reflecting the gameplay linkage.
- `project.godot`: names for physics layers 1, 2 and 4.
- `README.md`, `docs/steps-0-2.md`: current controls and progress links.

## Scene trees

The only new reusable scene is the debug panel. Its POI rows are created from
the data when the main scene starts:

```text
LightDebugPanel (PanelContainer)
└── Margin (MarginContainer)
    └── Rows (VBoxContainer)
        ├── Title (Label)
        ├── Thresholds (Label)
        └── four POI readouts (Label, runtime)
```

Additions to the existing scenes:

```text
Main
├── InteractionManager (Node3D)
├── LightEvaluator (Node3D)
├── InkPreview (Node)
├── DeskStage/CaseFilePage
│   ├── Photo01–04/TestPOI (Node3D): Marker (Label3D)
│   └── InkPreviewHint (Label3D)
├── Tools
│   ├── CeilingLight: GameplayLight (Node3D)
│   ├── DeskLamp
│   │   ├── PickBody (StaticBody3D): Base, Stem, Head (CollisionShape3D)
│   │   ├── Draggable (Node)
│   │   ├── Rotatable (Node)
│   │   └── GameplayLight (Node3D)
│   └── Paperweight
│       ├── PickBody (StaticBody3D): Weight, Base (CollisionShape3D)
│       └── Draggable (Node)
└── Overlay/Frame/LightDebugPanel
```

`Draggable` adds a hidden `SelectionOutline` mesh under each original tool mesh
at runtime. Those meshes cast no shadows and only appear for the selected tool.

## Lighting and tuning

`LightEvaluator.light_at(point)` adds gameplay ambient and each unblocked light
contribution, clamped to 0–1. Contribution is intensity × normalized distance
falloff × cone falloff. The light's exact visual transform, range and spot cone
are reused; gameplay intensity/falloff are independently tunable. Occlusion uses
the paperweight's actual sphere and cylinder collision shapes on layer 2. A
conservative bounding sphere rejects rays that cannot hit the shapes; remaining
rays use `PhysicsDirectSpaceState3D.intersect_ray`.

The evaluator watches light transforms/visibility/settings and occluder
transforms/layers at physics ticks. It only refreshes the readings and texture
when those values change. Disabled lights are excluded from the sampling loop;
fully saturated samples stop accumulating contributions. The POIs and the ink
grid call exactly the same `light_at()` function. The shader receives the same
thresholds from the evaluator, and the debug percentage is truncated to avoid
rounding a HIDDEN value up to the MURKY boundary.

| Setting | Inspector location | Default |
| --- | --- | --- |
| Desk bounds (XZ) | Main / InteractionManager | (-6,-4) to (6,4) |
| Drag plane / pick distance | InteractionManager | Y=0 / 50 |
| Lamp footprint / support radius | DeskLamp / Draggable | 1.65 / 0.58 |
| Paperweight footprint / support radius | Paperweight / Draggable | 0.29 / 0.29 |
| Desk / page support heights | Draggable | 0 / 0.086 |
| Held-key / wheel rotation | DeskLamp / Rotatable | 90°/s / 12° |
| Outline thickness | Draggable | 0.018 world units |
| Gameplay ambient / hidden / visible | LightEvaluator | 0.05 / 0.30 / 0.55 |
| Ceiling intensity / falloff | CeilingLight / GameplayLight | 2.0 / 1.0 |
| Lamp intensity / falloff / cone falloff | DeskLamp / GameplayLight | 1.6 / 2.0 / 0.6 |
| Light range and angle | Corresponding VisualLight | Existing values: ceiling 11, lamp 10 and 58° |
| POI radius / perimeter samples | POIData / TestPOI | 0.055 UV / 8 (+ centre) |
| Ink grid | Main / InkPreview | 80×100 |
| Ink colour / hidden opacity / murky opacity | InkPreview | #2A1F5C / 0.88 / 0.36 |
| Physics layers | Project Settings / Layer Names | 1 tools, 2 occluders, 4 cord |

Test POI texture coordinates (origin at the top-left):

| ID | Photo / type | Normalized position | Pixels at 768×640 |
| --- | --- | --- | --- |
| H1 | 1 / HERO | (0.50,0.30) | (384,192) |
| E2 | 2 / DAMAGE | (0.68,0.65) | (522.24,416) |
| E3 | 3 / WITNESS | (0.35,0.45) | (268.8,288) |
| E4 | 4 / MONEY | (0.62,0.50) | (476.16,320) |

With the initial positions and ceiling off, the averaged readings are about
62.6%, 51.6%, 80.7% and 53.4%. With the ceiling on they are all 100%. With both
lights off they all fall to ambient 5%, which is HIDDEN. Numerical readings are
the game's lighting model rather than a photometric match to Godot's renderer;
the purple preview is the authoritative shadow indication.

## Verification

Run the integration check from the project root:

```sh
/home/hammad/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/steps_3_5.gd
```

Omit `--headless` to also render and save previews under `/tmp`. The check
exercises viewport input for hover, selection, drag, bounds, rotation,
deselection and cord clicks at both resolutions. It verifies range/cone
rejection, threshold boundaries, POI averaging, collision-layer filtering,
shadow blocking/restoration, shared grid samples, averaging at exact thresholds
and no texture rebuilds at idle.

Passed headless and rendered checks in Godot 4.7.2 with Compatibility OpenGL on
Intel RPL-P. Optimized 60-position movement runs measured approximately
**6.7–9.2 ms median, 12.3–18.8 ms p95, 14.2–20.8 ms maximum** for the 80×100 ink
rebuild, with **106–113 FPS** reported during movement. These are local native
measurements, not a Web or mobile performance guarantee. Inspected selection, ceiling on/off, all-off and
shadow previews at exact 1280×720 and 1920×1080 sizes. `git diff --check` passes.

## Remaining work

The grid deliberately uses a modest resolution for interactive sampling, so
shadow edges show small cells. POI readings average nine samples across their
area; a partially shadowed POI can contain both purple and un-tinted pixels even
when its averaged state is MURKY. Test markers and the debug panel remain visible
for Step 4 verification. Step 6 introduces panel interpretation, target rings
and the story UI, and moves this debug panel behind F1.

Actual evidence art, publishing, reaction screens and Web testing remain future
steps. Matching Web export templates are still not installed. No changes to
the later flashlight or magnifier assets were required.
