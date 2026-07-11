---
name: test
description: Run the Pixel Dragon City headless Godot test suite (all tests, or one by name) and report pass/fail. Use when asked to run tests, verify a change, or check a specific test script.
---

# Run headless Godot tests

Tests live in `godot/scripts/tests/*.gd`. Each is a SceneTree script that calls `quit(0)` on PASS and `quit(1)` on failure, and may write screenshots to `/private/tmp/`. There is no external test framework — exit code is the source of truth.

Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot`

## Run one test
Given a name like `combat_flow` (with or without `_test.gd`):
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/<name>.gd
echo "exit: $?"
```
Report PASS if exit code is 0, FAIL otherwise, and surface any error lines from the log.

## Run the full suite
Run each script in `godot/scripts/tests/` and collect exit codes:
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
for f in godot/scripts/tests/*.gd; do
  name="res://scripts/tests/$(basename "$f")"
  "$GODOT" --headless --path godot --script "$name" >/tmp/pdc_test.log 2>&1
  code=$?
  [ $code -eq 0 ] && echo "PASS  $(basename "$f")" || { echo "FAIL($code)  $(basename "$f")"; tail -20 /tmp/pdc_test.log; }
done
```
Note: some scripts (e.g. `swordsman_walk_audit_image.gd`, `visual_snapshot_test.gd`) are image/snapshot generators rather than pass/fail assertions — treat a clean exit as success and mention the artifact path if one is printed.

Finish with a one-line summary: how many passed / failed and which failed.
