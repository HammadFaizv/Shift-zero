# Steps 0–2: desk and visual lights

This records the initial implementation. Steps 3–5 now add interaction,
gameplay lighting and ink preview. The desk lamp has since been replaced with
a torch; see [the current controls and checks](torch.md).

The project started with Godot 4.7 Compatibility settings, three imported GLB
props, TIFF wood maps and screenshot references, but no main scene or scripts.
The existing renderer and project name are retained. The game's title is shown
in the scene. `DESIGN.md` contains Part A of `Agents.md`.

Implemented: an authored main scene, input actions, a wooden desk, a case-file
page with four numbered placeholder images, a fixed orthographic camera, a dim
environment, a ceiling fixture with a clickable cord, a broad desk lamp, one
shadow-casting paperweight, a mug, pencil and editor's note. There is no temporary
light: the two tool lights provide the illumination.

## Files

- `project.godot`: main scene, 1280×720 base viewport, minimum window size and six
  input actions. Compatibility rendering is retained.
- `DESIGN.md`: project brief copied from Part A.
- `scenes/main.tscn`: camera, environment, scene instances and title/control hint.
- `scenes/desk/desk.tscn`: desk, blotter and decorative props.
- `scenes/desk/case_file_page.tscn`: page, header, stamp and four photo meshes.
- `scenes/lighting/ceiling_light.tscn`: fixture, visual light and cord click target.
- `scenes/tools/desk_lamp.tscn`, `scenes/tools/paperweight.tscn`: static tools.
- `scripts/lighting/ceiling_light.gd`: keyboard/click toggle and a state signal.
- `scripts/{game,data,interaction,evidence,tools,ui}/.gitkeep`: planned folders;
  no placeholder scripts.
- `Assets/materials/wood_color.png`, `wood_roughness.png`: Godot-ready copies of
  the supplied TIFF maps, with roughness converted from 16-bit to 8-bit.
- `Assets/evidence/placeholders/*.svg`: four 768×640 test images, with matching
  aspect ratio on the photo meshes. Godot also creates their `.import` sidecars.

## Scene trees

All geometry is authored in `.tscn` files and editable in Godot. The `.tscn`
instances expand as follows:

```text
Main (Node3D)
├── WorldEnvironment
├── Camera3D
├── DeskStage [desk.tscn]
│   ├── Desk, Edge, Blotter (MeshInstance3D)
│   ├── CaseFilePage [case_file_page.tscn]
│   │   ├── Paper, HeaderRule (MeshInstance3D)
│   │   ├── CaseHeader, Time, Stamp, Footer (Label3D)
│   │   └── Photo01, Photo02, Photo03, Photo04 (Node3D)
│   │       └── Border, Image, Tape (MeshInstance3D), Title (Label3D)
│   └── Props (Node3D)
│       ├── Mug (Node3D): Body, Coffee, Rim, Handle (MeshInstance3D)
│       ├── EditorNote (Node3D): Paper (MeshInstance3D), Message (Label3D)
│       └── Pencil (MeshInstance3D)
├── Tools (Node3D)
│   ├── CeilingLight [ceiling_light.tscn, ceiling_light.gd]
│   │   ├── Shade, Rim, Diffuser (MeshInstance3D)
│   │   ├── VisualLight (OmniLight3D)
│   │   ├── PullCord (Node3D)
│   │   │   ├── Cord (MeshInstance3D)
│   │   │   └── Handle (StaticBody3D)
│   │   │       ├── Knob (MeshInstance3D)
│   │   │       └── CollisionShape3D
│   │   └── Status (Label3D)
│   ├── DeskLamp [desk_lamp.tscn]
│   │   ├── Base, Stem, Arm (MeshInstance3D)
│   │   └── Head (Node3D)
│   │       ├── Shade, Bulb (MeshInstance3D)
│   │       └── VisualLight (SpotLight3D)
│   └── Paperweight [paperweight.tscn]
│       └── Base, Weight (MeshInstance3D)
└── Overlay (CanvasLayer)
	└── Frame (Control): Eyebrow, Title, Hint (Label)
```

## Manual check

1. Open `project.godot` in Godot 4.7.2 and press **F6** on `scenes/main.tscn`,
   or **F5** to run the project.
2. Confirm all four photo numbers/titles, the case-file heading and red stamp
   are readable. The right side is reserved for the later story UI.
3. Press **L**, or left-click the **red knob at the end of the ceiling cord**.
   The ceiling light and its ON/OFF label should switch together. Repeating the
   action turns it back on. Holding L should not repeatedly toggle it.
4. With the ceiling off, the desk lamp should still illuminate several photos,
   and the paperweight on photo 1 should cast a clear shadow.
5. Check window framing at 1280×720 and 1920×1080.
6. For an ambient-only check, hide both `VisualLight` nodes in the editor and
   use F6. The desk should remain faintly visible. Restore both nodes afterward.

Registered for later steps: left mouse = select; right mouse / Esc = deselect;
Q/E = rotate; Space = torch toggle. Only the ceiling toggle is active now.

## Tuning

Numbers live in the scene resources or exported script properties:

| Setting | Location | Initial value |
| --- | --- | --- |
| Viewport / minimum window | `project.godot` | 1280×720 / 960×540 |
| Camera position / orthographic size | `main.tscn`, Camera3D | (2.3, 12, 7) / 9.4 |
| Visual ambient energy | `main.tscn`, Environment | 0.16 |
| Desk size / top surface | `desk.tscn`, DeskMesh | 12×0.32×8 / Y=0 |
| Page size / centre | `case_file_page.tscn`, Page; `desk.tscn` | 4.7×0.022×5.85 / (-0.3, 0.055, 0) |
| Photo texture / mesh size | placeholders; PhotoMesh1–4 | 768×640 / 1.95×1.625 |
| Ceiling energy / range / attenuation | `ceiling_light.tscn`, VisualLight | 1.4 / 11 / 0.8 |
| Lamp energy / range / cone | `desk_lamp.tscn`, Head/VisualLight | 1.5 / 10 / 58° |
| Cord click layer / distance / radius | ceiling script; KnobShape | layer 4 (mask 8) / 50 / 0.23 |

Visual ambient energy is independent of the gameplay ambient value described
in the brief. Gameplay light sampling starts in Step 4.

## Verification

Checked in the installed Godot 4.7.2 editor/runtime with Compatibility OpenGL:
the main scene loads, all six input actions are registered, L changes the light
state, and simulated clicks on the physical cord switch it at both resolutions.
Inspected rendered frames at exactly 1280×720 and 1920×1080 with the ceiling
on/off, plus an ambient-only frame. Photo titles and shadows are readable and
the desk remains faintly visible with both lights hidden. `git diff --check`
passes. The initial headless editor import reported sandbox restrictions on its
debug listener and settings file; the project runtime and final render checks
completed without script errors.

Saved previews: [ceiling on](previews/desk-on.png) and
[ceiling off](previews/desk-off.png). The preview directory has `.gdignore` so
these documentation images are excluded from Godot's asset imports.

## Remaining work

The photos are test patterns awaiting evidence artwork in Step 7. Dragging,
rotation, gameplay light evaluation, ink preview, story UI and publishing are
future steps. The flashlight and magnifier assets are reserved for Steps 11
and 13. No Web export was produced: matching export templates are not installed.
The next implementation step is Step 3.
