# 12 Art Direction

## 当前美术方向

《像素龙城》采用原创像素美术，参考经典 2D 斜俯视 ARPG 的视觉语法，但不复制任何商业游戏素材、UI 图形、字体、地图块、怪物、角色造型、文本或音效。

当前已确认的整体方向：

- 地图视角：斜俯视或近似 2.5D。
- 地图角色：非 Q 版，人物在场景中偏小，保留足够地图视野。
- 人物立绘：像素半身像，用于角色、装备和重要 NPC 对话。
- UI：以 `assets/references/ui_direction_primary_v1.png` 为第一版主参考。
- 质感：暗木、石、青铜、皮革、暗绿森林、暖色村庄灯光、黑石矿洞。

## 参考图

| 类型 | 文件 | 用途 |
| --- | --- | --- |
| 人物立绘 | `assets/references/character_portrait_direction_v1.png` | 三职业半身像方向参考。 |
| 场景方向 | `assets/references/scene_direction_v1.png` | 青木村、黑狼林、黑石矿洞气氛参考。 |
| UI 主参考 | `assets/references/ui_direction_primary_v1.png` | HUD、背包、装备面板的主视觉参考。 |
| 装备图标 | `assets/references/equipment_icon_direction_v1.png` | 装备、药水、材料图标方向参考。 |
| 怪物立绘 | `assets/references/monster_portrait_direction_v1.png` | 野狼、黑狼头目、矿洞怪物和 Boss 方向参考。 |
| 剑士设计 | `assets/references/swordsman_design_preview_v1.png` | 默认剑士主角 v1 方向参考。 |

这些图片是方向稿，不是最终游戏切图。正式资源需要重新拆分、清理、统一尺寸、透明背景和导入配置。

## 第一批可用资源

第一批生成资源已经保存到 `assets/` 和 `godot/assets/`。具体路径见 `assets/ASSET_MANIFEST.md`。

当前可在 Godot 中引用：

- `res://assets/sprites/player_swordsman_sheet.png`
- `res://assets/sprites/monster_sheet.png`
- `res://assets/items/item_icons_sheet.png`
- `res://assets/tilesets/environment_tileset_v1.png`
- `res://assets/ui/ui_atlas.png`
- `res://assets/portraits/swordsman_portrait_v1.png`

这些资源可用于 v0.2 到 v0.4 的原型占位，但仍需后续裁切和精修。

## 美术资源生产计划

详细资源开发计划见 `docs/13_ArtAssetPlan.md`。

当前资源分为方向参考、原型占位、动作 blockout、正式候选和正式资源。方向参考图不直接作为游戏切图；AI 生成 sheet 如果不是严格网格，需要重切、重排或重绘；blockout atlas 只用于验证方向、步行动作和碰撞观感，不代表最终美术精度。

近期美术生产优先级：

1. 确认剑士 blockout atlas 的 GUI 动作观感。
2. 制作野狼正式或半正式 atlas。
3. 制作第一批 `32x32` 物品图标规则 sheet。
4. 拆分 UI atlas 的 HUD、格子、按钮和面板资源。
5. 制作黑狼林第一版 `32x32` tileset。

## UI 方向

用户对第一版生成结果中的第三张 UI 界面比较满意，因此 UI 当前以 `ui_direction_primary_v1.png` 为主参考。

具体布局、尺寸、颜色、tooltip 和模态规则见 `docs/13_UIStyleGuide.md`。

保留方向：

- 底部 HUD 固定显示生命、魔法、快捷栏、经验和金币。
- 背包与装备界面采用高密度格子布局。
- 装备面板预留像素半身立绘区域。
- 面板材质偏暗木、石、青铜和皮革。
- 整体有经典 RPG 重量感，而不是现代扁平 UI。

后续调整：

- 降低复杂度，避免面板过满。
- 保证文字和图标在 Godot 中清晰可读。
- 优先制作 HUD、背包、装备三个核心界面。
- 图标先做 32x32 或 48x48，再根据 UI 格子尺寸统一。

## 人物立绘方向

第一版人物立绘采用三职业半身像：

- 剑士：铁甲、皮革、宽剑，气质沉稳。
- 法师：深蓝和火焰色 robe，法杖，远程职业辨识度强。
- 灵术师：玉色、符纸、灵体元素，突出东方奇幻特色。

暂不锁死具体脸型、服装和最终姿势。立绘可后续单独讨论和重做。

### 剑士 v1 方向

参考图：`assets/references/swordsman_design_preview_v1.png`

当前剑士采用“边境佣兵 + 少量流浪剑客”的方向：

- 气质：冷静、耐打、有野外刷怪经验，但不是传奇英雄开局。
- 年龄：青年到年轻成人。
- 体型：中等偏结实，不做 Q 版。
- 识别元素：暗红围巾或短披肩、铁肩甲、皮革胸甲、旅行腰包、单手宽剑。
- 色彩：铁灰、深棕、暗红，少量青铜高光。
- 地图 sprite：保留暗红披肩作为小尺寸识别点。

后续可调整：

- 脸型、发型和具体姿势。
- 披肩长度和盔甲复杂度。
- 宽剑形状，避免过大导致地图 sprite 难读。

剑士地图 sprite 和行走动画规格见 `docs/art/swordsman_sprite_animation_spec.md`。

当前 UI 面板使用 `assets/portraits/swordsman_portrait_v1.png` 作为默认剑士单人半身立绘。旧的 `assets/references/character_portrait_direction_v1.png` 继续保留为三职业方向参考，不作为当前剑士 UI 立绘。

## 场景方向

第一版场景方向包含：

- 青木村：木石建筑、暖灯、村庄安全感。
- 黑狼林：暗绿森林、雾、可读路径、野外遇敌空间。
- 黑石矿洞：黑石、矿灯、支架、地下城压迫感。

地图制作时先保证可走路径、边界、入口、出口和刷怪区域清楚，再增加装饰。

## 装备图标方向

装备图标要优先保证轮廓清楚和品质可读：

- 普通：白色或低饱和金属。
- 优秀：绿色。
- 稀有：蓝色。
- 史诗：紫色。
- 传说：橙色。

MVP 阶段先做木剑、铁剑、布衣、皮甲、药水、金币、狼牙、草药和黑石矿。

## 怪物方向

主要怪物第一批方向：

- 野狼：普通森林怪物，轮廓清楚。
- 黑狼头目：第一只 Boss，体型和气势明显强于普通狼。
- 骷髅矿工：黑石矿洞普通怪。
- 矿洞小怪：用于填充矿洞战斗节奏。
- 黑石魔像：矿洞 Boss 或中期 Boss 方向。

怪物地图 sprite 和怪物立绘可以分开制作，不要求从同一张图直接缩放。
