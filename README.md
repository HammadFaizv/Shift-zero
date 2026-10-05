# The Right Angle

**Play in your browser on itch.io: https://hammadfaizvi.itch.io/the-right-angle**

The Right Angle is a desk-based light manipulation puzzle built in Godot 4.7
with the Compatibility renderer. You are a photo editor. Place lamps, torches
and other tools around each photograph so the printed shadows tell the right
story, and keep Halcyon in the right light. Successful editions always earn
positive editor feedback and public reaction.

The campaign has **eight cases and twenty-two photographs**: The Hero, The
People's Hero, Above the Lake, Keeping the Peace, The Rescue, The Bank,
Assembly Square and The Factory.

## Team

| | |
|---|---|
| **Team name** | Shift-Zero |
| **Members** | Hammad Faizvi ([@HammadFaizv](https://github.com/HammadFaizv)), solo developer |
| **Repository** | https://github.com/HammadFaizv/Shift-zero |
| **IndieConnect** | https://www.indieconnect.in/@hammadfaizvi |

## Setup and run

### Play online

Open the [itch.io page](https://hammadfaizvi.itch.io/the-right-angle). It
needs a desktop browser with a mouse and keyboard.

### Run from source

1. Install **Godot 4.7** (standard build, not .NET): https://godotengine.org/download
2. Clone the repository:
   ```sh
   git clone https://github.com/HammadFaizv/Shift-zero.git
   cd Shift-zero
   ```
3. Open the project in Godot: from the Project Manager choose **Import** and
   select `project.godot`, or run `godot --path . --editor`.
4. Press **F5** (or run `godot --path .`) to start at the main menu.

**Play** opens the illustrated tutorial. **Settings** saves music/effects
volume and mute. The desk's **Menu** button lets you resume, change sound, or
replay How to play. F6 on `scenes/main.tscn` opens the gameplay scene directly
and skips the menu.

### Build for the Web

```sh
# Only if the matching export templates are missing:
python3 tools/download_web_templates.py

python3 tools/build_web.py     # or: --godot /path/to/godot
python3 tools/serve_web.py     # serves builds/web at http://127.0.0.1:8060/index.html
```

This writes `builds/web/` and the itch.io-ready `builds/the-right-angle-web.zip`.
Serve the export over HTTP instead of opening the HTML file directly. See
[Web export / itch.io](docs/web-export.md) for the upload settings.

### Run the tests

```sh
godot --headless --path . --script tests/endings.gd
godot --headless --path . --script tests/stages_7_8.gd
godot --headless --path . --script tests/stage_photos.gd
```

## Controls

| Action | Input |
|---|---|
| Move a tool | Click and drag |
| Aim the selected lamp/torch | **Q** / **E**, the mouse wheel, or the gold rotation handle |
| Switch the ceiling light (Cases 1–2) | **L** or the red cord |
| Switch a torch on/off | **Space** or double-click |
| Deselect | Right-click or **Esc** |
| Show light readings | **F1** |
| Mute / unmute sound | **M** |
| Toggle targets | Checkbox on the right panel |

The right panel shows the editor's instruction, live captions and the SPUN
count. Purple previews the printed shadow.

## How to play

The editor's grease-pencil marks show what each subject needs:

- A gold sun means it still needs light.
- A red open eye means it is exposed.
- A tick or a slashed eye means it is settled.
- A heavier line or a double loop marks a subject that would hurt Halcyon
  badly if it printed.

When the desk is ready:

- **Publish** opens a comic proof. **Keep editing** returns to the desk;
  **Publish this comic** confirms publication and the public reaction.
- **Replay printing** repeats the reveal. **Back to desk** keeps your tool
  positions.
- **Next case** unlocks after CHARMED or ADORING. DIVIDED needs another pass.
  Anything below DIVIDED shows the bad ending and returns to the same desk
  with a new editor name.
- **Restart case** resets the current page.
- Clear all eight cases above DIVIDED for the two-page good ending, then use
  **Replay game**.

## More documentation

[Main menu and tutorial](docs/main-menu.md) ·
[Proofs and endings](docs/endings.md) ·
[Case layouts and checks](docs/seven-cases.md) ·
[Stages 7–8](docs/stages-7-8.md) ·
[Every current POI](docs/tutorial-pois.md) ·
[SVG editing](docs/evidence-scenes.md) ·
[Reputation points and sound](docs/reputation.md) ·
[Tuning defaults](docs/tuning.md) ·
[Web export / itch.io](docs/web-export.md) ·
[Project brief](DESIGN.md)

## Credits and license

Third-party models, fonts and audio are credited in [CREDITS.md](CREDITS.md).
The project is released under the terms in [LICENSE](LICENSE).
