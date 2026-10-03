# Desk camera and green ceiling lamp

The camera sits at **24° from vertical**, using an orthographic projection to
avoid tapering the photographs. Its vertical size is **7.8 world units**. The
page fills about 500 pixels of height at 1280×720, with its heading, photographs
and footer visible between the screen heading and control hints.

`scripts/ui/desk_camera.gd` centres the page in the playable area whenever the
overlay resizes. It reserves **24% of the screen width** for the story/status
strip, including the right margin. The actual status panel occupies about 22%
at 1280×720. Tune the camera angle, height, page offset and reserved fraction in
the Camera3D Inspector; change the built-in `size` property to zoom.

The ceiling fixture now has a rectangular green enamel shade, brass trim and
end caps, and a warm rectangular diffuser. It hangs above the upper-right edge
of the page, with its red pull cord beside the page so it does not cover the
photographs. The ceiling light remains a broad gameplay light. The torch beam
and physical 4/4 solution retain their previous tuning.

## Files created or changed

- `scripts/ui/desk_camera.gd`: responsive fixed camera composition.
- `scenes/main.tscn`: angled camera, closer framing and proportional sidebar.
- `scenes/lighting/ceiling_light.tscn`: green box fixture and visible pull cord.
- `scenes/desk/desk.tscn`: updated ceiling-light instruction on the sticky note.
- `tests/vertical_slice.gd`: framing, sidebar width and photo readability checks.
- `tools/dump_tuning.gd`: uses the authored desktop size for responsive defaults.
- `docs/tuning.md`: regenerated Inspector values.
- These notes, linked from `docs/steps-6-10.md` and `docs/web-export.md`.
- `docs/previews/composition-desk.png`, `composition-solution.png`, and
  `composition-wide.png`: browser previews.
- `builds/web/` and `builds/the-right-angle-web.zip`: rebuilt Web release.

No new scene was added. The existing ceiling-light scene now contains:

```text
CeilingLight (Node3D)
├── Shade (MeshInstance3D, green BoxMesh)
├── Rim (MeshInstance3D, brass BoxMesh)
├── Diffuser (MeshInstance3D, warm BoxMesh)
├── LeftEndCap (MeshInstance3D)
├── RightEndCap (MeshInstance3D)
├── VisualLight (OmniLight3D)
├── PullCord (Node3D)
│   ├── Cord (MeshInstance3D)
│   └── Handle (StaticBody3D)
│       ├── Knob (MeshInstance3D)
│       └── CollisionShape3D
├── Status (Label3D)
└── GameplayLight (Node3D)
```

## Testing

Press **F5** to run the project. Study the page with the ceiling light on, then
press **L** or click the **red pull cord** to switch it off. Drag the torch and
paperweights; select the torch and use **Q/E** or the **mouse wheel** to aim it,
and **Space** or a **double-click** to toggle it. **Esc/right-click** deselects.
Publish, replay printing and return to confirm that tool positions are retained.
Resize the desktop window or enter fullscreen to check page/sidebar framing.

The integration check verifies the page stays beside the sidebar and inside
the heading/hint margins at 1280×720 and 1920×1080. Each photograph must remain
over 160 logical pixels wide, have equal top/bottom widths, and retain at least
85% of its original aspect ratio after camera tilt. It also checks picking,
dragging, the physical 4/4 solution and the full publish/replay/return loop.

See [desk preview](previews/composition-desk.png),
[solved desk](previews/composition-solution.png), and
[1920×1080 preview](previews/composition-wide.png).

Headless and rendered integration checks passed. The final Web release passed
the Chrome GPU test with actual drag/rotate input, 4/4 SPUN, ADORING 100/100,
publishing/replay/return and 1920×1080 resizing, without runtime or browser
errors. Its ZIP contents were checked against the exact browser-tested files.

No remaining issue is known with this composition change. Existing placeholder
art, desktop mouse/keyboard controls and deferred later cases/audio still apply.
