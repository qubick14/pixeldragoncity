# Pixel Dragon City v0.4 UI, NPC, and Shop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable RPG interface layer for HUD, inventory, equipment, NPC dialogue, and shop interactions without implementing combat, loot drops, quests, classes, map progression, or save/load.

**Architecture:** Keep UI panels modular and data-ready. `HUD` remains always visible, modal panels live under one UI/menu coordinator, reusable slot/tooltip rows are shared by inventory, equipment, and shop views, and prototype data is loaded from JSON so later v0.3 inventory/equipment logic and v0.5 NPC content can replace the demo state cleanly.

**Tech Stack:** Godot 4.x, GDScript, Control/CanvasLayer UI scenes, JSON design data in `data/`, existing generated pixel UI atlas and item/portrait assets.

---

## Scope

This plan covers v0.4 only:

- Main HUD
- Inventory UI
- Equipment UI
- NPC dialogue UI
- Shop UI
- Pixel UI style guide
- Character/equipment portrait placeholder region
- Headless verification for UI behavior and JSON data loading

This plan explicitly excludes:

- v0.2 combat implementation
- v0.3 real monster drops, inventory persistence, equipment stat math, or item pickup
- v0.5 quest flow, map switching, save/load, or full newbie story progression
- v0.6 class and skill-system implementation

Where real gameplay data is not available yet, use a small demo UI state and JSON data with stable ids. Do not hide important decisions in chat; record them in docs.

## Current Baseline

The project already includes:

- `godot/scenes/ui/hud.tscn` with HP/MP labels, quick slots, EXP/gold text, and Bag/Equip buttons.
- `godot/scenes/ui/menu_overlay.tscn` with prototype inventory/equipment panels.
- `godot/scripts/ui/menu_overlay.gd` for show/hide behavior.
- `godot/scripts/game/main_menu_controller.gd` for Bag/Equip button routing.
- `godot/assets/ui/ui_atlas.png` for prototype pixel UI art.
- `godot/assets/items/item_icons_sheet.png` for prototype item icons.
- `godot/assets/portraits/character_portrait_direction_v1.png` for prototype portrait display.
- `godot/scripts/tests/player_input_and_ui_test.gd` with existing HUD/menu toggle coverage.

Treat these as starting points. Do not replace the whole UI stack unless a task says to split a specific panel out.

## File Structure

- Modify: `docs/09_UI.md` - expand v0.4 UI requirements and interaction rules.
- Modify: `docs/11_DevelopmentPlan.md` - link this v0.4 plan and clarify that v0.4 follows v0.3 unless explicitly pulled forward for UI prototyping.
- Modify: `TODO.md` - split v0.4 into executable subtasks.
- Modify: `docs/DevLog.md` - append implementation notes after verified changes.
- Create: `docs/13_UIStyleGuide.md` - first pixel UI style guide.
- Create: `data/npcs.json` - NPC ids, names, portrait keys, dialogue lines, and interaction targets.
- Create: `data/shops.json` - shop ids, names, stocked item ids, prices, and shopkeeper NPC linkage.
- Create: `data/ui_demo_state.json` - temporary UI state for HUD, inventory, equipment, player stats, and gold.
- Create: `godot/scripts/data/json_data_loader.gd` - small JSON loader for UI/NPC/shop data.
- Create: `godot/scripts/ui/ui_demo_state.gd` - reads `ui_demo_state.json` and exposes demo HUD/inventory/equipment state.
- Modify: `godot/scenes/ui/hud.tscn` - attach script and name nodes for reliable updates.
- Create: `godot/scripts/ui/hud.gd` - HUD update API.
- Create: `godot/scenes/ui/item_slot.tscn` - reusable item/equipment/shop slot.
- Create: `godot/scripts/ui/item_slot.gd` - slot data binding and selected/empty state.
- Create: `godot/scenes/ui/item_tooltip.tscn` - reusable item tooltip.
- Create: `godot/scripts/ui/item_tooltip.gd` - tooltip content binding.
- Create: `godot/scenes/ui/inventory_panel.tscn` - inventory grid panel.
- Create: `godot/scripts/ui/inventory_panel.gd` - inventory grid rendering and tooltip routing.
- Create: `godot/scenes/ui/equipment_panel.tscn` - equipment slots, stats, and portrait region.
- Create: `godot/scripts/ui/equipment_panel.gd` - equipment/stat rendering.
- Create: `godot/scenes/ui/dialogue_panel.tscn` - NPC dialogue panel.
- Create: `godot/scripts/ui/dialogue_panel.gd` - dialogue line progression.
- Create: `godot/scenes/ui/shop_item_row.tscn` - row for shop item list.
- Create: `godot/scripts/ui/shop_item_row.gd` - shop row rendering and buy/sell signal.
- Create: `godot/scenes/ui/shop_panel.tscn` - shop buy/sell panel.
- Create: `godot/scripts/ui/shop_panel.gd` - shop rendering and demo transaction feedback.
- Create: `godot/scenes/ui/ui_root.tscn` - top-level UI layer that instances HUD and modal panels.
- Create: `godot/scripts/ui/ui_root.gd` - central UI open/close coordinator.
- Modify: `godot/scenes/main.tscn` - use `UIRoot` or wire it alongside existing HUD/MenuOverlay after compatibility is preserved.
- Modify: `godot/scripts/game/main_menu_controller.gd` - delegate to `UIRoot` instead of directly toggling panel paths.
- Create: `godot/scripts/tests/ui_data_load_test.gd` - validates JSON data loading.
- Create: `godot/scripts/tests/ui_panels_test.gd` - validates HUD, inventory, equipment, dialogue, and shop panel behavior.
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd` - keep v0.1 movement and menu behavior passing after UI refactor.

## UI Constants for v0.4

Use these starter values unless the user requests changes:

| Area | Value |
| --- | --- |
| Design viewport | 1600 x 900 |
| HUD height | 96 px |
| Quick slots | 6 |
| Inventory grid | 5 columns x 6 rows |
| Item slot size | 48 x 48 px |
| Equipment slots | weapon, armor, helmet, necklace, ring |
| Portrait region | 220 x 260 px minimum |
| Tooltip width | 260 px |
| Primary panel materials | dark wood, stone, bronze, leather |
| Quality colors | normal white, uncommon green, rare blue, epic purple, legendary orange |

Use English node/script names and stable snake_case JSON ids. Visible in-game text can be Chinese later, but this plan can use short English prototype labels while the font pipeline is still temporary.

## Task 1: Documentation Sync for v0.4

**Files:**

- Modify: `docs/09_UI.md`
- Modify: `docs/11_DevelopmentPlan.md`
- Modify: `TODO.md`
- Modify: `docs/DevLog.md`

- [ ] **Step 1: Expand `docs/09_UI.md`**

Add sections for HUD, inventory, equipment, dialogue, shop, modal rules, and data boundaries. State that v0.4 may use demo state until v0.3 gameplay data is available.

- [ ] **Step 2: Update `docs/11_DevelopmentPlan.md`**

Under v0.4, link this plan:

```text
docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.4-ui-npc-shop.md
```

Clarify that v0.4 implementation should not pull in combat, drops, quest flow, class skills, map switching, or save/load unless the user explicitly requests it.

- [ ] **Step 3: Split `TODO.md` v0.4 tasks**

Replace the broad v0.4 list with trackable items:

```text
- [ ] Expand v0.4 UI documentation and style guide
- [ ] Add NPC/shop/demo UI JSON data
- [ ] Add UI data loading tests
- [ ] Formalize HUD update API
- [ ] Build reusable item slot and tooltip
- [ ] Build inventory grid UI
- [ ] Build equipment panel with portrait region
- [ ] Build NPC dialogue panel
- [ ] Build shop panel
- [ ] Route panels through UI root
- [ ] Run headless UI verification
```

- [ ] **Step 4: Append planning note to `docs/DevLog.md`**

Add a short entry saying the v0.4 UI/NPC/shop implementation plan was created and approved for later execution.

## Task 2: Prototype UI Data

**Files:**

- Create: `data/npcs.json`
- Create: `data/shops.json`
- Create: `data/ui_demo_state.json`

- [ ] **Step 1: Create `data/npcs.json`**

Create three starter NPCs:

- `village_chief` with 3 dialogue lines and no shop.
- `merchant` with 2 dialogue lines and `shop_id: "merchant_general_store"`.
- `blacksmith` with 2 dialogue lines and `shop_id: "blacksmith_basic_gear"`.

Each NPC entry must include `id`, `name`, `portrait`, `dialogue`, and `shop_id`.

- [ ] **Step 2: Create `data/shops.json`**

Create:

- `merchant_general_store` stocking potion, herb, town scroll, and wolf fang buyback placeholder.
- `blacksmith_basic_gear` stocking iron sword, leather armor, and bronze helmet placeholders.

Each shop item must include `item_id`, `display_name`, `kind`, `quality`, `price`, `sell_price`, `description`, and `icon_index`.

- [ ] **Step 3: Create `data/ui_demo_state.json`**

Create demo state with:

- level 1
- hp 84 / 100
- mp 32 / 40
- exp 18 / 100
- gold 128
- 30 inventory slots with 5 filled items
- equipment slots for weapon and armor filled, remaining slots empty
- stats attack 12, defense 4, max_hp 100, max_mp 40

## Task 3: JSON Loading Tests

**Files:**

- Create: `godot/scripts/data/json_data_loader.gd`
- Create: `godot/scripts/tests/ui_data_load_test.gd`

- [ ] **Step 1: Write `ui_data_load_test.gd` first**

The test should load:

- `res://../data/npcs.json`
- `res://../data/shops.json`
- `res://../data/ui_demo_state.json`

It should assert:

- NPC ids include `village_chief`, `merchant`, `blacksmith`.
- Merchant has `shop_id == "merchant_general_store"`.
- Shops include `merchant_general_store`.
- Demo state includes 30 inventory slots.
- Demo state gold equals 128.

- [ ] **Step 2: Run the data test and verify it fails before loader implementation**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd
```

Expected: FAIL because `json_data_loader.gd` does not exist or cannot load data yet.

- [ ] **Step 3: Implement `json_data_loader.gd`**

Add:

- `load_json(path: String) -> Variant`
- file existence check with `FileAccess.file_exists`
- parse with `JSON.parse_string`
- return `{}` or `[]` only when the file intentionally contains that type
- print a clear error and return `null` for missing or invalid JSON

- [ ] **Step 4: Re-run data test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd
```

Expected: output contains `ui_data_load_test: PASS`.

## Task 4: HUD Update API

**Files:**

- Modify: `godot/scenes/ui/hud.tscn`
- Create: `godot/scripts/ui/hud.gd`
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd`

- [ ] **Step 1: Extend the existing HUD test**

Add assertions that `HUD` exposes:

- `set_health(84, 100)`
- `set_mana(32, 40)`
- `set_experience(18, 100)`
- `set_gold(128)`
- `set_level(1)`

Expected visible values should include `84/100`, `32/40`, `18%`, `Gold 128`, and `Lv.1`.

- [ ] **Step 2: Run the existing player/UI test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: FAIL because `hud.gd` update methods are not attached yet.

- [ ] **Step 3: Attach `hud.gd` to `hud.tscn`**

Keep existing HUD layout but rename or add child labels so tests can address them predictably:

- `BottomPanel/LeftFrame/HpValue`
- `BottomPanel/LeftFrame/MpValue`
- `BottomPanel/StatusLabel`
- `BottomPanel/QuickSlots`

- [ ] **Step 4: Implement `hud.gd`**

Implement:

- `set_health(current: int, maximum: int) -> void`
- `set_mana(current: int, maximum: int) -> void`
- `set_experience(current: int, maximum: int) -> void`
- `set_gold(amount: int) -> void`
- `set_level(value: int) -> void`
- `set_quick_slot(index: int, slot_data: Dictionary) -> void`

The status label should combine level, EXP percent, and gold in one stable string:

```text
Lv.1  EXP 18%  Gold 128
```

- [ ] **Step 5: Re-run the test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: output contains `player_input_and_ui_test: PASS`.

## Task 5: Reusable Item Slot and Tooltip

**Files:**

- Create: `godot/scenes/ui/item_slot.tscn`
- Create: `godot/scripts/ui/item_slot.gd`
- Create: `godot/scenes/ui/item_tooltip.tscn`
- Create: `godot/scripts/ui/item_tooltip.gd`
- Create: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Write slot/tooltip tests**

Create `ui_panels_test.gd` with assertions that:

- empty slot shows no quantity text
- filled slot stores `item_id`
- quantity greater than 1 is displayed
- tooltip displays item name, quality, description, and price

- [ ] **Step 2: Run panel test and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL because item slot and tooltip scenes/scripts do not exist.

- [ ] **Step 3: Create `item_slot.tscn`**

Use a `PanelContainer` or `TextureRect` root named `ItemSlot` with:

- `Icon` as `TextureRect`
- `QuantityLabel` as `Label`
- `SelectionFrame` as `ColorRect`

Attach `item_slot.gd`.

- [ ] **Step 4: Implement `item_slot.gd`**

Implement:

- `set_empty() -> void`
- `set_item(data: Dictionary) -> void`
- `set_selected(value: bool) -> void`
- `get_item_id() -> String`

Use `data.icon_index` for later icon atlas slicing, but if slicing is not ready in this task, still store the value and show the slot as occupied.

- [ ] **Step 5: Create tooltip scene/script**

Implement `item_tooltip.gd` with:

- `set_item(data: Dictionary) -> void`
- label fields for name, kind, quality, description, price, sell price
- `hide_tooltip() -> void`

- [ ] **Step 6: Re-run panel test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: slot/tooltip assertions pass.

## Task 6: Inventory Panel

**Files:**

- Create: `godot/scenes/ui/inventory_panel.tscn`
- Create: `godot/scripts/ui/inventory_panel.gd`
- Modify: `godot/scenes/ui/menu_overlay.tscn`
- Modify: `godot/scripts/ui/menu_overlay.gd`
- Modify: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Add inventory panel tests**

Extend `ui_panels_test.gd` to instantiate `inventory_panel.tscn`, call `set_inventory(slots)`, and assert:

- 30 visible item slots are created or updated.
- filled demo slots expose their item ids.
- empty slots remain empty.
- the panel title is `Inventory`.

- [ ] **Step 2: Run the panel test and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL because `inventory_panel.tscn` does not exist.

- [ ] **Step 3: Create inventory panel scene**

Use a root `Control` named `InventoryPanel` with:

- `TitleLabel`
- `SlotGrid` as `GridContainer` with 5 columns
- `Tooltip` instance from `item_tooltip.tscn`

- [ ] **Step 4: Implement `inventory_panel.gd`**

Implement:

- `set_inventory(slots: Array) -> void`
- `clear_slots() -> void`
- `get_slot_count() -> int`
- `get_slot(index: int) -> Control`

Do not implement drag/drop in v0.4 unless the user later asks.

- [ ] **Step 5: Wire inventory panel into `menu_overlay.tscn`**

Replace the prototype item sheet preview with an `InventoryPanel` instance while preserving Bag button behavior.

- [ ] **Step 6: Re-run tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: inventory assertions pass.

## Task 7: Equipment Panel

**Files:**

- Create: `godot/scenes/ui/equipment_panel.tscn`
- Create: `godot/scripts/ui/equipment_panel.gd`
- Modify: `godot/scenes/ui/menu_overlay.tscn`
- Modify: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Add equipment tests**

Extend `ui_panels_test.gd` to instantiate `equipment_panel.tscn`, call `set_equipment(equipment, stats)`, and assert:

- slot names include weapon, armor, helmet, necklace, ring
- weapon and armor demo items are filled
- portrait region exists
- stats labels show attack, defense, max_hp, and max_mp

- [ ] **Step 2: Run panel test and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL because `equipment_panel.tscn` does not exist.

- [ ] **Step 3: Create equipment panel scene**

Use root `Control` named `EquipmentPanel` with:

- `TitleLabel`
- `PortraitFrame`
- `PortraitPreview`
- `SlotList`
- one slot container per equipment slot
- `StatsList`
- `Tooltip`

- [ ] **Step 4: Implement `equipment_panel.gd`**

Implement:

- `set_equipment(equipment: Dictionary, stats: Dictionary) -> void`
- `get_equipment_slot(slot_id: String) -> Control`
- `set_portrait(texture: Texture2D) -> void`

- [ ] **Step 5: Wire equipment panel into `menu_overlay.tscn`**

Replace the prototype equipment preview while preserving Equip button behavior.

- [ ] **Step 6: Re-run tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: equipment assertions pass.

## Task 8: NPC Dialogue Panel

**Files:**

- Create: `godot/scenes/ui/dialogue_panel.tscn`
- Create: `godot/scripts/ui/dialogue_panel.gd`
- Modify: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Add dialogue tests**

Extend `ui_panels_test.gd` to instantiate `dialogue_panel.tscn`, call `start_dialogue(npc_data)`, and assert:

- NPC name appears.
- first dialogue line appears.
- `advance()` moves to the second line.
- after the final line, `is_finished()` returns true.
- shop button becomes visible for merchant NPC data.

- [ ] **Step 2: Run panel test and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL because `dialogue_panel.tscn` does not exist.

- [ ] **Step 3: Create dialogue scene**

Use root `Control` named `DialoguePanel` with:

- `PortraitFrame`
- `PortraitPreview`
- `NameLabel`
- `DialogueText`
- `NextButton`
- `CloseButton`
- `ShopButton`
- `QuestButton`

Keep `QuestButton` disabled/hidden in v0.4 because full quest logic belongs to v0.5.

- [ ] **Step 4: Implement `dialogue_panel.gd`**

Implement:

- `start_dialogue(npc_data: Dictionary) -> void`
- `advance() -> void`
- `is_finished() -> bool`
- `get_shop_id() -> String`
- signals `dialogue_closed` and `shop_requested(shop_id)`

- [ ] **Step 5: Re-run tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: dialogue assertions pass.

## Task 9: Shop Panel

**Files:**

- Create: `godot/scenes/ui/shop_item_row.tscn`
- Create: `godot/scripts/ui/shop_item_row.gd`
- Create: `godot/scenes/ui/shop_panel.tscn`
- Create: `godot/scripts/ui/shop_panel.gd`
- Modify: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Add shop tests**

Extend `ui_panels_test.gd` to instantiate `shop_panel.tscn`, call `set_shop(shop_data, player_gold)`, and assert:

- shop name appears.
- at least one item row appears.
- row displays display name and price.
- player gold displays as `Gold 128`.
- buy button emits `buy_requested(item_id)`.
- sell view can be selected even if it only shows demo sell rows.

- [ ] **Step 2: Run panel test and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL because shop scenes/scripts do not exist.

- [ ] **Step 3: Create `shop_item_row.tscn`**

Use root `HBoxContainer` named `ShopItemRow` with:

- `Icon`
- `NameLabel`
- `KindLabel`
- `PriceLabel`
- `BuyButton`

- [ ] **Step 4: Implement `shop_item_row.gd`**

Implement:

- `set_item(data: Dictionary) -> void`
- `get_item_id() -> String`
- signal `buy_requested(item_id: String)`

- [ ] **Step 5: Create `shop_panel.tscn`**

Use root `Control` named `ShopPanel` with:

- `ShopNameLabel`
- `GoldLabel`
- `BuyTabButton`
- `SellTabButton`
- `ItemList`
- `Tooltip`
- `CloseButton`

- [ ] **Step 6: Implement `shop_panel.gd`**

Implement:

- `set_shop(shop_data: Dictionary, player_gold: int) -> void`
- `show_buy_tab() -> void`
- `show_sell_tab() -> void`
- `get_row_count() -> int`
- signal `buy_requested(item_id: String)`
- signal `shop_closed`

For v0.4, buying may emit a signal and update a status label. Do not build permanent inventory/economy changes unless explicitly requested.

- [ ] **Step 7: Re-run tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: shop assertions pass.

## Task 10: UI Root and Panel Routing

**Files:**

- Create: `godot/scenes/ui/ui_root.tscn`
- Create: `godot/scripts/ui/ui_root.gd`
- Modify: `godot/scenes/main.tscn`
- Modify: `godot/scripts/game/main_menu_controller.gd`
- Modify: `godot/scripts/tests/player_input_and_ui_test.gd`
- Modify: `godot/scripts/tests/ui_panels_test.gd`

- [ ] **Step 1: Add UI root routing tests**

Tests should assert:

- `UIRoot` has HUD.
- `show_inventory()` shows inventory and hides equipment/shop/dialogue.
- `show_equipment()` shows equipment and hides inventory/shop/dialogue.
- `show_dialogue("merchant")` shows dialogue.
- merchant dialogue `shop_requested` can open `merchant_general_store`.
- `close_active_panel()` hides the active modal panel.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: FAIL until `UIRoot` exists and routes panels.

- [ ] **Step 3: Create `ui_root.tscn`**

Use root `CanvasLayer` named `UIRoot` with instances of:

- `HUD`
- `InventoryPanel`
- `EquipmentPanel`
- `DialoguePanel`
- `ShopPanel`

All modal panels should start hidden.

- [ ] **Step 4: Implement `ui_root.gd`**

Implement:

- `load_demo_state() -> void`
- `show_inventory() -> void`
- `show_equipment() -> void`
- `show_dialogue(npc_id: String) -> void`
- `show_shop(shop_id: String) -> void`
- `close_active_panel() -> void`
- `close_all_panels() -> void`

Use `json_data_loader.gd` and `ui_demo_state.gd` for v0.4 demo data.

- [ ] **Step 5: Wire main scene**

Update `main.tscn` so the UI root replaces or wraps the current direct HUD/MenuOverlay setup. Keep existing Bag and Equip behavior passing.

- [ ] **Step 6: Update menu controller**

Make `main_menu_controller.gd` call `UIRoot.show_inventory()` and `UIRoot.show_equipment()`.

- [ ] **Step 7: Run player/UI and panel tests**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: output contains `player_input_and_ui_test: PASS`.

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: output contains `ui_panels_test: PASS`.

## Task 11: Pixel UI Style Guide

**Files:**

- Create: `docs/13_UIStyleGuide.md`
- Modify: `docs/09_UI.md`
- Modify: `docs/12_ArtDirection.md`

- [ ] **Step 1: Create `docs/13_UIStyleGuide.md`**

Document:

- viewport baseline
- HUD placement
- panel materials
- item slot size
- icon size policy
- portrait region policy
- quality colors
- tooltip content rules
- button states
- modal stacking rules
- prohibition on copying commercial UI art, fonts, layout, or text

- [ ] **Step 2: Link style guide from `docs/09_UI.md`**

Add a sentence that v0.4 UI implementation follows `docs/13_UIStyleGuide.md`.

- [ ] **Step 3: Link style guide from `docs/12_ArtDirection.md`**

Under UI direction, reference `docs/13_UIStyleGuide.md` as the concrete layout/style standard.

## Task 12: Final Verification and Status Updates

**Files:**

- Modify: `TODO.md`
- Modify: `docs/DevLog.md`
- Optional Modify: `README.md` if current-stage text is still stale after v0.4 work is complete.

- [ ] **Step 1: Run Godot project load check**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
```

Expected: exits with code 0.

- [ ] **Step 2: Run data load test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd
```

Expected: output contains `ui_data_load_test: PASS`.

- [ ] **Step 3: Run UI panel test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
```

Expected: output contains `ui_panels_test: PASS`.

- [ ] **Step 4: Run existing player/input/UI regression test**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
```

Expected: output contains `player_input_and_ui_test: PASS`.

- [ ] **Step 5: Update `TODO.md`**

Mark only completed and verified v0.4 subtasks as checked. Do not mark the entire v0.4 milestone complete if NPC/shop UI exists only as demo UI and the user wants real map interaction later.

- [ ] **Step 6: Append `docs/DevLog.md`**

Record:

- files created/modified
- tests run
- whether UI is demo-data based or connected to real gameplay data
- remaining risks

## Manual QA Checklist

After automated tests pass, open the Godot project and manually verify:

- HUD is visible at the bottom and does not obscure the player.
- Bag opens inventory and closes cleanly.
- Equip opens equipment with portrait region and readable stat labels.
- Dialogue panel advances through all lines.
- Merchant dialogue can open the shop.
- Shop displays item names and prices.
- Tooltips are readable.
- UI has a pixel RPG feel, not a modern flat placeholder look.
- Text does not overlap at 1600 x 900.

## Risks and Guardrails

- The generated UI atlas is a prototype sheet, not clean final UI slices. Use it for style continuity but do not overfit layout to its imperfect regions.
- `menu_overlay.tscn` may become too large if every panel remains embedded. Prefer splitting inventory/equipment/dialogue/shop into separate scenes.
- v0.4 should not wait for v0.3 real inventory/equipment data. Use demo data, but keep the API easy to swap.
- Do not create circular dependencies between HUD, inventory, equipment, dialogue, shop, and player logic. Route panel visibility through `UIRoot`.
- Do not mark v0.4 complete solely because panels render; NPC/shop interaction rules and documentation must be verified too.

## Suggested Execution Strategy

Use subagent-driven development if available:

1. One subagent for docs/data setup.
2. One subagent for HUD and shared slot/tooltip components.
3. One subagent for inventory/equipment panels.
4. One subagent for dialogue/shop panels.
5. One subagent for UI root integration and regression tests.

Review after each task group. Keep commits or checkpoints small enough that UI regressions are easy to isolate.
