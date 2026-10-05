# Stages 7 and 8

The active campaign now has eight cases and 22 photographs, with counts
**1, 1, 1, 2, 2, 4, 6, 5**. The former three-photo `greatest` case remains on
disk as historical content but is no longer in the campaign.

| Stage | Desk and comic layout | Equipment |
| --- | --- | --- |
| 7 — Assembly Square | Three columns, two rows; six photographs | Two torches, one paperweight, two pairs of reading glasses |
| 8 — The Factory | Two columns, two rows, then one photograph spanning both columns | One torch, two pairs of reading glasses, one magnifier |

The ceiling inspection light remains available, as in the earlier PNG stages.
Photograph proportions are preserved. Use +/− to zoom into small details.
The larger stages have a scrolling status list with the Publish button outside
it. Every edition first opens a proof for confirmation. CHARMED/ADORING advances;
DIVIDED retries; lower moods trigger the bad ending without resetting the desk.
Clearing all eight cases unlocks the good ending. See [endings](endings.md).

## Objectives

Stage 7:
1. Light the hero; hide protesters and their signs. Caption: Halcyon arrives
   to help settle the protest.
2. Light the hero; hide the citizen crushed by the car. Caption: Halcyon creates
   space between police and citizens.
3. Light the hero; hide running citizens. Caption: Halcyon joins the protest.
4. Light the hero and police; hide the nurse and dead citizen. Caption: Halcyon
   objects as officers prepare to use force.
5. Light the hero; hide both destroyed cars and rubble.
6. Light the hero; hide police violence and the citizens beneath him.

Stage 8:
1. Light the factory and hero.
2. Light the hero; hide oil cans, spilled oil and the lighter.
3. Light the hero; hide both workers.
4. Light the hero; hide both dead workers.
5. Light the hero; hide the ruined factory and both areas of rubble.

[Target coordinates](stages-7-8-pois.md) ·
[Annotated photographs](previews/stages-7-8-hitboxes.png)

## Files and scene tree

Content: `data/levels/protest/{01..06}_panel.tres`,
`data/levels/factory/{01..05}_panel.tres`, and both folders' level/reaction/comments
resources. `tools/author_stages_7_8.py` regenerates only these two stages and
will overwrite manual edits to their resources.

The existing main scene adds `Tools/ReadingGlasses2`; the existing page adds
`Photo05` and `Photo06`, each with Border, Image and Tape children. InkPreview
now covers all six slots. LevelData exports `comic_columns` and `comic_wide_last`
for the printed layout. No new standalone scene is needed.

Updated gameplay files: `level_data.gd`, `game_manager.gd`, `comic_grid.gd`,
`comic_renderer.gd`, `comic_result_ui.gd`, `story_status_ui.gd`, `ink_preview.gd`,
`start_screen.gd`, both scene files and the Web export exclusions.

## Play and verification

F5 → Play → finish/skip tutorial. Publish and Next case advance to Stage 7/8.
Drag tools with the left button; Q/E, wheel or the gold handle aims them.
Space/double-click toggles a torch; L toggles inspection lighting. Use the
pencil-mark checkbox to inspect targets; F1 shows light readings.

`tests/stages_7_8.gd` checks content, all target requirements, scores, aspect
ratios, six-slot ink overlays, inactive tool collisions, case switching,
comic views, printing and progression. `tests/stage_photos.gd` covers all eight
cases; the menu test also passes. Native screenshots verify both desk and comic
layouts. These checks do not establish complete mouse-driven puzzle solutions
or balance for the new equipment combinations. Existing shutdown resource-leak
warnings remain.
