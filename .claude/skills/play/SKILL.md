---
name: play
description: Launch Pixel Dragon City in the Godot editor/GUI for visual validation, or capture a headless screenshot. Use when asked to run the game, play it, do the "GUI check", or see how a change looks on screen.
---

# Launch the game for visual validation

Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot`. Main scene: `res://scenes/main.tscn`.

## Run the game (GUI)
The owner does a manual "10-minute GUI acceptance" pass on gameplay changes. Launch the running game window:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot res://scenes/main.tscn
```
This opens a real window — the user drives it. Don't block waiting on it; tell them it's launched and what to look for given the change you made.

## Open the editor
```bash
/Applications/Godot.app/Contents/MacOS/Godot --editor --path godot
```

## Headless screenshot (for when you need to see it yourself)
The repo already has snapshot tests that render PNGs to `/private/tmp/`. Prefer running the relevant one via `/test` (e.g. `visual_snapshot_test`, `hud_responsive_layout_test`) and then Read the produced PNG to inspect it, rather than hand-rolling a capture.

After a visual change, state which scene/panel to look at and what should have changed.
