# Composed evidence artwork

The current seven cases use **thirteen self-contained SVG photographs**.
[View all scenes](previews/evidence-scenes.png): rows follow the seven cases,
with one, two or three photographs in each row. The empty preview cells are
not part of the game. See [case content, solutions and testing](seven-cases.md)
and [the current POI coordinates](tutorial-pois.md).

The user-supplied `Assets/evidence_assets/` pack is intact. Hero poses, crowds,
victims, officers, witnesses, backgrounds, money and effects are embedded as
named vector groups. Additional quote/strap/beam paths establish accusations,
stolen money and the attack. All active textures are **768 × 640** under
`Assets/evidence/hero`, `fans`, `lake`, `peace`, `rescue`, `robbery` and `greatest`.
These are vector illustrations, with muted colors on the desk and the existing
bright comic treatment when published.

## Editing

Open a generated SVG directly in Inkscape to edit its named groups. For
repeatable placement changes, edit `data/art/evidence_compositions.json`:

- `asset` selects a supplied SVG; `svg` contains an additional vector detail.
- `poi` anchors the layer to a named POI; `at` sets an absolute location.
- `anchor`, `offset`, `scale` and `mirror` control placement.
- `desaturation` bakes the muted palette without unsupported SVG filters.

The compositor reads destinations from each panel's `.tres`, prefixes imported
IDs to isolate clipping paths/gradients, converts text to DejaVu Sans outlines
for Godot and clips everything to the photograph. No external image references
or runtime authoring dependencies are needed. The raw pack and authoring JSON
are excluded from export; the assembled images are included.

To regenerate the complete content from its authoring source, install Python
`fonttools`, then run:

```sh
python3 tools/build_tutorial_cases.py
python3 tools/compose_evidence_scenes.py
```

`build_tutorial_cases.py` rewrites the seven case resources and manifest, so
make persistent content edits there or keep direct resource edits separately.
For artwork-only changes to the manifest, run just the compositor. Import the
project in Godot, or run its headless editor import, before previewing/exporting.
`tools/preview_evidence.gd` renders the contact sheet and individual PNG previews
with Godot's actual SVG loader.

Files/scene tree, exact controls and current limits are documented in
[seven-cases.md](seven-cases.md). There is no new scene file for the artwork.
The old twenty-photo campaign remains only as historical authoring files.
