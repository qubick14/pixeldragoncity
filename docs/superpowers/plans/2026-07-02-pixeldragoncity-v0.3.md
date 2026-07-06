# Pixel Dragon City v0.3 Loot, Inventory, and Equipment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a data-driven loot, inventory, equipment, and basic stat pipeline where configured monster drops can be collected, stored, equipped, and reflected in player stats.

**Architecture:** Keep v0.3 independent from unfinished combat by implementing reusable data, inventory, equipment, stat, and loot modules first. Runtime code should read repository JSON data, expose small testable APIs, and only connect to monster death events after v0.2 provides a stable death signal. UI work stays minimal: existing inventory/equipment panels should display real data, while complete pixel UI polish remains v0.4 scope.

**Tech Stack:** Godot 4.x, GDScript, JSON design data in `data/`, headless Godot `SceneTree` tests, existing v0.1 HUD/menu scenes, future v0.2 combat death signals.

---

## Current Baseline

The project already has:

- `data/items.json` with starter equipment, consumable, and material ids: `wooden_sword`, `iron_sword`, `cloth_armor`, `leather_armor`, `small_health_potion`, and `wolf_pelt`.
- `data/monsters.json` with monster stats, gold, exp, and drop rows for `wild_rabbit`, `wild_wolf`, and `black_wolf_leader`.
- `godot/assets/items/item_icons_sheet.png` imported into the Godot project as the first item icon placeholder sheet.
- `godot/scenes/ui/menu_overlay.tscn` with existing `InventoryPanel` and `EquipmentPanel` placeholders.
- `godot/scripts/ui/menu_overlay.gd` and `godot/scripts/game/main_menu_controller.gd` that can already open and close those panels.

v0.3 must not assume that v0.2 combat has already been implemented. If v0.2 is still incomplete, loot should be tested through `LootTable` and a lightweight pickup harness instead of real monster death.

## Scope

Included in v0.3:

- Runtime reading of `data/items.json` and `data/monsters.json`.
- Item lookup by stable id.
- Monster lookup by stable id.
- Inventory data structure with gold and item stacks.
- Equipment data structure for `weapon` and `armor`.
- Basic stat calculation for `attack`, `defense`, `max_hp`, `max_mp`, `speed`, `magic_attack`, and `crit_rate`.
- Loot rolling from configured monster gold and drops.
- Dropped item scene with item/gold setup data and pickup behavior.
- Minimal inventory/equipment display using the existing menu overlay.
- Headless tests for data loading, inventory, equipment, stat calculation, and loot.

Excluded from v0.3 unless the user explicitly expands scope:

- Full combat implementation.
- Monster AI.
- NPCs, shops, quests, map switching, save/load, experience gain, skill bars, random affixes, durability, rarity color polish, and complete final UI art.

## File Structure

- Create: `godot/scripts/data/game_data.gd` - reads JSON design data and provides item/monster lookup APIs.
- Create: `godot/scripts/inventory/inventory_model.gd` - owns gold and item stacks.
- Create: `godot/scripts/inventory/equipment_model.gd` - owns equipment slots and equip/unequip rules.
- Create: `godot/scripts/inventory/stat_calculator.gd` - combines base stats and equipment stats.
- Create: `godot/scripts/loot/loot_table.gd` - rolls monster gold and item drops.
- Create: `godot/scripts/loot/dropped_item.gd` - stores one world pickup payload and transfers it to an inventory.
- Create: `godot/scenes/loot/dropped_item.tscn` - visible pickup scene using placeholder icon art.
- Create: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd` - headless tests for v0.3 behavior.
- Modify: `godot/scenes/ui/menu_overlay.tscn` - replace static preview-only labels with minimal real inventory/equipment labels.
- Modify: `godot/scripts/ui/menu_overlay.gd` - render inventory/equipment model state into the existing panels.
- Modify: `godot/scripts/tests/asset_load_test.gd` - verify the dropped item scene and item icon sheet load.
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd` - keep existing menu open/close behavior covered after panel content changes.
- Modify after implementation: `TODO.md` and `docs/DevLog.md` - mark only verified v0.3 items as complete.

## Data Contract for v0.3

`data/items.json` entries should be treated as the design source of truth. The v0.3 runtime should support the current fields and tolerate the optional fields below:

```json
{
  "id": "iron_sword",
  "name": "铁剑",
  "type": "weapon",
  "quality": "common",
  "level": 1,
  "slot": "weapon",
  "stackable": false,
  "max_stack": 1,
  "stats": {
    "attack": 5
  },
  "price": 30,
  "icon_region": [32, 0, 32, 32]
}
```

Rules:

- `id` must be stable and unique.
- `type` determines default behavior. `weapon` maps to `slot: "weapon"`, `armor` maps to `slot: "armor"`.
- `material` and `consumable` default to `stackable: true` and `max_stack: 99`.
- `weapon` and `armor` default to `stackable: false` and `max_stack: 1`.
- `icon_region` is optional in v0.3; if missing, UI can show a text row or a fallback region from `item_icons_sheet.png`.

`data/monsters.json` drop rows should keep this shape:

```json
{ "item_id": "wolf_pelt", "chance": 0.6, "min": 1, "max": 2 }
```

Rules:

- `chance` is clamped between `0.0` and `1.0`.
- `min` and `max` are inclusive.
- `item_id` must exist in `items.json`.
- Monster `gold` is always included as a separate loot result when greater than 0.

## Starter Stat Contract

Use these player base stats for v0.3 tests unless a later balance pass changes them:

```gdscript
const PLAYER_BASE_STATS := {
	"attack": 1,
	"magic_attack": 0,
	"defense": 0,
	"max_hp": 100,
	"max_mp": 30,
	"speed": 140,
	"crit_rate": 0.0,
}
```

Stat calculation is direct additive in v0.3:

```text
final_stat = base_stat + sum(equipped_item.stats[stat])
```

No critical damage, random affixes, level requirements, class requirements, durability, or temporary buffs are part of v0.3.

## Implementation Tasks

### Task 1: Document and Normalize Data Contract

**Files:**

- Modify: `docs/06_Items.md`
- Modify: `data/items.json` only if optional v0.3 fields are needed before implementation.
- Modify: `data/monsters.json` only if validation finds a broken drop reference.

- [ ] **Step 1: Update item system documentation**

Document supported item fields, default stack rules, equipment slots, icon placeholder rules, loot row rules, and v0.3 stat calculation.

- [ ] **Step 2: Validate JSON syntax**

Run:

```bash
jq empty data/items.json data/monsters.json
```

Expected: no output and exit code 0.

- [ ] **Step 3: Validate drop references**

Confirm every `drops[].item_id` in `data/monsters.json` exists in `data/items.json`.

Expected current valid ids:

- `small_health_potion`
- `wolf_pelt`
- `iron_sword`
- `leather_armor`

### Task 2: Game Data Loader

**Files:**

- Create: `godot/scripts/data/game_data.gd`
- Create: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd`

- [ ] **Step 1: Write failing data-loader tests**

Create a headless `SceneTree` test that loads `GameData` and verifies:

- `load_all()` returns true.
- `get_item("iron_sword").name == "铁剑"`.
- `get_item("leather_armor").stats.max_hp == 15`.
- `get_monster("wild_wolf").gold == 4`.
- `get_monster("black_wolf_leader").drops.size() == 3`.
- `has_item("missing_item") == false`.

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd
```

Expected: FAIL because `res://scripts/data/game_data.gd` does not exist.

- [ ] **Step 3: Implement `GameData`**

Implement:

- `load_all() -> bool`
- `load_items(path: String = "res://../data/items.json") -> bool`
- `load_monsters(path: String = "res://../data/monsters.json") -> bool`
- `get_item(item_id: String) -> Dictionary`
- `get_monster(monster_id: String) -> Dictionary`
- `has_item(item_id: String) -> bool`
- `has_monster(monster_id: String) -> bool`
- `get_item_stack_rules(item_id: String) -> Dictionary`
- `validate_monster_drops() -> Array[String]`

Use `FileAccess.get_file_as_string`, `JSON.parse_string`, and dictionaries indexed by `id`.

- [ ] **Step 4: Re-run the data-loader test**

Run the same command.

Expected: output contains `v0_3_inventory_and_loot_test: PASS` for the data-loader section.

### Task 3: Inventory Model

**Files:**

- Create: `godot/scripts/inventory/inventory_model.gd`
- Modify: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd`

- [ ] **Step 1: Add failing inventory tests**

Cover:

- new inventory starts with 0 gold and empty item stacks.
- adding 4 gold changes gold to 4.
- adding 2 `wolf_pelt` creates one stack with quantity 2.
- adding 1 more `wolf_pelt` increases that stack to 3.
- adding two `iron_sword` items creates two separate quantity-1 entries.
- removing 1 `wolf_pelt` reduces the wolf pelt stack by 1.
- removing more items than available returns false and leaves inventory unchanged.

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd
```

Expected: FAIL because `InventoryModel` does not exist.

- [ ] **Step 3: Implement `InventoryModel`**

Implement:

- `setup(game_data_ref)`
- `add_gold(amount: int) -> void`
- `spend_gold(amount: int) -> bool`
- `add_item(item_id: String, quantity: int = 1) -> bool`
- `remove_item(item_id: String, quantity: int = 1) -> bool`
- `count_item(item_id: String) -> int`
- `get_entries() -> Array`
- `is_equipment(item_id: String) -> bool`
- `take_first_equipment(item_id: String) -> bool`

Store entries as dictionaries:

```gdscript
{ "item_id": "wolf_pelt", "quantity": 2 }
```

- [ ] **Step 4: Re-run the inventory tests**

Expected: output contains `v0_3_inventory_and_loot_test: PASS` for data-loader and inventory sections.

### Task 4: Equipment Model and Stat Calculator

**Files:**

- Create: `godot/scripts/inventory/equipment_model.gd`
- Create: `godot/scripts/inventory/stat_calculator.gd`
- Modify: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd`

- [ ] **Step 1: Add failing equipment/stat tests**

Cover:

- equipment starts with empty `weapon` and `armor`.
- equipping `iron_sword` moves it from inventory to weapon slot.
- calculated attack becomes 6 with base attack 1 plus iron sword attack 5.
- equipping `leather_armor` moves it to armor slot.
- calculated defense becomes 3.
- calculated max_hp becomes 115.
- replacing `iron_sword` with `wooden_sword` returns `iron_sword` to inventory.
- trying to equip `wolf_pelt` returns false.

- [ ] **Step 2: Run the test and verify it fails**

Run the v0.3 test command.

Expected: FAIL because equipment/stat scripts do not exist.

- [ ] **Step 3: Implement `EquipmentModel`**

Implement:

- `setup(game_data_ref, inventory_ref)`
- `equip(item_id: String) -> bool`
- `unequip(slot: String) -> bool`
- `get_equipped_item_id(slot: String) -> String`
- `get_slots() -> Dictionary`
- `get_slot_for_item(item_id: String) -> String`

Only `weapon` and `armor` are active in v0.3.

- [ ] **Step 4: Implement `StatCalculator`**

Implement:

- `calculate(base_stats: Dictionary, equipment_model, game_data_ref) -> Dictionary`

Ensure all supported stats exist in the output even when 0:

- `attack`
- `magic_attack`
- `defense`
- `max_hp`
- `max_mp`
- `speed`
- `crit_rate`

- [ ] **Step 5: Re-run equipment/stat tests**

Expected: output contains `v0_3_inventory_and_loot_test: PASS` for data, inventory, equipment, and stats.

### Task 5: Loot Table

**Files:**

- Create: `godot/scripts/loot/loot_table.gd`
- Modify: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd`

- [ ] **Step 1: Add failing loot tests**

Cover:

- `roll("black_wolf_leader")` always includes 30 gold.
- `black_wolf_leader` always includes 1 `leather_armor`.
- `black_wolf_leader` always includes 3 to 6 `wolf_pelt`.
- `roll("wild_wolf")` includes 4 gold.
- unknown monster id returns an empty loot list and no crash.
- drop rows referencing unknown items appear in validation errors.

- [ ] **Step 2: Run the test and verify it fails**

Run the v0.3 test command.

Expected: FAIL because `LootTable` does not exist.

- [ ] **Step 3: Implement `LootTable`**

Implement:

- `setup(game_data_ref)`
- `roll(monster_id: String, rng: RandomNumberGenerator = null) -> Array`
- `roll_drop_row(drop_row: Dictionary, rng: RandomNumberGenerator) -> Dictionary`

Loot result dictionaries:

```gdscript
{ "kind": "gold", "amount": 4 }
{ "kind": "item", "item_id": "wolf_pelt", "quantity": 2 }
```

Use seeded `RandomNumberGenerator` in tests.

- [ ] **Step 4: Re-run loot tests**

Expected: output contains `v0_3_inventory_and_loot_test: PASS`.

### Task 6: Dropped Item Scene and Pickup Payload

**Files:**

- Create: `godot/scenes/loot/dropped_item.tscn`
- Create: `godot/scripts/loot/dropped_item.gd`
- Modify: `godot/scripts/tests/v0_3_inventory_and_loot_test.gd`
- Modify: `godot/scripts/tests/asset_load_test.gd`

- [ ] **Step 1: Add failing dropped-item tests**

Cover:

- scene can be loaded from `res://scenes/loot/dropped_item.tscn`.
- `setup_item("wolf_pelt", 2)` stores kind item, item id, and quantity.
- `setup_gold(4)` stores kind gold and amount.
- `pickup(inventory)` adds gold or item to inventory and returns true.

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd
```

Expected: FAIL because the dropped item scene does not exist.

- [ ] **Step 3: Create dropped item scene**

Scene requirements:

- root `Area2D` named `DroppedItem`
- child `Sprite2D` named `Icon`
- child `CollisionShape2D` named `PickupShape`
- uses `godot/assets/items/item_icons_sheet.png` as placeholder texture
- script `res://scripts/loot/dropped_item.gd`

- [ ] **Step 4: Implement dropped item script**

Implement:

- `setup_item(item_id: String, quantity: int)`
- `setup_gold(amount: int)`
- `pickup(inventory_model) -> bool`
- `get_payload() -> Dictionary`

Do not require a real player node yet. Direct method calls keep v0.3 testable before v0.2 death/pickup signals are wired.

- [ ] **Step 5: Re-run dropped item tests**

Expected: v0.3 and asset tests pass.

### Task 7: Minimal Menu Overlay Binding

**Files:**

- Modify: `godot/scenes/ui/menu_overlay.tscn`
- Modify: `godot/scripts/ui/menu_overlay.gd`
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd`

- [ ] **Step 1: Add failing UI binding tests**

Cover:

- opening inventory still shows `InventoryPanel`.
- opening equipment still shows `EquipmentPanel`.
- calling `set_models(inventory, equipment, game_data, stats)` does not crash.
- inventory panel text includes `Gold 4` after adding gold.
- equipment panel text includes `Weapon: iron_sword` after equipping iron sword.

- [ ] **Step 2: Run the UI test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: FAIL because `set_models` and real data labels do not exist.

- [ ] **Step 3: Update menu overlay scene**

Keep existing panels and close button. Add simple labels:

- `InventoryPanel/InventoryListLabel`
- `EquipmentPanel/EquipmentListLabel`
- `EquipmentPanel/StatsLabel`

The labels can use plain text in v0.3. Pixel visual polish belongs to v0.4.

- [ ] **Step 4: Implement menu overlay rendering**

Add:

- `set_models(inventory_model, equipment_model, game_data_ref, calculated_stats: Dictionary)`
- `refresh_inventory()`
- `refresh_equipment()`

Render compact readable lines such as:

```text
Gold 4
狼皮 x2
铁剑 x1
```

```text
Weapon: iron_sword
Armor: leather_armor
ATK 6  DEF 3  HP 115
```

- [ ] **Step 5: Re-run existing UI behavior tests**

Expected: `player_input_and_ui_test: PASS`.

### Task 8: Optional v0.2 Death Hook

**Files:**

- Modify only if v0.2 already exists: `godot/scripts/actors/wild_wolf_controller.gd`
- Modify only if v0.2 already exists: `godot/scenes/main.tscn`

- [ ] **Step 1: Check whether v0.2 death signal exists**

Search:

```bash
rg -n "died|HealthComponent|wild_wolf|loot" godot/scripts godot/scenes
```

Expected if v0.2 is not implemented yet: no real hook is available, so stop this task and document it as deferred.

- [ ] **Step 2: If available, connect death to loot spawning**

When a monster dies, call `LootTable.roll(monster_id)` and instance one dropped item scene per loot result near the monster position.

- [ ] **Step 3: Verify no v0.2 behavior regresses**

Run v0.2 tests if they exist:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
```

Expected: PASS if those tests exist. If those scripts do not exist yet, document that v0.3 loot is ready for later combat integration.

### Task 9: Documentation and TODO Closeout

**Files:**

- Modify: `TODO.md`
- Modify: `docs/11_DevelopmentPlan.md`
- Modify: `docs/DevLog.md`

- [ ] **Step 1: Update TODO after verified implementation**

Only mark v0.3 tasks complete after their tests pass. Do not mark `完成 v0.3 掉落与装备` complete until data loading, inventory, equipment, stats, loot, dropped item payload, and minimal UI binding are verified.

- [ ] **Step 2: Update DevelopmentPlan**

Change v0.3 status from planned to implemented only after all v0.3 acceptance criteria pass.

- [ ] **Step 3: Update DevLog**

Record:

- files created
- user-visible behavior
- commands run
- pass/fail evidence
- whether v0.2 death hook was connected or deferred

## Verification Commands

Run these after implementation:

```bash
jq empty data/items.json data/monsters.json data/maps.json data/skills.json
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected:

- JSON validation exits 0.
- Godot project opens headless.
- v0.3 test prints `v0_3_inventory_and_loot_test: PASS`.
- asset test prints `asset_load_test: PASS`.
- UI/input test prints `player_input_and_ui_test: PASS`.

## Acceptance Criteria

v0.3 is complete only when:

- Godot can read `data/items.json` and `data/monsters.json`.
- Invalid item or monster ids fail safely without crashing.
- All monster drop `item_id` values are validated against item data.
- Loot can be rolled from `wild_wolf` and `black_wolf_leader`.
- Gold loot and item loot are represented with explicit payload dictionaries.
- Inventory can add, remove, and count stackable items.
- Equipment items remain separate inventory entries unless equipped.
- `weapon` and `armor` slots can equip and replace items.
- Equipping `iron_sword` changes attack.
- Equipping `leather_armor` changes defense and max HP.
- Dropped item scene can represent item and gold payloads.
- Existing Bag and Equip buttons still open the right panels.
- Minimal menu text displays inventory, equipment, and calculated stats.
- Existing v0.1 movement/menu tests still pass.

## Risks and Mitigations

- **v0.2 dependency:** Monster death may not exist yet. Mitigation: keep `LootTable` and `DroppedItem.pickup()` independently testable, and make the death hook an optional final task.
- **UI scope growth:** Full inventory/equipment UI belongs to v0.4. Mitigation: v0.3 uses compact text labels and existing panels only.
- **Data drift:** Future item fields may expand. Mitigation: `GameData` should tolerate missing optional fields and provide default stack/equipment rules.
- **Balance churn:** Early stat numbers will change. Mitigation: formulas stay additive and data-driven so JSON changes do not require GDScript edits.
