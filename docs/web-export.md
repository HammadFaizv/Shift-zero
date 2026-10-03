# Web export and itch.io

The current release contains the [seven tutorial cases](seven-cases.md),
[thirteen composed SVG photographs](evidence-scenes.md), the angled desk camera
and green rectangular ceiling fixture. The former five-case campaign and its
original-photo ending are excluded from this release.

Use Godot **4.7.2** with the matching downloaded templates. The Web preset uses
Compatibility, the official single-threaded runtime and adaptive canvas sizing.
No cross-origin isolation headers or SharedArrayBuffer setting are needed.
[Godot Web export documentation](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html).

## Ready-to-upload archive

`builds/the-right-angle-web.zip` is approximately **12.0 MiB** and contains
`index.html` at its root with the matching JS/WASM/PCK, worklets, icons, credits
and font licenses. Build outputs/templates are ignored by Git and reproducible.

On itch.io:

1. Set the project kind to **HTML Game**.
2. Upload `the-right-angle-web.zip` and mark it playable in the browser.
3. Use **1280 × 720**, **Click to play** and the **Fullscreen button**.
4. Leave **SharedArrayBuffer support** and **Mobile friendly** off; controls
   require a desktop mouse and keyboard.
5. Preview publishing, returning and advancing through the cases.

Settings follow the [itch.io HTML5 guide](https://itch.io/docs/creators/html5).
The release is tested locally; no itch.io account upload was performed.

## Build and verify

```sh
# Needed only if the matching local templates are absent:
python3 tools/download_web_templates.py

python3 tools/build_web.py
# Or: python3 tools/build_web.py --godot /path/to/godot
python3 tools/serve_web.py
```

Open `http://127.0.0.1:8060/index.html`. The server binds only loopback and uses
ordinary HTTP. Serve the exported build instead of opening the HTML as a file.

The active native regression is:

```sh
godot --headless --path . --script tests/seven_cases.gd
```

It checks all seven solutions, one/two/three-photo layouts, live POI replacement,
the real paperweight shadow, positive rewards, frozen ink, ordinary publication
and return/progression. The desktop camera is checked at 1280 × 720 and
1920 × 1080. A perfect edition always scores ADORING 100/100.

After the native test creates `/tmp/shift-zero-seven-inputs.json`, run the
server and the browser check:

```sh
npm --prefix /tmp/shift-zero-browser install playwright-core
NODE_PATH=/tmp/shift-zero-browser/node_modules node tests/web_seven_cases.cjs
# Desktop GPU when a display is available:
WEB_GPU=hardware NODE_PATH=/tmp/shift-zero-browser/node_modules node tests/web_seven_cases.cjs
```

The browser check uses actual drags and aim handles, prints all seven editions,
replays the reveal, returns to each solved desk and advances normally through
Case 7. It saves `/tmp/shift-zero-web-seven-*.png` and fails on browser/runtime
console errors. Screenshots are inspected for the expected SPUN counts and
positive results. It uses native-derived coordinates, with no test bridge in
the game. The ZIP is checked for CRC errors and against the exported files.

Historical five-case/Step 10 timing reports are not benchmarks of this campaign.
Current defaults and per-case overrides are listed in [tuning.md](tuning.md).
