# Steps 6–10: the complete bank case

The first-case loop is implemented: manipulate the desk, publish any edition,
watch the four photographs become a comic, read the public reaction, and return
to the same arrangement. The user's requested narrow, low torch replaces the
brief's broad lamp. A second paperweight is added; later tools/cases/audio are
outside this slice.

## Content and interpretation

`LevelData` supplies the incident, panel content, tool availability/start poses,
3/4 pass goal, subtitles, comment templates and reaction tuning. Four authored
photo slots receive their content from the level Resource before initialization.
`PanelData` supplies the original texture, POIs, captions, balloons, sound-effect
lettering, comments and overridable rule order.

Default priority: unburned evidence at or above 30% makes a panel **DAMNING**;
otherwise a burn mark makes it **TAMPERED**; otherwise every required hero at or
above 55% makes it **SPUN**; otherwise **MURKY**. Burning rules are supported in
the data/interpretation tests, but there is no burning tool in this slice.

The right panel shows four live state labels/captions and a segmented count bar.
Captions use the included OFL Caveat font. Target rings show LIGHT HIM/LIT and
HIDE/HIDDEN; their checkbox defaults on. F1 switches between story and light
debugging. Publishing is available for every result, including 0/4.

## Evidence texture size and POIs

The evidence is simple, muted illustrated SVG artwork at **768×640**. Lettering
is converted to paths because Godot's SVG importer omits SVG text. The artwork
can be replaced while retaining its size and the normalized POIs. No source
texture is modified when lighting, inking or printing.

Coordinates use the texture's top-left origin. Each POI averages the centre and
eight perimeter samples. Hero radius is 0.055 UV; evidence radius is 0.07 UV.

| Panel | POI / desired | UV centre | Pixel centre |
| --- | --- | --- | --- |
| 1 THE APPROACH | H1 Halcyon / visible | (0.65, 0.72) | (499.2, 460.8) |
| 1 | E1 crowd / hidden | (0.25, 0.28) | (192, 179.2) |
| 2 THE VAULT | H2 Halcyon / visible | (0.28, 0.72) | (215.04, 460.8) |
| 2 | E2 fist-shaped hole / hidden | (0.76, 0.30) | (583.68, 192) |
| 3 THE WITNESS | H3 Halcyon / visible | (0.65, 0.22) | (499.2, 140.8) |
| 3 | E3 “IT WAS HIM!” / hidden | (0.23, 0.74) | (176.64, 473.6) |
| 4 THE GETAWAY | H4 Halcyon / visible | (0.28, 0.22) | (215.04, 140.8) |
| 4 | E4 stolen cash / hidden | (0.76, 0.72) | (583.68, 460.8) |

The vault breach silhouette surrounds E2 and the money surrounds E4. Target
rings identify exactly which part of the illustrated evidence is evaluated.

## Controls and working solution

Run with **F5**. **L / red cord** switches the ceiling. **Click and drag** moves
the torch or either weight. With the torch selected, **Q/E / mouse wheel** aims
it; **Space / double-click** switches it. **Right-click / Esc** deselects.

A tested 4/4 solution (Godot X/Y/Z world units; dragging handles support Y):

1. Turn the ceiling **off** and leave the torch **on**.
2. Place the torch at **X=-4.7, Z=0.15**, with **yaw 0°**. It points horizontally
   across the centre of the page. From its initial -12° yaw, one wheel-up step
   reaches 0°.
3. Place the first weight at **X=1.18, Z=-1.245**, near the vault breach.
4. Place the second weight at **X=1.18, Z=1.6675**, near the falling cash.

The beam's edge hides the crowd and teller's accusation; the two weights block
the hole and cash. H1–H4 average approximately **81.8%, 64.2%, 82.1%, 64.3%**;
E1–E4 all read **5.0% HIDDEN**. All panels become SPUN. Moving either right-side
weight away exposes that panel and drops the result to 3/4, which still passes.

Click **PUBLISH THIS EDITION**. The perfect edition says **SAVES THE DAY!** and
receives **ADORING 100/100**. Publishing the initial ceiling-on arrangement
receives **FURIOUS 0/100**. Try **Replay printing**, then **BACK TO THE DESK**:
the tool poses and ceiling/torch states should be preserved. Scroll within each
results column to see the whole comic/post and all featured comments.

Saved browser previews: [desk](previews/slice-desk.png),
[4/4 solution](previews/slice-solution.png),
[ADORING comic](previews/slice-adoring.png), and
[FURIOUS comic](previews/slice-furious.png).

The current [camera composition and green ceiling lamp](camera-composition.md)
supersede the earlier desk preview framing.

The [five-case campaign, new optics and endings](steps-11-15.md) now extend
this first-case slice. The limitations and disabled Next-case button below
describe the original Step 10 implementation.

## Publishing and reaction

Publishing stops desk input, waits for the final physics movement to commit,
and captures a **160×200** page light map, twice the preview grid in each axis.
Tool colliders remain active during the freeze, so their occlusion survives
printing. Every captured sample calls the same `light_at()` function used by
the 80×100 preview and POIs. The snapshot contains immutable panel states,
captions, balloon text, effect lettering and light samples.

A separate results scene renders the original photos through a comic shader:
posterized saturated colours, dark edges, halftone texture, solid purple below
30%, and diagonal ink from 30% to below 55%. Each panel begins as YOUR PHOTO,
then becomes PRINTED COMIC; balloons and effect lettering appear last. Replay
restarts the tween from the existing snapshot rather than resampling the desk.

The fictional **Beacon Social** post includes the account, caption and social
statistics. Reaction score is `clamp(50 + 12.5*SPUN - 20*DAMNING - 12*TAMPERED
- 4*MURKY, 0, 100)`, rounded for display. The five-band meter animates a needle
and has labelled face icons. Comments come from Resources using a deterministic
seed derived from case, panel states and POI visibility/burn flags. Panel-specific
comments lead the sorted discussion; the perfect edition includes the lighting
twist and a defensive reply. “View all” expands the generated featured thread;
the total comment statistic represents the wider fictional audience.

## Files created and changed

New:

- `scripts/data/{panel_data,level_data,comment_templates,reaction_config,ui_style}.gd`.
- `scripts/evidence/{evidence_panel,interpretation}.gd`.
- `scripts/game/{game_manager,level_manager}.gd`.
- `scripts/ui/{story_status_ui,target_rings,newsroom_theme,comic_renderer,comic_result_ui,public_reaction_ui,reaction_generator,mood_meter}.gd`.
- `data/levels/bank/`: the level, four panel Resources and comment templates.
- `data/ui/default.tres`, `Assets/evidence/bank/*.svg`, `Assets/fonts/Caveat.ttf`
  and its OFL license, plus DejaVu Sans and its license for portable UI typography.
- `scenes/desk/evidence_poi.tscn`, `scenes/ui/comic_result.tscn`.
- `shaders/comic_photo.gdshader`, `shaders/comic_paper.gdshader`.
- `export_presets.cfg`, `tools/{download_web_templates,build_web,serve_web,outline_evidence_text}.py`,
  `tools/dump_tuning.gd`, `tests/vertical_slice.gd`, `tests/web_smoke.cjs`.
- These notes, `docs/tuning.md`, `docs/web-export.md`, and new previews.

Changed:

- `scenes/main.tscn`: game/level managers, story/target UI, second weight,
  comic renderer and results layer.
- `scenes/desk/case_file_page.tscn`: real panel Resources replace four test POIs.
- `scenes/tools/{torch,paperweight}.tscn`: KEEP_ACTIVE colliders for publication.
- `scripts/data/poi_data.gd`: runtime burned flag for interpretation.
- `scripts/evidence/evidence_poi.gd`: supports target rings without debug labels.
- `scripts/interaction/interaction_manager.gd`: public deselect method.
- `scripts/ui/light_debug_ui.gd`: eight-POI labels.
- `tests/steps_3_5.gd`: delegates to the full integration check.
- `README.md`, `CREDITS.md`, `.gitignore`, `docs/torch.md`.

Godot adds `.uid` and `.import` sidecars. Downloaded templates and build outputs
are locally available and ignored by Git/export; the scripts reproduce them.

## Scene trees

```text
Main (Node3D, GameManager)
├── WorldEnvironment / Camera3D
├── DeskStage / CaseFilePage
│   ├── Paper / header / stamp / footer
│   ├── Photo01–04 (Node3D, EvidencePanel)
│   │   ├── Border / Image / Tape / Title
│   │   └── 2 EvidencePOI instances (runtime)
│   └── InkPreviewHint
├── Tools
│   ├── CeilingLight
│   ├── Torch
│   ├── Paperweight
│   └── Paperweight2
├── InteractionManager / LightEvaluator / InkPreview
├── LevelManager / ComicRenderer
├── Overlay / Frame
│   ├── TargetRings (Control)
│   ├── StoryStatus (PanelContainer, runtime rows/settings/publish)
│   ├── Eyebrow / Title / Hint
│   └── LightDebugPanel (F1)
└── ResultsLayer (CanvasLayer)
    └── ComicResult (Control, instanced on publish)
```

The new POI scene is a single Node3D with the sampling script. The new result
scene creates the following Control layout from its frozen data:

```text
ComicResult
├── Background
└── Margin / Column
    ├── Header: verdict / Replay / Back / disabled Next case
    └── Columns (HBoxContainer)
        ├── ComicScroll / Post
        │   ├── Account
        │   ├── ComicPaper / title / subtitle / 2×2 panel grid
        │   │   └── Panel: original-photo shader / balloon / effect / caption
        │   └── Social post footer
        └── ReactionScroll / PublicReactionUI
            ├── Mood / animated meter / summary / statistics
            └── Featured comments / replies / View all
```

## Verification and limits

Run `Godot --headless --path . --script tests/vertical_slice.gd`; omit headless
for rendered previews. The test exercises actual viewport controls, data rule
priority/overrides, the 4/4 arrangement, both weights, live captions/targets/F1,
publishing any edition, replay, frozen colliders/ink, deterministic comments,
fan replies, murky/tampered reactions and exact return poses at both resolutions.
The rendered and Web verification results are recorded in [Web export](web-export.md).
Inspector defaults are collected in [tuning.md](tuning.md).

The evidence is replaceable first-case illustration rather than final polished
art. Low-resolution preview edges remain slightly stepped. Results columns
scroll on shorter displays. Only the bank case is implemented; Next case is
disabled. Audio and later tools/cases remain deferred. This stops at Step 10.
