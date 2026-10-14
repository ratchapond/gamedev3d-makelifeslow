# Make Life Slower

A cozy 3D farming game for desktop web browsers, made with Godot.

[Play on GitHub Pages](https://ratchapond.github.io/gamedev3d-makelifeslow/)

## Current version

This is the tested playtest snapshot from source commit `2c0749f02cf62102300f3e1a70ab07ac3888ca00`.
It keeps the existing people and animal models, with no further model redesign.

- Full development map and assets, 20 rigged people/animal models, material detail,
  blinking, grazing, breathing and sitting on benches.
- Bushes and ground plants keep their complete footprint clear of roads;
  ground flowers are reduced by about half.
- Physical E works on Thai and English keyboard layouts for animal interactions.
- Cow/goat milking: drag down/up four times, with arrow/button alternatives.
- Wandering neighbours offer trades, gifts, loans and kindness surprises.
  Offers and debts survive saves; lenders return after two game days.

## Editable source

- `game/`: complete Godot project, source scripts, assets and tests.
- `art-source/`: supplied original Blender files and GLBs; `refined/` contains
  the editable rigs used by this build.
- `tools/`: material generation, rig refinement, model rendering and web packaging.
- `docs/`: ready-to-host web release plus existing model reference galleries.

Open `game/project.godot` in Godot. Regenerate shared character normal maps with
`python3 tools/character_textures.py` (NumPy/Pillow), and refine the original rigs
with `blender --background --factory-startup --disable-autoexec --python tools/refine_characters.py`.
The original Blender sources use 5.2; the refined rigs use 4.3.

## Web build and hosting

Run `python3 tools/build_web.py` with Godot and its matching Web export template
installed. This snapshot was packed with Godot 4.6.3 and the supplied Web 4.7.2
engine. The script retains that engine and writes the pack and loader into `docs/`.
When upgrading Godot, update the engine export and loader sizes together.

GitHub Pages uses **main → /docs**. The loader decompresses `index.wasm.gz` and the
versioned `.pck.gz.partNN` files with browser `DecompressionStream`; keep all parts,
`wasm-loader.js` and `index.html` together. No Node build is required.

Browser saves keep their existing format. Saves are local to each browser/origin,
so the Codex playtest and GitHub Pages have separate saves.

## Controls

WASD move; mouse look; Shift run; E interact; 1–4 tools; V FPS/TPS;
I inventory; M map; L lantern; Esc menu. Xbox: sticks move/look, A interact,
X use, Y inventory, shoulders tools, Start pause.

## Verification

Headless suites live in `game/tests/`: integration, localization, slow_life,
interaction_and_paths and visitors. Run, for example:

```sh
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tests/visitors.gd
```

The released snapshot passed the native suites and Chromium WebGL checks for
Thai-layout E, four-stroke milking, visitor approach/reward and clear roads.
Performance on the player's device should be measured in the game.

Third-party license notices are included in `docs/LICENSES.md` and the assets.
