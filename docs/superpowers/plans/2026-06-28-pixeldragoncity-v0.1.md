# Pixel Dragon City v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable Godot 4 prototype where a player can move around a test map with camera follow.

**Architecture:** Keep v0.1 small: one main scene, one player scene, one camera, and one test map. Put reusable logic in focused scripts under `godot/scripts/`, and leave combat, inventory, and save systems for later roadmap tasks.

**Tech Stack:** Godot 4.x, GDScript, 2D scene system, JSON data files in the repository root.

---

## File Structure

- Create: `godot/project.godot` - Godot project manifest.
- Create: `godot/scenes/main.tscn` - boot scene that instances the test map and player.
- Create: `godot/scenes/actors/player.tscn` - player body, collision, camera, and visual placeholder.
- Create: `godot/scenes/maps/test_map.tscn` - simple graybox map for movement testing.
- Create: `godot/scripts/actors/player_controller.gd` - keyboard movement logic.
- Create: `godot/scripts/game/main.gd` - main scene setup.
- Modify: `TODO.md` - mark v0.1 implementation steps as complete as they land.
- Modify: `docs/DevLog.md` - append the development result.

## Task 1: Create Godot Project Shell

**Files:**

- Create: `godot/project.godot`
- Create: `godot/scenes/main.tscn`
- Create: `godot/scripts/game/main.gd`

- [x] **Step 1: Create folders**

Run:

```bash
mkdir -p godot/scenes/actors godot/scenes/maps godot/scripts/actors godot/scripts/game
```

Expected: folders exist under `godot/`.

- [x] **Step 2: Create the Godot project manifest**

Write `godot/project.godot`:

```ini
; Engine configuration file.
; It is best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.

config_version=5

[application]

config/name="Pixel Dragon City"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.0")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
```

- [x] **Step 3: Create the main script**

Write `godot/scripts/game/main.gd`:

```gdscript
extends Node2D


func _ready() -> void:
	print("Pixel Dragon City v0.1 prototype loaded")
```

- [x] **Step 4: Create an empty main scene**

Create `godot/scenes/main.tscn` with a `Node2D` root named `Main`, attach `res://scripts/game/main.gd`, and save.

- [x] **Step 5: Verify project opens**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot --editor
```

Expected: Godot opens the project without import or scene errors.

## Task 2: Add Player Movement

**Files:**

- Create: `godot/scenes/actors/player.tscn`
- Create: `godot/scripts/actors/player_controller.gd`
- Modify: `godot/scenes/main.tscn`

- [x] **Step 1: Create player controller script**

Write `godot/scripts/actors/player_controller.gd`:

```gdscript
extends CharacterBody2D

@export var move_speed: float = 120.0


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()
```

- [x] **Step 2: Create player scene**

Create `godot/scenes/actors/player.tscn`:

- Root: `CharacterBody2D` named `Player`
- Script: `res://scripts/actors/player_controller.gd`
- Child: `ColorRect` named `PlaceholderSprite`, size `Vector2(24, 32)`, position `Vector2(-12, -24)`
- Child: `CollisionShape2D` named `CollisionShape2D`, rectangle shape size `Vector2(18, 24)`
- Child: `Camera2D` named `Camera2D`, set `enabled = true`, `position_smoothing_enabled = true`

- [x] **Step 3: Instance the player in main scene**

Open `godot/scenes/main.tscn`, instance `res://scenes/actors/player.tscn`, and set `Player.position = Vector2(160, 120)`.

- [x] **Step 4: Verify movement**

Run the project from Godot.

Expected:

- `W` moves up.
- `A` moves left.
- `S` moves down.
- `D` moves right.
- Diagonal movement is not faster than straight movement because `Input.get_vector` normalizes input.

## Task 3: Add Test Map and Boundaries

**Files:**

- Create: `godot/scenes/maps/test_map.tscn`
- Modify: `godot/scenes/main.tscn`

- [x] **Step 1: Create test map scene**

Create `godot/scenes/maps/test_map.tscn`:

- Root: `Node2D` named `TestMap`
- Child: `ColorRect` named `Ground`, size `Vector2(1600, 1000)`, position `Vector2(-800, -500)`, color dark green or gray
- Child nodes: four `StaticBody2D` boundary walls with `CollisionShape2D`

- [x] **Step 2: Boundary dimensions**

Use these wall collision rectangles:

```text
Top wall:    position Vector2(0, -520), size Vector2(1640, 40)
Bottom wall: position Vector2(0, 520),  size Vector2(1640, 40)
Left wall:   position Vector2(-820, 0), size Vector2(40, 1040)
Right wall:  position Vector2(820, 0),  size Vector2(40, 1040)
```

- [x] **Step 3: Instance test map before player**

Open `godot/scenes/main.tscn`, instance `res://scenes/maps/test_map.tscn`, and place it before the player node in the tree.

- [x] **Step 4: Verify collision**

Run the project and move toward all four edges.

Expected: player cannot leave the test map boundaries.

## Task 4: Update Project Documentation

**Files:**

- Modify: `TODO.md`
- Modify: `docs/DevLog.md`

- [x] **Step 1: Update TODO**

Mark these items complete:

```markdown
- [x] 创建 Godot 4 项目
- [x] 创建主场景
- [x] 创建测试地图
- [x] 创建玩家场景
- [x] 实现玩家八方向移动
- [x] 实现相机跟随
```

- [x] **Step 2: Append DevLog**

Add a new entry to `docs/DevLog.md`:

```markdown
## 2026-06-28 v0.1 可移动原型

完成：

- 创建 Godot 4 工程。
- 创建主场景、玩家场景和测试地图。
- 实现 WASD 八方向移动。
- 实现 Camera2D 跟随玩家。
- 实现测试地图边界碰撞。

待完成：

- 玩家动画。
- 基础攻击。
- 怪物生命值和追踪 AI。
```

- [x] **Step 3: Final manual verification**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot
```

Expected:

- Project starts.
- Main scene loads.
- Player moves with WASD.
- Camera follows.
- Player cannot leave the test map.

## Plan Self-Review

- Spec coverage: v0.1 roadmap items are covered by Tasks 1 to 4.
- Placeholder scan: no task uses unspecified implementation placeholders.
- Type consistency: scene paths, script paths, and input action names are consistent across all tasks.
