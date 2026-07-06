# Asset Manifest

第一批生成美术资源，供 Godot 原型和后续切图使用。

## 状态说明

| 状态 | 含义 |
| --- | --- |
| `reference` | 方向参考图，不直接作为游戏切图。 |
| `prototype` | 原型占位资源，可用于 Godot 流程验证。 |
| `blockout` | 动作或布局验证资源，不代表最终美术精度。 |
| `production_candidate` | 规则网格或可复用切图候选，可进入实机验收。 |
| `production_ready` | 已通过尺寸、导入和实机验收，可作为当前阶段正式资源。 |

## Godot 可引用路径

这些文件已复制到 `godot/assets/`，可在 Godot 中用 `res://assets/...` 引用。

| 类型 | 状态 | Godot 路径 | 说明 |
| --- | --- | --- | --- |
| 玩家 sprite sheet | `prototype` | `res://assets/sprites/player_swordsman_sheet.png` | 剑士玩家行走方向概念 sheet，透明背景。 |
| 玩家九方向 sheet | `prototype` | `res://assets/sprites/player_swordsman_9dir_sheet.png` | 剑士九宫格方向 sheet，早期玩家场景使用。 |
| 剑士行走动画源图 | `prototype` | `res://assets/sprites/swordsman/swordsman_walk_8dir_v1.png` | 8 方向 walk 动画源图，后续需裁切为严格网格。 |
| 剑士行走测试 atlas | `prototype` | `res://assets/sprites/swordsman/swordsman_walk_8dir_test_atlas.png` | 从源图重排出的 `4x7` 临时测试 atlas。 |
| 剑士 v2 九方向行走 atlas | `production_candidate` | `res://assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png` | 重新生成的 `4x9` 规则 atlas，需实机确认动作观感。 |
| 剑士动作 blockout atlas | `blockout` | `res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png` | 脚本绘制的 `4x9` 动作基底，当前玩家场景使用，用于验证左右方向和步行动画。 |
| 怪物 sprite sheet | `prototype` | `res://assets/sprites/monster_sheet.png` | 野狼、黑狼头目、骷髅矿工、黑石魔像概念 sheet，透明背景。 |
| 道具图标 sheet | `prototype` | `res://assets/items/item_icons_sheet.png` | 装备、药水、材料、任务物品图标，透明背景，后续需重排为规则图标 sheet。 |
| 场景 tileset | `prototype` | `res://assets/tilesets/environment_tileset_v1.png` | 青木村、黑狼林、黑石矿洞方向 tileset，不透明背景，后续需拆成可铺地图块。 |
| UI atlas | `prototype` | `res://assets/ui/ui_atlas.png` | HUD、背包、装备、对话框等 UI 部件，后续需拆成可复用组件。 |
| 测试地图背景 | `prototype` | `res://assets/backgrounds/test_map_background_v1.png` | 统一测试地图背景，用于替代错位的临时 tileset 拼贴。 |

这些资源已通过 Godot 导入流程生成 `.png.import` 文件，并通过 `ResourceLoader.load()` 验证可以加载为 `Texture2D`。

## 当前场景接入

- `godot/scenes/actors/player.tscn` 已使用 `res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png` 根据移动方向和行走帧播放确定性动作基底。
- `godot/scenes/maps/test_map.tscn` 已使用 `res://assets/backgrounds/test_map_background_v1.png` 作为统一测试地图背景，避免非规则 tileset 裁切错位。
- `godot/scenes/ui/hud.tscn` 已使用 `res://assets/ui/ui_atlas.png` 作为 HUD 风格底图，并显示 `res://assets/portraits/character_portrait_direction_v1.png` 角色立绘预览。
- `godot/scenes/ui/menu_overlay.tscn` 默认隐藏，点击 HUD 的 Bag 或 Equip 按钮后显示背包或装备面板。
- `godot/scenes/ui/art_preview.tscn` 已展示玩家、怪物、道具、tileset 和 UI atlas 的缩略预览。
- `godot/scenes/main.tscn` 已实例化 `ArtPreview`，运行主场景时可以在右上角看到资源预览。

## 2026-07-02 静态审计结论

详细记录见 `docs/art/current_asset_audit_2026-07-02.md`。
GUI 视口截图审计见 `docs/art/gui_visual_audit_2026-07-02.md`。

- `swordsman_walk_blockout_v1_atlas.png` 是规则 `4x9`、`192x192` cell 的动作验证资源，继续作为当前玩家动作验证基底。
- `swordsman_walk_9dir_v2_atlas.png` 是规则 `4x9`、`192x192` cell 的外观候选，但步态帧变化偏弱，需 GUI 对比后再决定是否替换 blockout。
- `monster_sheet.png`、`item_icons_sheet.png`、`environment_tileset_v1.png` 和 `ui_atlas.png` 仍属于 `prototype`，可作为方向参考和临时资源，不应直接标记为 `production_ready`。
- `asset_load_test.gd` 已确认当前 Godot 资源引用可以加载。

## 参考资源状态

| 类型 | 状态 | 文件 | 说明 |
| --- | --- | --- | --- |
| 人物立绘方向 | `reference` | `assets/references/character_portrait_direction_v1.png` | 三职业半身像方向参考。 |
| 场景方向 | `reference` | `assets/references/scene_direction_v1.png` | 青木村、黑狼林、黑石矿洞气氛参考。 |
| UI 主参考 | `reference` | `assets/references/ui_direction_primary_v1.png` | HUD、背包、装备面板的主视觉参考。 |
| 装备图标方向 | `reference` | `assets/references/equipment_icon_direction_v1.png` | 装备、药水、材料图标方向参考。 |
| 怪物立绘方向 | `reference` | `assets/references/monster_portrait_direction_v1.png` | 野狼、黑狼头目、矿洞怪物和 Boss 方向参考。 |
| 剑士设计 | `reference` | `assets/references/swordsman_design_preview_v1.png` | 默认剑士主角 v1 方向参考。 |

## 源文件路径

根目录 `assets/` 保留源文件和处理后的透明 PNG：

- `assets/sprites/player_swordsman_sheet_source.png`
- `assets/sprites/player_swordsman_sheet.png`
- `assets/sprites/player_swordsman_9dir_sheet_source.png`
- `assets/sprites/player_swordsman_9dir_sheet.png`
- `assets/references/swordsman_design_preview_v1.png`
- `assets/sprites/swordsman/swordsman_walk_8dir_v1_source.png`
- `assets/sprites/swordsman/swordsman_walk_8dir_v1.png`
- `assets/sprites/swordsman/swordsman_walk_8dir_test.png`
- `assets/sprites/swordsman/swordsman_walk_8dir_test_atlas.png`
- `assets/sprites/swordsman/swordsman_walk_9dir_v2_source.png`
- `assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png`
- `assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png`
- `assets/sprites/monster_sheet_source.png`
- `assets/sprites/monster_sheet.png`
- `assets/items/item_icons_sheet_source.png`
- `assets/items/item_icons_sheet.png`
- `assets/tilesets/environment_tileset_v1.png`
- `assets/ui/ui_atlas_source.png`
- `assets/ui/ui_atlas.png`

## 使用注意

- 这批资源是第一版 AI 生成美术源，不是最终精修切图。
- 透明资源已从绿色 chroma-key 背景处理为 RGBA。
- AI 生成 sheet 的画布尺寸不是严格的 32x32、48x48 或 64x64 网格倍数。
- 接入正式动画前，需要手工裁切、重排或重新绘制为严格网格。
- 当前测试 atlas 是自动抠图和重排版本，仅用于 Godot 实机测试比例、动作和方向感。
- 剑士 v2 atlas 已经是严格 `4x9`、每格 `192x192` 的 Godot 测试规格，但仍需实机确认动作观感。
- blockout atlas 是动作验证资源，不代表最终美术精度；当动作方向确认后再替换为正式精修 sprite。
- v0.2 可先使用这些资源做怪物、道具和 UI 的视觉占位。
