# Comic proofs and endings

Previews: [proof](previews/comic-proof.png), [good page 1](previews/ending-good-page1.png),
[good page 2](previews/ending-good-page2.png), [bad ending](previews/ending-bad.png),
[nameplate](previews/editor-nameplate.png).

Every stage now opens an **unpublished proof** when you press Publish this
edition. Keep editing returns to the exact desk state. Publish this comic
confirms that frozen proof and evaluates public opinion once.

Mood rules use the current reaction bands:

| Mood | Outcome |
| --- | --- |
| FURIOUS / SUSPICIOUS (0–39 by default) | Bad ending immediately; Replay stage returns to the same case |
| DIVIDED (40–59) | No ending or advancement; Try again returns to the desk |
| CHARMED / ADORING (60–100) | Stage cleared; Next case advances |

The good ending requires confirmed CHARMED/ADORING editions for **all eight
stages**, including the last. A final-stage pass alone cannot trigger it.
After the good ending, the game thanks the player and offers Replay game,
which clears the completed-stage ledger and restarts Stage 1.

Bad-ending retries preserve earlier clears, the current photograph resources,
tool positions, ceiling/torch state and scorch marks. Restart case remains an
explicit way to reset burns. A bad ending replaces the desk nameplate with a
*different* name from the exported list of 15 names. The chosen name otherwise
stays fixed through stage changes, manual restarts and campaign replay.
Progress and names are session-local, like the existing campaign.

## Ending pages

The supplied files are under `Assets/Endings` (capital E).

Good: A, B, C, D, E on page 1, then F alone on page 2:

```text
A | C
B | C
D | E

Page 2: F
```

Bad: A and B side by side on one page. All panels reveal alphabetically.
The first panel appears immediately; each later panel appears after one second.
Next panel reveals the next immediately and restarts the one-second delay.
Skip completes the sequence and shows Replay stage / Replay game. Images retain
their proportions and the automatic timer stops after the final panel.

## Files / scene tree

Added: `scripts/ui/ending_comic.gd`, `scenes/ui/ending_comic.tscn`,
`scripts/props/editor_nameplate.gd`, `tests/endings.gd`, this guide and previews.
Updated: `game_manager.gd`, `comic_result_ui.gd`, `story_status_ui.gd`,
`start_screen.gd`, `scenes/main.tscn`, the Stage 7–8 regression and README.

```text
Main/DeskStage/Props/Nameplate
  MeshInstance3D + Label3D (runtime)
Main/ResultsLayer/EndingComic
  MarginContainer/VBoxContainer
    Header, mood, comic sheet, panel count, thanks, navigation (runtime)
  Timer (one second)
```

The comic proof reuses the existing ComicResult scene in proof mode, displaying
no public likes, comments or verdict until confirmation.

## Verification

`godot --headless --path . --script tests/endings.gd` covers preview cancellation,
no advancement before confirmation, boundaries 39/40/59/60, one-second reveals,
manual reveal order, two-page good layout, skipping, all-stage completion,
changed/persistent identity, retained tool positions/scorches and replay.
Stage 7–8 and menu regressions run against the new confirmation flow.
Existing shutdown resource-leak warnings remain.

Stages 1-3 are forgiving: a sour reception there (below Divided) only shows the results with **TRY AGAIN**; the bad
ending and the editor change start from stage 4 (`GameManager.bad_ending_from_stage`).
