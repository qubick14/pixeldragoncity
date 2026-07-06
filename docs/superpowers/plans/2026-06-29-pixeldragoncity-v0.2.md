# Pixel Dragon City v0.2 Combat Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable combat loop where the player can attack a wild wolf, the wolf can chase and damage the player, and death is visible and testable.

**Architecture:** Keep combat modular and data-ready. Put reusable combat state in focused scripts under `godot/scripts/combat/`, monster behavior under `godot/scripts/actors/`, and UI feedback under `godot/scripts/ui/`. v0.2 should use existing JSON ids and stats where useful, but it does not need to complete the full v0.3 item/drop pipeline.

**Tech Stack:** Godot 4.x, GDScript, CharacterBody2D, Area2D hitboxes/hurtboxes, Control-based health bars, repository JSON design data.

---

## Current Baseline

v0.1 is complete. The current Godot project already includes:

- `godot/project.godot`
- `godot/scenes/main.tscn`
- `godot/scenes/actors/player.tscn`
- `godot/scenes/maps/test_map.tscn`
- `godot/scenes/ui/hud.tscn`
- `godot/scenes/ui/menu_overlay.tscn`
- `godot/scripts/actors/player_controller.gd`
- `godot/scripts/tests/player_input_and_ui_test.gd`

Relevant design data already exists:

- `data/monsters.json` contains `wild_wolf` with hp, attack, defense, speed, exp, gold, and planned drops.
- `docs/05_Combat.md` defines the MVP damage formula and v0.2 monster AI states.
- `docs/07_Monsters.md` defines the wild wolf as the first formal combat monster.

## File Structure

- Create: `godot/scripts/combat/health_component.gd` - owns max/current HP, damage, healing, death signal.
- Create: `godot/scripts/combat/hitbox.gd` - describes outgoing attack damage and attacker ownership.
- Create: `godot/scripts/combat/hurtbox.gd` - receives hitbox overlaps and forwards damage to a health component.
- Create: `godot/scripts/combat/damage_number.gd` - short-lived floating damage label.
- Create: `godot/scenes/ui/health_bar.tscn` - reusable world-space health bar.
- Create: `godot/scripts/ui/health_bar.gd` - binds a health component to the bar.
- Create: `godot/scenes/actors/wild_wolf.tscn` - first monster scene.
- Create: `godot/scripts/actors/wild_wolf_controller.gd` - idle, chase, attack, hurt, dead behavior.
- Create: `godot/scripts/tests/combat_component_test.gd` - headless tests for HP and damage rules.
- Create: `godot/scripts/tests/combat_flow_test.gd` - headless tests for player hitbox, wolf damage, and death flow.
- Modify: `godot/scenes/actors/player.tscn` - add health component, hurtbox, attack hitbox, and health bar nodes.
- Modify: `godot/scripts/actors/player_controller.gd` - add attack input, cooldown, and hitbox timing without breaking movement.
- Modify: `godot/scenes/main.tscn` - instance one wild wolf in the test map.
- Modify: `godot/scenes/ui/hud.tscn` - expose player HP in the bottom HUD.
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd` - keep existing v0.1 behavior covered after combat nodes are added.
- Modify: `TODO.md` - mark v0.2 items as complete only after implementation and verification.
- Modify: `docs/DevLog.md` - append the v0.2 implementation result after tests pass.

## Combat Constants for v0.2

Use these starter values unless the user requests balance changes:

| Entity | max_hp | attack | defense | speed |
| --- | ---: | ---: | ---: | ---: |
| Player | 100 | 12 | 2 | existing movement speeds |
| Wild Wolf | 50 | 8 | 1 | 70 |

Use this damage formula from `docs/05_Combat.md`:

```text
final_damage = max(1, attacker.attack - defender.defense)
```

v0.2 does not need critical hits, skill multipliers, equipment modifiers, random hit chance, real drop spawning, or experience gain. Those belong to v0.3+ unless explicitly requested.

## Task 1: Health Component

**Files:**

- Create: `godot/scripts/combat/health_component.gd`
- Create: `godot/scripts/tests/combat_component_test.gd`

- [ ] **Step 1: Write the health component test**

Create `godot/scripts/tests/combat_component_test.gd` as a headless `SceneTree` test. Cover these behaviors:

- new component starts at `max_hp`
- damage reduces `current_hp`
- damage is clamped at 0
- `died` emits once
- healing cannot exceed `max_hp`

- [ ] **Step 2: Run the test and verify it fails because the component does not exist**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
```

Expected: FAIL because `res://scripts/combat/health_component.gd` cannot be loaded.

- [ ] **Step 3: Implement `HealthComponent`**

Implement focused state and signals:

- `health_changed(current_hp, max_hp)`
- `damaged(amount, source)`
- `healed(amount)`
- `died(source)`
- `setup(new_max_hp, new_defense)`
- `apply_damage(raw_attack, source)`
- `heal(amount)`
- `is_dead()`

- [ ] **Step 4: Re-run the component test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
```

Expected: output contains `combat_component_test: PASS`.

## Task 2: Hitbox and Hurtbox

**Files:**

- Create: `godot/scripts/combat/hitbox.gd`
- Create: `godot/scripts/combat/hurtbox.gd`
- Modify: `godot/scripts/tests/combat_component_test.gd`

- [ ] **Step 1: Extend the component test**

Add coverage for an `Area2D` hitbox overlapping a hurtbox and applying damage to the target health component.

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
```

Expected: FAIL because hitbox/hurtbox scripts are missing.

- [ ] **Step 3: Implement hitbox and hurtbox scripts**

Implementation rules:

- `Hitbox` stores `attack`, `owner_node`, and `enabled`.
- `Hurtbox` exports a `NodePath` to its `HealthComponent`.
- `Hurtbox` ignores disabled hitboxes.
- `Hurtbox` ignores hitboxes owned by the same actor.
- `Hurtbox` calls `health_component.apply_damage(hitbox.attack, hitbox.owner_node)`.

- [ ] **Step 4: Re-run the test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
```

Expected: output contains `combat_component_test: PASS`.

## Task 3: Player Attack

**Files:**

- Modify: `godot/project.godot`
- Modify: `godot/scenes/actors/player.tscn`
- Modify: `godot/scripts/actors/player_controller.gd`
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd`

- [ ] **Step 1: Add an attack input test**

Extend `player_input_and_ui_test.gd` to confirm:

- player has a `HealthComponent`
- player has a disabled `AttackHitbox` by default
- calling `start_attack()` enables the attack hitbox briefly
- attack cooldown prevents immediate repeat attacks

- [ ] **Step 2: Run the player test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: FAIL because player combat nodes and methods do not exist yet.

- [ ] **Step 3: Add combat nodes to the player scene**

Add these children to `Player`:

- `HealthComponent`
- `Hurtbox` with a compact collision shape around the body
- `AttackHitbox` as `Area2D`, disabled by default
- `AttackShape` sized for a short melee arc in front of the player

- [ ] **Step 4: Add player attack logic**

Update `player_controller.gd` with:

- exported `attack: int = 12`
- exported `defense: int = 2`
- exported `attack_cooldown: float = 0.55`
- exported `attack_active_time: float = 0.12`
- `start_attack()`
- attack timer and cooldown timer
- attack hitbox positioning based on `facing_direction`

Keep existing WASD movement, mouse move, right-click run, long-press movement, animation key logic, and camera behavior intact.

- [ ] **Step 5: Re-run v0.1 behavior tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: output contains `player_input_and_ui_test: PASS`.

## Task 4: Wild Wolf Monster

**Files:**

- Create: `godot/scenes/actors/wild_wolf.tscn`
- Create: `godot/scripts/actors/wild_wolf_controller.gd`
- Create: `godot/scripts/tests/combat_flow_test.gd`
- Modify: `godot/scenes/main.tscn`

- [ ] **Step 1: Write the combat flow test**

Create `combat_flow_test.gd` to instantiate a player and wild wolf, then verify:

- wild wolf starts alive with 50 HP
- wild wolf enters chase range when the player is nearby
- player attack reduces wolf HP
- repeated attacks can kill the wolf
- dead wolf disables collision and stops chasing

- [ ] **Step 2: Run the flow test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected: FAIL because the wolf scene and controller do not exist yet.

- [ ] **Step 3: Create `wild_wolf.tscn`**

Scene requirements:

- root `CharacterBody2D` named `WildWolf`
- `HealthComponent`
- `Hurtbox`
- `AttackHitbox`
- `CollisionShape2D`
- visible sprite using `godot/assets/sprites/monster_sheet.png`
- reusable health bar instance

- [ ] **Step 4: Implement wolf controller**

State machine:

- `IDLE`: no target in aggro range
- `CHASE`: move toward player when within aggro range
- `ATTACK`: enable hitbox when in attack range and cooldown is ready
- `HURT`: brief pause after taking damage
- `DEAD`: disable hitboxes, hurtbox, movement, and collision

Starter constants:

- aggro range: 280 px
- attack range: 42 px
- attack cooldown: 0.9 s
- attack active time: 0.16 s
- hurt pause: 0.18 s

- [ ] **Step 5: Instance one wolf in the test map**

Modify `main.tscn` so the v0.2 test map starts with one `WildWolf` positioned far enough from spawn that the player can approach it intentionally.

- [ ] **Step 6: Re-run the flow test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected: output contains `combat_flow_test: PASS`.

## Task 5: Health Bars and Damage Feedback

**Files:**

- Create: `godot/scenes/ui/health_bar.tscn`
- Create: `godot/scripts/ui/health_bar.gd`
- Create: `godot/scripts/combat/damage_number.gd`
- Modify: `godot/scenes/actors/player.tscn`
- Modify: `godot/scenes/actors/wild_wolf.tscn`
- Modify: `godot/scenes/ui/hud.tscn`

- [ ] **Step 1: Add UI expectations to tests**

Extend tests to confirm:

- player and wolf each have a health bar node
- health bar value changes after damage
- HUD can display player HP as text or bar
- damage number nodes auto-remove after their lifetime

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected: FAIL because health bar and damage number behaviors are not wired yet.

- [ ] **Step 3: Implement reusable health bar**

Use a compact `Control` scene with a background and foreground bar. It should expose:

- `bind(health_component)`
- `set_health(current_hp, max_hp)`

- [ ] **Step 4: Implement damage numbers**

Use a `Label`-based node that:

- displays integer damage
- floats upward briefly
- fades out
- queues itself free

- [ ] **Step 5: Wire feedback into player and wolf**

On damage:

- update health bars
- spawn a damage number above the target
- pause wolf briefly when hurt

- [ ] **Step 6: Re-run flow and v0.1 tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected:

- `combat_flow_test: PASS`
- `player_input_and_ui_test: PASS`

## Task 6: Documentation and Manual Verification

**Files:**

- Modify: `TODO.md`
- Modify: `docs/DevLog.md`
- Modify: `docs/11_DevelopmentPlan.md` if v0.2 scope changes during implementation.

- [ ] **Step 1: Run final automated checks**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected:

- prototype loads without scene errors
- v0.1 player/input/UI behavior still passes
- combat component tests pass
- combat flow tests pass

- [ ] **Step 2: Run manual play check**

Open the project with Godot and verify:

- player can still move with WASD
- left click walk and right click run still work
- player can approach the wolf
- player attack visibly damages the wolf
- wolf chases and damages the player
- both health bars update
- wolf death is clear

- [ ] **Step 3: Update TODO and DevLog**

Only after the above checks pass:

- mark completed v0.2 items in `TODO.md`
- append a dated implementation entry to `docs/DevLog.md`
- include exact verification commands and results

## Plan Self-Review

- Spec coverage: v0.2 roadmap items are covered by Tasks 1 to 6: health, hit detection, melee attack, wolf chase, death, health bars, damage feedback, tests, and docs.
- Placeholder scan: no task relies on unspecified future systems such as inventory, drops, experience, or save data.
- Type consistency: script names, scene paths, and test paths are consistent with the current Godot directory layout.
- Scope boundary: v0.2 intentionally stops before real drops, equipment stat calculation, skill bar, NPCs, shops, map switching, and saves.

## 2026-07-02 Execution Addendum

This addendum clarifies how to move from planning into implementation. It does not expand v0.2 scope.

### Approved Scope

v0.2 builds only the first playable combat loop:

- player HP and wolf HP
- player melee hit detection
- wild wolf hurtbox and HP reduction
- wild wolf chase and close-range attack
- player damage from wolf attacks
- wolf death and disabled combat behavior
- player HUD HP feedback
- wolf world health bar
- basic damage numbers or equivalent hit feedback
- automated component and flow tests

Do not implement these systems in v0.2:

- real loot spawning
- inventory or equipment
- experience gain or leveling
- skill bar UI
- NPCs, shops, quests, map switching, save/load
- final art replacement

### Recommended Input Decision

Use keyboard attack input for v0.2:

- Action name: `attack_primary`
- Suggested key: `J`
- Optional second key: `Space`

Do not bind left mouse button to attack in v0.2 because left click is already part of the completed click-to-move behavior.

### Development Gate Order

Each gate should pass before starting the next one.

1. **Combat component gate**
   - Implement `HealthComponent`.
   - Implement damage clamping and one-time death signal.
   - Pass `combat_component_test.gd`.

2. **Hitbox/hurtbox gate**
   - Implement outgoing and incoming hit areas.
   - Prevent self-damage.
   - Pass hitbox/hurtbox coverage in `combat_component_test.gd`.

3. **Player attack gate**
   - Add `attack_primary`.
   - Add player combat nodes.
   - Add `start_attack()`, cooldown, active window, and facing-based hitbox placement.
   - Pass `player_input_and_ui_test.gd`.

4. **Wild wolf gate**
   - Create `wild_wolf.tscn`.
   - Implement idle, chase, attack, hurt, dead states.
   - Pass the wolf sections of `combat_flow_test.gd`.

5. **Feedback gate**
   - Add player HUD HP update.
   - Add wolf health bar.
   - Add hit feedback and damage number behavior.
   - Pass all combat and v0.1 regression tests.

6. **Documentation gate**
   - Update status docs only after the implementation and verification commands pass.
   - Record exact commands and observed results in `docs/DevLog.md`.

### Documentation Update Matrix

Update documents at these moments:

| File | When to update | Required content |
| --- | --- | --- |
| `TODO.md` | After each verified implementation gate | Mark only verified v0.2 items complete. Do not mark the whole milestone complete until final manual check passes. |
| `docs/DevLog.md` | After final automated and manual verification | Add a dated v0.2 implementation entry with commands, results, and remaining risks. |
| `docs/05_Combat.md` | After combat APIs settle | Document `HealthComponent`, hitbox/hurtbox behavior, attack cooldown, and the v0.2 damage formula actually used. |
| `docs/07_Monsters.md` | After wolf behavior is implemented | Record v0.2 wild wolf constants: aggro range, attack range, cooldown, hurt pause, HP, attack, defense, speed. |
| `docs/11_DevelopmentPlan.md` | After v0.2 is complete or scope changes | Change combat status from planned to implemented, or document any approved scope adjustment. |
| `README.md` | Only if run/test instructions change | Add new combat test commands if they become part of the standard verification flow. |
| `AGENTS.md` | Only if collaboration rules or canonical plan paths change | Avoid frequent edits unless a new required entrypoint is added. |

### Verification Commands

Run these commands before claiming any v0.2 implementation success:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected results:

- project loads without scene or script errors
- existing v0.1 movement, input, HUD, and asset tests still pass
- combat component tests pass
- combat flow tests pass

Manual play check:

- WASD movement still works
- left click walk still works
- right click run still works
- `J` or `Space` triggers melee attack
- wolf notices the player and chases
- wolf can damage the player
- player can damage and kill the wolf
- HP bars and damage feedback make hit, hurt, and death readable

### Implementation Risk Notes

- Godot `Area2D` overlap signals can be awkward in headless tests. If signal timing is flaky, tests may call the hurtbox method directly for deterministic coverage while leaving real scene overlaps for manual play checks.
- `player_controller.gd` already owns movement and animation state. Keep combat additions small; if attack logic grows beyond cooldown and hitbox timing, split it into a dedicated player combat script.
- Git repository management was initialized on 2026-07-06. Future implementation sessions should use normal Git status checks and commits when requested.
