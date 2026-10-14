# Demo validation — refinement pass, 7 October 2026

- Godot 4.7.2, GDScript, Compatibility renderer; single-threaded WebGL 2 export.
- 25 economy/state checks passed, including crop growth, animal maturity, premium yields, meat/live animal sales, storage, upgrades, seasons, and isolated save/reload.
- 35 integration checks passed: animal forward direction during turns, fixed signs, roads clear of trees/benches/walls/fences, playable farming loop, shop purchases, selected-quantity sale preserving remaining inventory, FPS/TPS, actual vehicle movement and acceleration, walking/ground collision, dark night/lantern/daytime sun, Xbox tool selection/input hint switching, and NPC greeting proximity.
- All 20 animated GLBs validated with skins, skeletons, Idle/Walk and Use/Eat; textures <=512 pixels.
- Native rendered previews inspected: farm, crops, animals, village, market, settings, title and night. Fixed plot mesh winding and background fog during visual QA. Shop animal icons rendered directly from game models.
- Final native benchmark: NVIDIA RTX 4050 Laptop GPU, about 60 FPS, 6.93 ms process, 0.92 ms physics, 278 draw calls in the starter farm view. The same refinement view before bed batching/distant NPC culling recorded 442 draw calls. Values are scene/hardware specific.
- Local browser release opened and exercised: saved-game continuation, walking, camera mode switch, inventory, pause/settings, automatic 3D resolution, mouse look without right-button hold. Existing browser save was readable after updates.
- The Codex browser reports Intel UHD through ANGLE. High-quality/automatic-resolution tests still showed roughly 17–22 FPS in the tested views; this is not a claim that browser performance matches the Windows build. Lower quality remains available. External Chrome and other hosted/device combinations were not measured in this pass.
- The embedded Chromium reported a pointer-lock UnknownError; the game keeps mouse-motion and arrow-key fallback available. Native locking/browser permission behavior should be checked on the final hosting browser.
- Controller button behavior is covered by synthetic input checks. Physical controller feel and device-specific behavior were not hands-on validated; vibration is not implemented.
- The demo uses arcade vehicle physics and basic animation rigs. Headless tests skip audio; normal renderer/web exercise the generated audio assets.
- Release ZIPs are integrity checked and source/delivery hashes matched. Player saves remain outside the delivered project folders.

