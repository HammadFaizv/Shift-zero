# Main menu and tutorial

Previews: [main menu](previews/main-menu.png), [tutorial](previews/how-to-play.png),
[settings](previews/settings.png).

Added files: `scenes/ui/start_screen.tscn`, `scripts/ui/start_screen.gd`,
`scripts/game/player_settings.gd`, four `Assets/ui/tutorial/*.svg` diagrams,
`tests/start_screen.gd` and this guide. Updated `project.godot`,
`scripts/game/audio_hub.gd` and `README.md`.

F5 opens `scenes/ui/start_screen.tscn`. The existing `scenes/main.tscn` remains
the gameplay scene, so opening it directly with F6 bypasses the menu.

Play shows four illustrated tutorial pages: moving/aiming the torch, lighting
subjects and casting shadows, publishing the comic, and public opinion.
Back/Next navigate; Start my shift or Skip tutorial enters the first case.
The tutorial appears each fresh launch and can be replayed with How to play.

The translucent menu leaves the desk visible while suspending desk processing
and input. The desk's Menu button opens Settings or How to play during a case;
Resume preserves the current case, tools and burns.

Settings provides independent music/effects sliders and mute. Preferences save
to `user://settings.cfg`. M toggles the same saved mute setting during play.
This saves audio preferences, not campaign progress. Browser storage must be
retained for those preferences to survive a later visit.

The four SVG diagrams are editable in `Assets/ui/tutorial/`. They use explicit
arrowhead polygons because SVG marker arrowheads do not render in Godot's importer.
Menu dimensions, transparency and picture height are exported on StartScreen.
The card scrolls when its contents exceed the available window height.

Scene tree:

```text
StartScreen
├── Desk (existing main.tscn)
└── MenuLayer (CanvasLayer)
    └── Control (runtime)
        ├── ColorRect (translucent backdrop)
        └── PanelContainer
            └── ScrollContainer
                └── VBoxContainer (menu/settings/tutorial)
```

Verification: `godot --headless --path . --script tests/start_screen.gd` checks
menu navigation, four tutorial images, saved slider values, paused gameplay,
restored controls, preserved case/tool state and publishing after the tutorial.
