# The Right Angle — project brief

============================================================
A0. WORKING RULES FOR THE ASSISTANT
============================================================

- This project is built in small steps. I give you one step
  at a time.
- Do ONLY the step I give you. Do not start the next step or
  add features from later steps, even if it seems convenient.
- Read existing files before changing them. Do not rewrite a
  working system without telling me why.
- If anything in a step is unclear or conflicts with this
  brief, ask me before building.
- Keep scripts small and single-purpose. Put every tunable
  number in an exported variable or a Resource, never buried
  inside code.
- At the end of every step, reply with:
    1. Files created or changed
    2. The scene tree of any new scene
    3. How to test it, with exact controls
    4. Anything unfinished or any known issue
  Then STOP and wait for my next message.

============================================================
A1. CONCEPT
============================================================

Title: The Right Angle
Genre: Narrative puzzle / light manipulation / dark comedy
Themes: Comic, Light, Twist (plus perspective and propaganda)

Pillar:

    BEND THE LIGHT TO BEND THE TRUTH.

Premise:
The player works the night desk of a newspaper that also
publishes a comic. Captain Halcyon, the city's beloved
superhero, is secretly a criminal. Photographs on the desk
show what he really did. The editor wants them turned into a
heroic comic before the 6 a.m. print deadline.

The player may NOT delete, edit, crop or move anything inside
a photograph. The player can only move physical objects and
light on the desk. Anything left in shadow is inked out when
the page is printed. Anything lit stays visible.

Tone split (important):
- The desk and the evidence photos are serious: late-night
  noir, real crime-scene evidence.
- The published comic is bright and cheerful, aimed at kids
  and young readers. Propaganda that looks innocent.
The contrast between the two is the joke and the twist.

============================================================
A2. DESIGN RULES
============================================================

- Every puzzle is about ILLUMINATE, BLOCK, REDIRECT, FOCUS.
- It should feel like moving objects on a real editor's desk.
- It must NOT become an inventory game, action game, FPS,
  free-roaming 3D game or realistic optics simulator.
- Panels are NOT isolated puzzles. Broad light for one panel
  spills onto its neighbours. That interdependence is the
  core of every puzzle.
- The player can always publish an imperfect page. A bad page
  gives a bad public reaction; it never blocks progress.

============================================================
A3. PRESENTATION
============================================================

Hybrid 2D/3D:
- The desk and tools are 3D (Camera3D, MeshInstance3D, simple
  primitive meshes are fine).
- The evidence photographs are 2D textures on a 3D page.
- UI uses Control nodes.
- Fixed camera, top-down or slightly angled. Mouse controls.

Desk contents: wooden surface, the case-file page, ceiling
light with pull cord, desk lamp, tools, plus decoration
(coffee mug, pencil, sticky note from the editor reading
"Make him a hero. Prints 6am — Ed.", paperclips, newspaper
scraps). Decoration needs no gameplay.

Atmosphere: late-night newsroom, warm lamp light, dark
surroundings, strong readable shadows, slightly messy desk.

============================================================
A3.1. SCREENSHOT / VISUAL REFERENCES
============================================================

A folder named:

    screenshots/

has been provided in the project root.

Before implementing or significantly changing any visual scene,
UI layout, desk composition, comic presentation, or results screen,
inspect the images in this folder.

These screenshots are VISUAL REFERENCES ONLY.

They show the basic idea of what the player should see and are
intended to communicate things such as:

- the overall desk-based presentation
- a case-file/comic page placed at the centre of the desk
- photographs arranged as panels on that page
- physical tools positioned around the page
- a fixed top-down / slightly angled viewpoint
- strong readable light and shadow across the desk
- a right-side UI showing the current interpretation of each panel
- the visual separation between the serious evidence desk and the
  bright published comic
- the general idea of the final comic/social reaction screen

DO NOT attempt to recreate the screenshots exactly.

In particular, do not blindly copy:

- exact positions
- dimensions
- spacing
- colours
- fonts
- panel count
- proportions
- icons
- tool placement
- UI layout
- artwork
- individual visual details

Treat the screenshots as CONCEPT ART / UX REFERENCES, not as
pixel-perfect mockups.

The Godot version should develop its own polished visual identity
while preserving the same core experience:

    PHYSICAL DESK
         +
    EVIDENCE PAGE
         +
    MANIPULATABLE LIGHT/OBJECTS
         +
    LIVE STORY INTERPRETATION
         ↓
    PUBLISHED COMIC
         ↓
    PUBLIC REACTION

When the written DESIGN.md specification conflicts with something
shown in a screenshot, DESIGN.md takes priority.

For example, a screenshot may contain six photographs while the
current Level 1 specification requires four. Implement four.

Likewise, if a screenshot shows a tool or mechanic that has not yet
been introduced by the current implementation step, DO NOT add it
early.

Use screenshots to answer:

    "What should this experience roughly feel like?"

Do not use them to answer:

    "What exact implementation should I copy?"

============================================================
A4. THE CASE-FILE PAGE
============================================================

- One page per level. Panel count comes from level data.
  Case 1 uses ONE photograph; the first seven cases use 1–3 photographs.
- Header printed on the page, e.g.
  "CASE FILE · FIRST CITY SAVINGS · FRI 2:14 PM"
  and a red rubber stamp "DO NOT PRINT".
- Photos look like real evidence prints: white border, a bit
  of tape, slight grain, slightly desaturated.
- Source photos are never modified. Ink and burn marks are
  separate layers.

============================================================
A5. LIGHTS AND TOOLS (final behaviour)
============================================================

These are built across several steps. This is how each one
must behave when finished.

CEILING LIGHT (main light)
- Hangs above the top edge of the desk with a pull cord.
  Click the cord or press L to switch it.
- ON: the whole page is brightly lit and every piece of
  evidence is visible. This lets the player study the photos.
- OFF: the page is much dimmer and the player works with the
  tools. Switching it off is effectively the first move.
- It is a real gameplay light, not just a visual one.

AMBIENT
- With every light off, the player must still faintly see the
  desk. Ambient gameplay light is tiny (about 0.05) and can
  never make anything count as visible.

DESK LAMP
- Broad light. Movable anywhere on the desk; closer means
  brighter. Always affects several panels at once.

TORCH (one or two)
- Narrow beam. Move it, aim it with a rotation handle, switch
  it on or off with a double click or Space.

PAPERWEIGHTS
- Occluders. Cast hard shadows away from every light at once.
  Block gameplay light rays. Shapes can vary later.

READING GLASSES
- Game optics, not real optics. When a beam hits the glasses,
  they send out a controlled beam in the direction they face.
  Rotating the glasses aims it. Predictable, clearly drawn.
- The player should think: "The glasses let me send light
  where the lamp can't reach."

MAGNIFYING GLASS
- Focuses incoming light into a small, bright spot. It is a
  booster for lighting a hero precisely. It barely darkens
  what sits under its rim.
- Burning: only when held still in very strong light, and
  slowly (about 2.5 s). Give clear warning first: glowing
  spot, discoloration, smoke, a "Too hot" hint. Then a
  permanent scorch mark for this attempt.
- A burned panel becomes TAMPERED.
- Burning NEVER counts as hiding evidence. (In the prototype
  the magnifier was too strong: players burned away every
  piece of evidence to win. This rule prevents that.)

============================================================
A6. POINTS OF INTEREST (POIs)
============================================================

Every photo has hand-placed POIs (no image recognition).

Types: HERO, WEAPON, VICTIM, MONEY, WITNESS, DAMAGE, POLICE,
FIRE, EXIT, SPEECH_BUBBLE (extendable).

Each POI stores:
- id, type, description
- desired: VISIBLE or HIDDEN
- position and radius on the photo
- importance
- current_light (0.0 to 1.0, calculated)
- comment lines used by the reaction screen

Light at a POI = average of about 9 sample points spread over
its area (centre plus points around it).

============================================================
A7. LIGHT EVALUATION
============================================================

Keep VISUAL lighting (what Godot renders) separate from
GAMEPLAY lighting (what the rules use).

For each gameplay light: is the point inside its range and
cone, how strong is it there (falloff), and does a raycast
from the light to the point hit an occluder? Then add
redirected and focused beams. Sum everything and clamp to
0..1.

Thresholds (configurable, defined in ONE place):

    HIDDEN    below 0.30
    MURKY     0.30 to 0.55
    VISIBLE   0.55 and above

A hero counts as lit at 0.55 or more.
Evidence counts as hidden below 0.30.

CRITICAL: one function, light_at(point), gives the light at
any point on the page. POI checks, the ink preview and the
final comic must ALL use this same function, so what the
player sees on the desk is exactly what prints.

============================================================
A8. INK PREVIEW (always on, no toggle)
============================================================

The page always shows what will print as shadow:
- below 0.30: strong deep-purple tint
- 0.30 to 0.55: lighter purple tint
- 0.55 and above: no tint
Small label under the page: "INK PREVIEW: purple prints as
shadow".

Suggested method: evaluate light_at() on a low-resolution
grid over the page (resolution exported, e.g. 128 x 196),
write it into an Image/ImageTexture, and use it in the page
shader. Re-evaluate only when something moves.

============================================================
A9. PANEL STATES
============================================================

States: SPUN, MURKY, DAMNING, TAMPERED.

Default rules, checked in this order (a panel's data can
override them):
1. Any evidence POI not hidden and not burned -> DAMNING
2. Otherwise any burn mark on the panel -> TAMPERED
3. Otherwise every desired-VISIBLE POI is lit -> SPUN
4. Otherwise -> MURKY

Each panel has a caption for each state. Example, THE VAULT:
  SPUN:     "Halcyon inspects the vault door the robbers
             blew open."
  DAMNING:  "Halcyon punches straight through the vault door."
  MURKY:    "Something has torn its way into the vault."
  TAMPERED: "Part of this photo has been burned away."

No panel logic in one big global script. Rules live in data.

============================================================
A10. DESK UI (right side)
============================================================

- "PANELS SPUN 2 / 4" with a bar split by state.
- One row per panel: number, title, state pill, and the
  current caption in a handwritten font. Updates live.
- Pills use text plus colour, never colour alone.
- A hint line under the desk explains the selected tool.
- Target rings (hint overlay): rings around POIs labelled
  LIGHT HIM / LIT / HIDE / HIDDEN / BURNED. On by default in
  Level 1 only; toggle in settings.
- Large PUBLISH button.

============================================================
A11. PUBLISHED COMIC PAGE
============================================================

On PUBLISH: freeze the lighting, evaluate everything, build
the comic, show the results screen.

Style: bright kids' comic.
- Yellow page with a dot pattern. Big outlined title
  "CAPTAIN HALCYON" with a round "No. 1" badge.
- Subtitle pill chosen by result:
    all panels spun:   "SAVES THE DAY!"
    any tampered:      "WHAT HAPPENED AT THE BANK?"
    1–2 damning:       "HERO... OR VILLAIN?"
    3+ damning:        "...THE BANK BANDIT?!"
    otherwise:         "A STRANGE DAY AT THE BANK"
  (subtitles are per-level data)
- Panels use the ORIGINAL evidence photos, not redrawn art,
  with a comic filter: bold dark outlines (edge detection),
  boosted and posterized colour, halftone dots on light areas.
- Then the ink, from the same light data as the preview:
  below 0.30 solid deep purple (#2A1F5C); 0.30–0.55 diagonal
  halftone dots that get denser as light drops.
- Burn marks show as scorched holes.
- Thick rounded panel borders; a caption box under each panel
  with that panel's state caption.
- Speech balloons and sound-effect bursts per panel state,
  e.g. SPUN "Hold on tight, little ones!", DAMNING
  "KA-CHING!", MURKY "???".
- Reveal: each panel first appears as "YOUR PHOTO" (the lit
  desk photo), then fades into its comic version, one after
  another; balloons pop in last. A "Replay printing" button.

============================================================
A12. PUBLIC REACTION
============================================================

The comic appears as a post on a fictional, Instagram-style
social app from @thedailybeacon. Invent the app; no real
brand names or logos. Heart / comment / share icons, a post
caption with hashtags.

PUBLIC MOOD, score 0–100. Starting formula for 4 panels
(all weights configurable):

  score = clamp(50 + 12.5*SPUN - 20*DAMNING
                   - 12*TAMPERED - 4*MURKY, 0, 100)

Bands:
   0–19 FURIOUS     "Readers are calling for his arrest."
  20–39 SUSPICIOUS  "People are zooming in on the panels."
  40–59 DIVIDED     "The city can't decide what it read."
  60–79 CHARMED     "Most love him. A few keep zooming in."
  80–100 ADORING    "The city is in love with its hero."
Show a gradient meter with a needle that animates to the
score, five faces, and the one-line summary.

Stats: likes, comments, shares derived from the score (higher
score means more likes; lower means more comments).

COMMENTS: from templates, no AI API. Deterministic: the same
result always gives the same comments (seeded random).
- DAMNING panel: a skeptic points at that panel's visible
  evidence ("Those 'survivors' in panel 4 have dollar signs
  on them"). If score >= 30, a fan replies defending him
  ("he was CHASING the robbers, read it again").
- TAMPERED panel: "Is that a BURN MARK on panel 2? What is
  the Beacon hiding?"
- MURKY panel: "Panel 3 is so dark I can't tell what's
  happening lol". With 3+ murky: "Did they draw half of this
  with the lights off??"
- SPUN panel: fans gush about that specific panel.
- Extra generic fan comments, more at higher scores.
- Perfect score in the first seven cases: cheerful fan comments only.
  Do not explain the discovery or question the assignment.
Sort by likes, show about 9, then "View all N comments".

EDITOR VERDICT at the top: names any damning panels, scolds
burning ("Never touch the prints."), or says "Excellent work."
Followed by "Spin rating X/N" for the active photo count.
Buttons: Back to the desk, Next case (when unlocked).

============================================================
A13. CASE CONTENT AND NARRATIVE
============================================================

The first seven cases are the tutorial/narrative progression:
1 THE HERO — one photograph, innocent lighting tutorial.
2 THE PEOPLE'S HERO — two photographs, light hero and cheering citizens.
3 ABOVE THE LAKE — one photograph, hide the drowning woman with a shadow.
4 KEEPING THE PEACE — two photographs, obscure the dead citizen, officer
  and captured accusation: HE WAS INNOCENT!
5 THE RESCUE — two photographs, light the survivors; obscure the witness
  and fire connecting Halcyon to the incident.
6 THE BANK — two photographs, establish a robbery response; hide the
  money bag, banknotes, guard and STOP! in the getaway photograph.
7 OUR GREATEST HERO — three photographs, obscure attack, fleeing and
  injured civilians, witnesses, police and destruction.

Escalation: innocent, positive, questionable, disturbing, suspicious,
obviously criminal, undeniable. This is authoring context only: discover
it from the photographs, never from explanatory dialogue.

The player character never questions, refuses, exposes Halcyon or comments
on the morality of the work. The editor treats every case as ordinary
image preparation. Successful manipulation always earns SPUN, GOOD WORK,
STORY READY and CHARMED/ADORING. The goal never changes:
KEEP HALCYON IN THE RIGHT LIGHT.

These cases must remain mechanically easy, with readable source images
and spatially separated POIs. Positive surrounding subjects are desired
VISIBLE; unwanted context is desired HIDDEN. Case 4 uses HIDDEN for the
dead citizen. Lamp and shadows are taught before the torch in Case 6.
Reading glasses and magnifying glass remain available for later content,
but are not introduced in these seven tutorial cases.

Case 7 is not the larger final puzzle. It publishes normally, with no
moral choice, refusal, original-photo publication, conspiracy reveal or
guilt dialogue. A perfect edition reads OUR CITY'S GREATEST HERO!, earns
an overwhelmingly positive feed and receives Excellent work.
The currently available sequence cycles to the next ordinary edition
(Case 1) after Case 7; later cases can be appended through LevelData.

Exact captions, editor instructions and POIs live in data/levels/
hero, fans, lake, peace, rescue, robbery and greatest.
See docs/seven-cases.md and docs/tutorial-pois.md for the implementation,
working solutions, controls and every coordinate.

============================================================
A14. ART AND AUDIO
============================================================

Desk: warm brown wood, dark surroundings, warm lamps, paper,
dust, noir.
Evidence photos: illustrated, thick outlines, flat but muted
colours, grain, readable silhouettes. Serious.
Comic: bright colours, big lettering, halftone, balloons,
action words (WHOOSH! KRAKA-BOOM! BONK! KA-CHING!). Keep
effects out of the puzzle itself.

Audio: soft pickup sound, subtle scrape on rotate, click for
lamp/torch/ceiling cord, faint sizzle while burning, small
typewriter ding when a panel becomes SPUN, printing press on
publish, paper unfolding on results, quiet newsroom ambience
with a ticking clock and distant city.

============================================================
A15. CODE ARCHITECTURE
============================================================

scripts/
├── game/          game_manager.gd, level_manager.gd,
│                  save_manager.gd
├── data/          level_data.gd, panel_data.gd, poi_data.gd,
│                  comment_templates.gd   (Resources)
├── interaction/   interaction_manager.gd,
│                  draggable_object.gd, rotatable_object.gd
├── lighting/      gameplay_light.gd, light_evaluator.gd,
│                  ceiling_light.gd, redirector.gd,
│                  focuser.gd, ink_preview.gd
├── evidence/      evidence_panel.gd, evidence_poi.gd,
│                  interpretation.gd
├── tools/         desk_lamp.gd, torch.gd, paperweight.gd,
│                  reading_glasses.gd, magnifying_glass.gd
└── ui/            story_status_ui.gd, comic_result_ui.gd,
                   comic_renderer.gd, public_reaction_ui.gd,
                   reaction_generator.gd

LevelData contains: title, incident, panels (PanelData),
available tools and their start positions, required spun
panels to pass, subtitles, comment templates.

============================================================
A16. WEB BUILD
============================================================

Target: Web build on itch.io.
- Use the Compatibility renderer from day one (required for
  web export).
- Few dynamic lights, small textures, low-poly meshes, no
  heavy shaders or realtime GI. Compressed assets.
- Mouse + keyboard controls.
- Test a web export early (after Step 2) and at Step 10.
