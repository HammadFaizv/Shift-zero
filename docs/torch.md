# Torch replacement

This records the torch change before the complete first case. See
[Steps 6–10](steps-6-10.md) for the current content, starting paperweights,
story UI, publishing loop and Web verification.

The current main scene replaces the broad desk lamp with the supplied
`Assets/simple_lowpoly_flashlight.glb`, as requested. This overrides the original
brief's Level 1 lamp choice without implementing the remaining later steps.

The spot cone is halved from **58° to 29°**. Its emitter is **0.274 units above
the desk**, compared with the previous lamp's approximately 2.04, and aims
**6° downward**. The shallow angle creates an elongated footprint across the
page and long shadows behind the paperweight. The emitter sits just beyond the
front lens so the torch housing does not block its own beam.

The visual and gameplay light share the same transform, cone, range and on/off
state. POI readings and the purple ink preview continue to use `light_at()`.

## Files

- Added `scenes/tools/torch.tscn` and `scripts/tools/torch.gd` (plus its Godot UID).
- Updated `scenes/main.tscn` to instance the torch in place of the lamp.
- Updated `scripts/interaction/interaction_manager.gd` for double-click toggling
  and the selected torch's on/off hint.
- Updated `scripts/interaction/draggable_object.gd` so selection outlines retain
  their world-space thickness on the scaled imported model.
- Updated `tests/steps_3_5.gd` for torch input, shadow blocking and a comparison
  between low and elevated light-source shadows.
- Updated `README.md` and the earlier step notes; added this document,
  previews and `CREDITS.md` for the supplied model's CC BY 4.0 attribution.

## New scene tree

```text
Torch (Node3D, torch.gd)
├── Model (imported flashlight scene)
├── Beam (Node3D)
│   └── VisualLight (SpotLight3D)
├── PickBody (StaticBody3D, tool layer)
│   └── CollisionShape3D (BoxShape3D)
├── Draggable (Node)
├── Rotatable (Node)
└── GameplayLight (Node3D)
```

The main scene now contains `Tools/Torch`, alongside `CeilingLight` and
`Paperweight`. Imported meshes receive selection outlines at runtime.

## Controls and manual checks

1. Press **F5** to run; press **L** or click the red cord to turn the ceiling off.
   A narrow beam should stretch across the page from the torch on the left.
2. **Click and drag** the torch to move it. While selected, hold **Q/E** or use
   the **mouse wheel** to aim it. **Right-click / Esc** deselects.
3. Press **Space** while the torch is selected, or **double-click** its body,
   to toggle it. With the ceiling and torch both off, all four readings should
   show **5.0% HIDDEN** and the photos should be purple.
4. Drag the paperweight into the beam. A long shadow should extend away from
   the torch; shadowed evidence should turn purple and its POI reading should
   fall. Move the weight away to restore the light.
5. Check at **1280×720** and **1920×1080**: the beam, selection outline and
   control hint should remain readable.

Saved previews: [ceiling off](previews/torch-off.png),
[torch selected](previews/torch-selected.png), and
[paperweight blocking E2](previews/torch-shadow.png).

## Tunables

| Setting | Inspector location | Value |
| --- | --- | --- |
| Initial position / yaw | Main / Tools / Torch | (-3.9, 0, -1.1) / -12° |
| Emitter position / rotation | Torch / Beam | (0.72, 0.274, 0) / (-6°, -90°, 0°) |
| Cone / range | Beam / VisualLight | 29° / 12 |
| Visual energy / distance attenuation / cone attenuation | Beam / VisualLight | 4.5 / 0.8 / 0.6 |
| Shadow bias / normal bias | Beam / VisualLight | 0.008 / 0.15 |
| Gameplay intensity / falloff / cone falloff | GameplayLight | 1.6 / 2.0 / 0.6 |
| Starts on / body colour | Torch | true / charcoal (0.16, 0.18, 0.20) |
| Footprint / support radius | Draggable | 0.8 / 0.27 |
| Desk / page support height | Draggable | 0 / 0.086 |
| Held-key / wheel rotation | Rotatable | 90°/s / 12° |

Dragging onto the page raises the entire tool by 0.086, keeping the emitter
close to the surface. Shared lighting thresholds and ink settings are unchanged.
With the initial positions and ceiling off, H1/E2/E3/E4 read approximately
**76.3% / 65.8% / 5.0% / 19.7%**.

## Verification and limits

Passed headless and rendered integration checks in Godot 4.7.2 Compatibility:

```sh
/home/hammad/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/steps_3_5.gd
```

Omit `--headless` to render the previews under `/tmp`. The check covers picking,
movement bounds, rotation, Space/double-click toggles, cone/range rejection,
paperweight occlusion, shared POI/ink samples, threshold boundaries, idle updates
and ceiling controls at both resolutions. A 75-point raycast comparison behind
the weight found **75 blocked samples with the low emitter versus 12 with the
elevated emitter**. This measures the sampled shadow path, not a universal area
ratio. Rendered previews were inspected at both sizes. The local native run
reported 83 FPS during movement and a median ink rebuild of about 7.8 ms.

No unfinished work for this replacement. The existing low-resolution ink grid
still gives shadow edges a slightly stepped appearance. Evidence artwork and
the remaining game steps are unchanged; a browser export has not been tested.
