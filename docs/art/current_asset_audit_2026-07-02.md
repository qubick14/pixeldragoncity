# Current Asset Audit 2026-07-02

本文件记录当前像素美术资源的静态视觉审计和导入状态。它不替代 Godot GUI 手动验收；GUI 手感、遮挡、缩放和 UI 重叠仍需要实机窗口确认。

## 审计范围

本次检查：

- 读取 `docs/13_ArtAssetPlan.md` 和 `docs/superpowers/plans/2026-07-02-pixeldragoncity-art-assets.md`。
- 检查关键 PNG 尺寸。
- 直接查看剑士、怪物、物品、UI、tileset 和测试背景图。
- 运行 Godot headless 资源加载测试。

验证命令：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd
```

结果包含：

```text
asset_load_test: PASS
```

## 资源审计表

| 资源 | 尺寸 | 当前状态 | 审计结论 | 下一步 |
| --- | --- | --- | --- | --- |
| `assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png` | `768x1728` | `blockout` | 规则 `4x9` atlas，等价 `192x192` cell。方向、脚步、披肩和武器可读，适合继续验证动作和碰撞。 | 保持为当前动作验证资源；GUI 试玩确认后再决定是否作为正式动画蓝本。 |
| `assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png` | `768x1728` | `production_candidate` | 画面精度明显高于 blockout，角色识别强；但步态帧差异偏弱，可能在实机中显得滑行。 | 暂不直接替换 blockout；先做 GUI 对比，必要时按 v2 外观重绘更强步态。 |
| `assets/sprites/monster_sheet.png` | `1536x1024` | `prototype` | 野狼、黑狼头目、骷髅矿工、黑石魔像轮廓清楚，适合作方向和临时怪物视觉；但不是按单怪严格 grid 拆分的 atlas。 | 单独制作 `wild_wolf` 规则 atlas，优先 idle/walk/attack/hurt/death。 |
| `assets/items/item_icons_sheet.png` | `1774x887` | `prototype` | 图标质量和轮廓好，覆盖武器、防具、药水、金币、材料、任务物；但画布不是规则网格尺寸。 | 重排第一批 `32x32` 图标 sheet，先覆盖木剑、铁剑、布衣、皮甲、草药、生命药水、金币、狼皮、狼牙、黑色晶片。 |
| `assets/ui/ui_atlas.png` | `1536x1024` | `prototype` | UI 风格统一，暗木/青铜/皮革方向成立，包含 HUD、面板、格子、按钮和品质框；但需要拆成可复用切片。 | 为 v0.4 拆分 HUD 底板、血魔经验条、格子、按钮、面板和 tooltip 背板。 |
| `assets/tilesets/environment_tileset_v1.png` | `1254x1254` | `prototype` | 场景方向完整，村庄、森林、矿洞、木石建筑和边界件都可读；但不是 `32x32` 规则 tileset。 | 制作黑狼林第一版 `32x32` tileset，再制作青木村第一版 `32x32` tileset。 |
| `assets/backgrounds/test_map_background_v1.png` | `1586x992` | `prototype` | 背景整体观感好，适合测试地图氛围展示；但不是可编辑 tilemap。 | 保留为测试背景，不作为正式地图生产方式。 |

## 剑士资源结论

当前玩家应继续使用 `swordsman_walk_blockout_v1_atlas.png` 做动作验证。它的美术精度低，但方向和步态读得出来，适合验证玩家控制、相机缩放、碰撞和攻击接入。

`swordsman_walk_9dir_v2_atlas.png` 可以作为外观方向候选，但还不能标记为 `production_ready`。主要原因是四帧之间变化偏弱，实机移动可能仍像贴图平移。下一轮应在 Godot GUI 中对比 blockout 与 v2：如果 v2 观感滑行，就以 v2 造型为基础重绘更夸张的腿部与披肩帧。

## 怪物资源结论

`monster_sheet.png` 的野狼和黑狼头目方向可用，轮廓比当前临时怪物更清楚。但它是混合概念 sheet，不适合作为长期动画资源。下一步应优先制作 `wild_wolf` 专用 atlas。

推荐 `wild_wolf` 第一版规格：

- cell：`96x64` 或 `128x96`，以实机缩放为准。
- 方向：先做 4 方向，必要时左右镜像。
- 动作：idle 2 帧、walk/run 4 帧、attack 4 帧、hurt 1 帧、death 4 帧。
- 输出：透明背景、严格网格、脚底或身体中心对齐。

## 图标资源结论

`item_icons_sheet.png` 可以作为第一批图标重排来源或方向参考。它不能直接作为正式图标 sheet，因为尺寸不是规则网格，图标之间间距也不统一。

下一步应创建 `assets/items/item_icons_32_v1.png`，对应 Godot 路径 `res://assets/items/item_icons_32_v1.png`。第一批只做 MVP 所需物品，不扩展远期装备池。

## UI 资源结论

`ui_atlas.png` 的视觉方向已经适合继续推进 v0.4，但应该从“整张展示图”拆成 Godot 可复用的 UI 部件。优先拆：

- HUD 底板。
- 生命、魔法、经验条。
- 物品格、装备槽、快捷栏格。
- 面板边框和 9-slice 背板。
- tooltip 背板和按钮状态。

## Tileset 资源结论

`environment_tileset_v1.png` 是很好的方向图，但不能直接作为正式 tilemap 生产资源。下一步不要试图从整张图硬切出全部地图，而是以它为风格参考，单独制作黑狼林 `32x32` 第一版。

黑狼林第一版优先件：

- 草地、泥路、暗草边缘。
- 树、灌木、石头、断木。
- 不可通行森林边界。
- 草药采集点。
- 黑狼头目区域边界。
- 回村入口和矿洞方向提示件。

## 待办结论

可以标记完成：

- 现有资源静态视觉与导入审计。

仍需保留待办：

- Godot GUI 观感审计。
- 剑士 blockout atlas 实机手感确认。
- 野狼正式或半正式 atlas。
- 第一批 `32x32` 物品图标规则 sheet。
- UI atlas 核心拆件。
- 黑狼林与青木村第一版 `32x32` tileset。
