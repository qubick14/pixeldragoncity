# Pixel Dragon City v0.5 New Player Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 10-minute playable new-player loop from Greenwood Village to Black Wolf Forest, ending with the Black Wolf Leader quest turn-in and a reloadable save.

**Architecture:** v0.5 is a vertical slice, not a full RPG framework rewrite. Reuse the existing v0.1 movement, HUD, menu overlay, and art assets; depend on the minimum v0.2-v0.4 systems needed for this route; keep map, quest, save, and content data in focused scripts and JSON-compatible structures.

**Tech Stack:** Godot 4.x, GDScript, Node2D/CharacterBody2D scenes, JSON design data under `data/`, headless Godot behavior tests.

---

## Current Baseline

The project currently has a working v0.1 movement prototype and a v0.2 combat plan. The live Godot project includes:

- `godot/project.godot`
- `godot/scenes/main.tscn`
- `godot/scenes/actors/player.tscn`
- `godot/scenes/maps/test_map.tscn`
- `godot/scenes/ui/hud.tscn`
- `godot/scenes/ui/menu_overlay.tscn`
- `godot/scripts/actors/player_controller.gd`
- `godot/scripts/tests/player_input_and_ui_test.gd`

The data seeds already support the v0.5 route:

- `data/maps.json` contains `greenwood_village`, `black_wolf_forest`, and `blackstone_mine`.
- `data/monsters.json` contains `wild_rabbit`, `wild_wolf`, and `black_wolf_leader`.
- `data/items.json` contains `wooden_sword`, `iron_sword`, `cloth_armor`, `leather_armor`, `small_health_potion`, and `wolf_pelt`.

Git repository management was initialized on 2026-07-06. Future implementation sessions should use normal Git status checks and commits when requested.

## v0.5 Scope

### Must Build

- Greenwood Village graybox map with player spawn, village chief, and exit to Black Wolf Forest.
- Black Wolf Forest graybox map with return exit, wolf zone, boss zone, and simple boundaries.
- Map switching between `greenwood_village` and `black_wolf_forest`.
- New-player NPC interaction with `village_chief`.
- First quest `first_hunt`.
- Black Wolf Leader encounter.
- Minimum item drop, pickup, inventory, and equip behavior required by the quest.
- JSON save/load for map, position, inventory, equipment, and quest state.
- Headless tests for route-critical behavior.

### Must Not Expand

- Do not build a full generic quest editor.
- Do not build full shop, blacksmith, warehouse, or crafting systems.
- Do not deepen class skills or complete v0.6 features.
- Do not create large new art pipelines; use existing assets and graybox visuals unless required for route readability.
- Do not restructure the whole Godot directory.

## Player Route

1. New game starts at `greenwood_village` spawn `village_spawn`.
2. Player talks to `village_chief`.
3. `village_chief` starts quest `first_hunt`.
4. Player exits east/southeast to `black_wolf_forest`.
5. Player defeats at least three `wild_wolf` enemies.
6. Player picks up at least one useful drop or reward path item.
7. Player equips `iron_sword` or `leather_armor` if acquired.
8. Player defeats `black_wolf_leader`.
9. Quest state becomes ready to turn in.
10. Player returns to `greenwood_village`.
11. Player talks to `village_chief` and completes quest.
12. Save and reload restores map, position, inventory, equipment, and quest state.

## Content IDs

Use these stable ids:

| Purpose | ID |
| --- | --- |
| Village map | `greenwood_village` |
| Forest map | `black_wolf_forest` |
| Village chief NPC | `village_chief` |
| First quest | `first_hunt` |
| Wolf enemy | `wild_wolf` |
| Boss enemy | `black_wolf_leader` |
| Wolf pelt material | `wolf_pelt` |
| Starter weapon upgrade | `iron_sword` |
| Starter armor upgrade | `leather_armor` |

## File Structure

- Create: `godot/scenes/maps/greenwood_village.tscn` - graybox village map.
- Create: `godot/scenes/maps/black_wolf_forest.tscn` - graybox forest map.
- Create: `godot/scenes/actors/npc.tscn` - reusable minimal NPC actor.
- Create: `godot/scripts/actors/npc_interaction.gd` - NPC id, prompt range, and interaction signal.
- Create: `godot/scripts/game/game_state.gd` - runtime map id, quest state, inventory, equipment, and save payload.
- Create: `godot/scripts/game/map_manager.gd` - loads maps and moves the player to spawn points.
- Create: `godot/scripts/game/quest_manager.gd` - owns `first_hunt` state transitions.
- Create: `godot/scripts/game/save_manager.gd` - writes and reads v0.5 JSON save data.
- Create: `godot/scripts/inventory/inventory_model.gd` - minimal stackable item storage.
- Create: `godot/scripts/inventory/equipment_model.gd` - minimal weapon/armor slots and stat bonuses.
- Create: `godot/scenes/items/drop_item.tscn` - pickup item in the world.
- Create: `godot/scripts/items/drop_item.gd` - item id, quantity, and pickup behavior.
- Create: `godot/scripts/tests/v05_new_player_loop_test.gd` - headless route-state test.
- Modify: `godot/scenes/main.tscn` - replace fixed `TestMap` instance with map manager flow.
- Modify: `godot/scripts/game/main.gd` - initialize game state, map manager, quest manager, and save manager.
- Modify: `godot/scenes/actors/player.tscn` - expose interaction/pickup areas only if not already available from v0.2-v0.4.
- Modify: `godot/scripts/actors/player_controller.gd` - add interaction input hook without changing movement behavior.
- Modify: `data/maps.json` - add spawn ids, transition ids, and v0.5 layout metadata.
- Modify: `data/monsters.json` - only adjust v0.5 balance if manual testing shows the 10-minute route is too slow or too hard.
- Modify: `data/items.json` - only adjust v0.5 reward values if the equip route needs a guaranteed item.
- Modify: `TODO.md` - track v0.5 tasks.
- Modify: `docs/DevLog.md` - record implementation and verification after work is done.

## Save Data Shape

Use this v0.5 save shape:

```json
{
  "version": 1,
  "player": {
    "map_id": "greenwood_village",
    "spawn_id": "village_spawn",
    "position": { "x": 120, "y": 96 },
    "level": 1,
    "exp": 0,
    "current_hp": 100,
    "current_mp": 30,
    "gold": 10
  },
  "inventory": [
    { "item_id": "wolf_pelt", "quantity": 3 }
  ],
  "equipment": {
    "weapon": "iron_sword",
    "armor": "leather_armor"
  },
  "quests": {
    "first_hunt": {
      "state": "ready_to_turn_in",
      "wild_wolf_defeated": 3,
      "black_wolf_leader_defeated": true
    }
  }
}
```

Quest states are:

- `not_started`
- `active`
- `ready_to_turn_in`
- `completed`

## Task 1: Documentation and Data Contract

**Files:**

- Modify: `docs/01_GDD.md`
- Modify: `docs/08_Maps.md`
- Modify: `docs/10_SaveSystem.md`
- Modify: `docs/11_DevelopmentPlan.md`
- Modify: `TODO.md`
- Modify: `README.md`

- [x] Step 1: Confirm v0.5 scope in docs.
- [x] Step 2: Add the first quest route and route-critical ids.
- [x] Step 3: Add map layout notes for Greenwood Village and Black Wolf Forest.
- [x] Step 4: Add v0.5 save payload fields and quest states.
- [x] Step 5: Run `jq empty data/items.json data/monsters.json data/maps.json`.
- [x] Step 6: Run `test -f docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`.

Expected result: future agents can start v0.5 implementation without relying on chat context.

## Task 2: Map Manager and Two Graybox Maps

**Files:**

- Create: `godot/scripts/game/map_manager.gd`
- Create: `godot/scenes/maps/greenwood_village.tscn`
- Create: `godot/scenes/maps/black_wolf_forest.tscn`
- Modify: `godot/scenes/main.tscn`
- Modify: `godot/scripts/game/main.gd`
- Modify: `data/maps.json`
- Test: `godot/scripts/tests/v05_new_player_loop_test.gd`

- [x] Step 1: Write a headless test that loads `Main` and asserts current map id is `greenwood_village`.
- [x] Step 2: Assert player starts at spawn id `village_spawn`.
- [x] Step 3: Add `MapManager` with `load_map(map_id, spawn_id)`.
- [x] Step 4: Create graybox `greenwood_village.tscn` with spawn `village_spawn` and transition `to_black_wolf_forest`.
- [x] Step 5: Create graybox `black_wolf_forest.tscn` with spawn `forest_entry`, transition `to_greenwood_village`, wolf zone, and boss zone.
- [x] Step 6: Hook main scene initialization to load `greenwood_village`.
- [x] Step 7: Run the headless test.

Expected result: map loading and map switching can be tested without hand-playing the route.

## Task 3: NPC Interaction and First Quest

**Files:**

- Create: `godot/scenes/actors/npc.tscn`
- Create: `godot/scripts/actors/npc_interaction.gd`
- Create: `godot/scripts/game/quest_manager.gd`
- Modify: `godot/scenes/maps/greenwood_village.tscn`
- Modify: `godot/scripts/actors/player_controller.gd`
- Test: `godot/scripts/tests/v05_new_player_loop_test.gd`

- [x] Step 1: Extend the test to assert `first_hunt` starts as `not_started`.
- [x] Step 2: Add test coverage for interacting with `village_chief`.
- [x] Step 3: Implement `QuestManager` with `start_quest`, `record_wild_wolf_defeated`, `record_black_wolf_leader_defeated`, and `complete_quest`.
- [x] Step 4: Add `village_chief` to the village map.
- [x] Step 5: Add player interaction input hook using one action, `interact`.
- [x] Step 6: Use simple text feedback for quest start and completion.
- [x] Step 7: Run route-state test and existing player input test.

Expected result: the first quest can be accepted and completed through an NPC, even if the dialogue UI is minimal.

## Task 4: Forest Enemies and Boss Gate

**Files:**

- Reuse or create according to v0.2 status: `godot/scenes/actors/wild_wolf.tscn`
- Create or modify: `godot/scenes/actors/black_wolf_leader.tscn`
- Modify: `godot/scenes/maps/black_wolf_forest.tscn`
- Modify: `godot/scripts/game/quest_manager.gd`
- Test: `godot/scripts/tests/v05_new_player_loop_test.gd`

- [x] Step 1: Extend the test to simulate three wild wolf defeats.
- [x] Step 2: Assert `wild_wolf_defeated` reaches `3`.
- [x] Step 3: Extend the test to simulate Black Wolf Leader defeat.
- [x] Step 4: Assert quest state becomes `ready_to_turn_in`.
- [x] Step 5: Place wild wolf spawn points and one Black Wolf Leader in the forest map.
- [x] Step 6: Connect enemy death to quest progress.
- [x] Step 7: Run route-state test.

Expected result: the quest progression does not depend on hidden chat notes or manual bookkeeping.

## Task 5: Minimal Drops, Inventory, and Equipment

**Files:**

- Create: `godot/scripts/inventory/inventory_model.gd`
- Create: `godot/scripts/inventory/equipment_model.gd`
- Create: `godot/scenes/items/drop_item.tscn`
- Create: `godot/scripts/items/drop_item.gd`
- Modify: `godot/scenes/ui/menu_overlay.tscn`
- Modify: `godot/scripts/ui/menu_overlay.gd`
- Test: `godot/scripts/tests/v05_new_player_loop_test.gd`

- [x] Step 1: Extend the test to add `wolf_pelt`, `iron_sword`, and `leather_armor`.
- [x] Step 2: Assert item quantities stack by `item_id`.
- [x] Step 3: Assert equipping `iron_sword` fills `weapon`.
- [x] Step 4: Assert equipping `leather_armor` fills `armor`.
- [x] Step 5: Implement minimal inventory storage.
- [x] Step 6: Implement minimal equipment slots.
- [x] Step 7: Add pickup item scene and pickup behavior.
- [x] Step 8: Add simple menu overlay text for inventory and equipment state.
- [x] Step 9: Run route-state test.

Implementation note: this task is satisfied by the v0.3 inventory/equipment/drop stack (`InventoryModel`, `EquipmentModel`, `DroppedItem`) and the v0.5 route test coverage, rather than by adding duplicate `items/drop_item` files.

Expected result: the route supports the GDD requirement that the player can obtain and equip a basic item.

## Task 6: Save and Load

**Files:**

- Create: `godot/scripts/game/save_manager.gd`
- Modify: `godot/scripts/game/game_state.gd`
- Modify: `godot/scripts/game/main.gd`
- Test: `godot/scripts/tests/v05_new_player_loop_test.gd`

- [x] Step 1: Extend the test to build the v0.5 save payload.
- [x] Step 2: Assert payload includes player map, position, inventory, equipment, and `first_hunt`.
- [x] Step 3: Implement `SaveManager.save_to_path(path, game_state)`.
- [x] Step 4: Implement `SaveManager.load_from_path(path)`.
- [x] Step 5: Add handling for missing save file by creating a new game state.
- [x] Step 6: Add handling for wrong `version` by refusing to overwrite and returning a recoverable error.
- [x] Step 7: Run route-state test with a temp save path.

Expected result: saving and loading proves the v0.5 route can be resumed.

## Task 7: 10-Minute Route Verification

**Files:**

- Modify: `godot/scripts/tests/v05_new_player_loop_test.gd`
- Modify: `docs/DevLog.md`
- Modify: `TODO.md`

- [x] Step 1: Run Godot headless startup.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
```

Expected: output contains the current prototype startup message and no script errors.

- [x] Step 2: Run existing v0.1 player test.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: output contains `player_input_and_ui_test: PASS`.

- [x] Step 3: Run v0.5 route test.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd
```

Expected: output contains `v05_new_player_loop_test: PASS`.

- [ ] Step 4: Manually run the game and complete the route from new game to quest completion.
- [ ] Step 5: Save after quest completion, restart, and load.
- [ ] Step 6: Confirm the loaded state preserves map, position, inventory, equipment, and quest completion.
- [x] Step 7: Update `TODO.md` with completed v0.5 items.
- [x] Step 8: Update `docs/DevLog.md` with exact verification commands and remaining risks.

Expected result: v0.5 is demonstrably playable and reloadable.

## Implementation Order

1. Task 1: Documentation and data contract.
2. Task 2: Map manager and two graybox maps.
3. Task 3: NPC interaction and first quest.
4. Task 4: Forest enemies and boss gate.
5. Task 5: Minimal drops, inventory, and equipment.
6. Task 6: Save and load.
7. Task 7: 10-minute route verification.

## Risks

- v0.5 depends on v0.2 combat and v0.3 inventory/equipment concepts. If those are still unimplemented, implement only the smallest route-specific version needed here.
- Existing UI is prototype-level. Keep dialogue and inventory feedback simple until v0.4 UI is formally implemented.
- Map art should remain graybox if polished tiles would delay route verification.
- Balance numbers may need adjustment after manual testing; prefer changing JSON data over hard-coded script values.

## Definition of Done

- New game starts in Greenwood Village.
- Village chief starts `first_hunt`.
- Player can enter and leave Black Wolf Forest.
- Wild wolf defeats update quest progress.
- Black Wolf Leader defeat unlocks quest turn-in.
- Player can obtain and equip at least one basic item.
- Village chief completes the quest.
- Save/load restores the completed or in-progress route.
- Headless startup, existing player test, and v0.5 route test pass.
- `TODO.md` and `docs/DevLog.md` are updated after implementation.
