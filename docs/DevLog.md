# DevLog

## 2026-07-11 剑士攻击动画接入状态机

完成：

- 旧 `swordsman_attack_blockout_v1_atlas.png` 为 192px blockout 风格，与本次重做的像素剑士（32×40）不匹配；改为在 `build_pixel_art_pack.py` 生成与行走图同布局的像素攻击 atlas `swordsman_attack_pixel_atlas.png`（4×9，4 帧挥砍 + 金色斩击弧，8 向 + 待机）。
- `player_controller.gd`：新增 `attack_anim_time` 与 `_attack_anim_timer`，攻击时把 `GeneratedSprite` 贴图临时切换到攻击 atlas 并按计时器播放 4 帧,结束后切回行走 atlas;移除多边形 `AttackSlash`(斩击弧已烘焙进帧);命中判定窗口(`_attack_active_timer`)与视觉动画时长解耦。
- `_update_generated_sprite_region` 增加防御性 `generated_sprite` 取值与 `_walk_texture` 懒加载,兼容未 `_ready` 直接调用的测试路径。

验证：

- `player_input_and_ui_test.gd` 断言由"多边形斩击可见"更新为"攻击时贴图切到攻击 atlas"：`PASS`。
- 全量 headless 测试 14/15 `PASS`（仅 `visual_snapshot_test` 需真实渲染器）。
- 实机截图：向下挥砍动作正常显示剑刃前伸与斩击弧。

## 2026-07-11 v0.6 剑士技能系统

完成：

- `GameData` 读取 `skills.json`，新增 `get_skill` / `get_skills_for_class`，并纳入 `load_all`。
- `skills.json` 补 `icon_index`；生成剑士技能像素图标 `ui/skill_icons_sheet.png`（普通斩击/重斩/火球）。
- 玩家新增 MP 资源（`max_mp`、`current_mp`、`mp_regen`、`mana_changed` 信号）与技能系统：`use_skill` 按每技能冷却、MP 消耗与 `multiplier` 结算伤害（`damage = round(attack * multiplier)`），普通攻击键复用技能槽 0（普通斩击）。
- `project.godot` 新增输入 `skill_slot_1` / `skill_slot_2`（键 1 / 2）。
- HUD 快捷栏 `set_quick_slot` 升级为显示技能图标 + 键位数字 + 冷却遮罩，并接入真实 MP 显示；`main.gd` 装配剑士技能栏、连接 `mana_changed` 与逐帧冷却刷新。
- 实施计划见 `docs/superpowers/plans/2026-07-11-pixeldragoncity-v0.6.md`。

验证：

- 新增 `v07_skill_system_test.gd`：`PASS`（技能栏 2 技能、MP 不足拒绝、普通斩击 0 MP 且伤害=攻击力、重斩耗 5 MP 且伤害=round(攻击力×1.8)、冷却门控）。
- 全量 headless 测试 14/15 `PASS`（仅 `visual_snapshot_test` 需真实渲染器）。
- 实机截图：HUD 显示 MP 40/40 与 1、2 号技能图标。

## 2026-07-11 像素美术整体重做 + 可玩闭环打通

完成：

- 新增统一像素美术生成管线 `tools/build_pixel_art_pack.py`（共享调色板 + 程序化像素绘制），一键生成背景、人物、怪物、物品图标与 HUD 面板，风格统一。
- 背景重做：生成青木村 `greenwood_village_bg.png` 与黑狼林 `black_wolf_forest_bg.png` 像素背景（草地纹理、泥土路径、树木、房屋、Boss 空地），替换原地图的纯色 `Polygon2D` 地面。
- 人物重做：生成剑士像素行走 atlas `swordsman_pixel_atlas.png`（4x9，8 向 + 待机，含 4 帧走路循环），接入 `player.tscn` 并启用最近邻过滤。
- 怪物重做：生成侧面像素狼 `wolf_pixel_sheet.png`，接入 `wild_wolf.tscn`；`wild_wolf_controller.gd` 按目标水平方向翻转朝向。
- 物品图标重做：生成 `item_icons_sheet.png`（木剑/铁剑/布衣/皮甲/药水/狼皮/金币），并在 `items.json` 补 `icon_index`。
- 打通实机可玩闭环（怪物→战斗→掉落→拾取→装备）：`main.gd` 新增 live 会话（InventoryModel + EquipmentModel），掉落物走过即拾取（`dropped_item.gd` 接 `body_entered`），背包/装备面板改由实时数据驱动并显示图标，点击背包物品可装备并即时刷新 ATK/DEF/HP。
- HUD 重做：将 `ui_atlas.png` 底栏区重绘为像素木质面板（红/蓝宝珠、HP/MP 内嵌槽、6 快捷槽、右侧等级金币牌），沿用原有裁切区域，无需改场景。

验证：

- `tools/build_pixel_art_pack.py` 生成全部资源；`Godot --headless --path godot --import` 导入通过。
- 新增 `v06_pickup_equip_test.gd`：`PASS`（拾取皮甲→装备→DEF +3，装备槽与背包显示同步）。
- 全量 headless 测试 13/14 `PASS`；仅 `visual_snapshot_test`（需真实渲染器）在 headless 下无法截图，非 headless 下 `PASS`。
- 实机截图验证：村庄/森林像素场景、背包图标、装备面板（装木剑后 ATK 12→14）与像素 HUD 均正常。

## 2026-07-09 v0.4 HUD 自适应整改

完成：

- 根据用户截图修复不同窗口尺寸下血条、快捷栏和右侧菜单错位、拉伸及热点偏移问题。
- 确认根因是固定位置 `Sprite2D` 与 `Control` 混用，导致主布局存在两套坐标系；改为统一的 `LayoutRoot`，并将 HUD atlas 裁成左、中、右三区独立缩放。
- 将 HP、MP 改为 `ProgressBar`，保持状态值与条形反馈同步。
- 将右侧菜单入口改为 atlas 图标上的透明 `flat` 按钮热点，并补充 tooltip。
- 修复 `MenuOverlay` 与 `UIRoot` 双开后残留面板的问题，恢复主要面板互斥和关闭行为。
- 新增 `hud_responsive_layout_test.gd`，覆盖三区布局、尺寸约束、状态条和菜单按钮契约。

验证：

- Godot 项目 parse 检查通过。
- `hud_responsive_layout_test.gd`：`PASS`。
- `player_input_and_ui_test.gd`：`PASS`。
- `ui_panels_test.gd`：`PASS`。
- `v05_new_player_loop_test.gd`：`PASS`。
- 1280 x 720：`/private/tmp/pixeldragoncity_hud_1280x720.png`
- 1600 x 900：`/private/tmp/pixeldragoncity_hud_1600x900.png`
- 嵌入窗口：`/private/tmp/pixeldragoncity_hud_embedded_1498x843.png`（实际截图尺寸为 1498 x 842）

待完成：

- 背包、装备、NPC 对话和商店四个主要面板仍需完成视觉整改。
- 正式拆分 UI atlas 核心 HUD、格子、按钮和面板资源；本次仅使用运行时 `AtlasTexture` 裁区，未生成独立资产。

## 2026-07-09 剑士普通攻击 blockout atlas

完成：

- 新增严格 `6x9`、每格 `192x192` 的剑士普通攻击动作验证 atlas，覆盖八方向与正面参考行。
- 定义预备、蓄力、起挥、命中、随挥、收势六帧节奏，第 4 帧作为主要命中帧。
- 新增确定性生成脚本、资源契约测试和独立动作规格文档。
- 保持本批资源为 `blockout`，未修改并行开发中的玩家控制器和场景。

验证：

- `HOME=/tmp/pixeldragoncity-godot /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/swordsman_attack_asset_test.gd`
- 输出包含 `swordsman_attack_asset_test: PASS`。

待完成：

- 将攻击 atlas 接入玩家状态机，使第 4 帧与 `AttackHitbox` 有效窗口对齐。
- Godot GUI 下确认八方向剑尖范围、命中节奏和脚底稳定性。

## 2026-07-09 v0.2 战斗验收回归

完成：

- 复跑生命组件、战斗流程和主场景战斗验收。
- 修正 `combat_playthrough_test.gd` 对旧 HUD 排版路径的硬编码，改为在 HUD 边界内查找 `HpValue`，继续验证玩家受伤后的生命显示，同时不再依赖具体布局层级。
- 使用 Godot 正常渲染模式生成并检查主场景截图，确认玩家、HUD、生命/法力文本和底栏可见。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/pdc_combat_component.log --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/pdc_combat_flow.log --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/pdc_combat_playthrough.log --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://scripts/tests/visual_snapshot_test.gd`
- `git diff --check`

待人工复核：

- 静态截图无法评价攻击节奏、野狼追踪、受击停顿和死亡反馈的实际手感；`TODO.md` 中 v0.2 Godot GUI 手动验收继续保留为未完成。
- 并行进行中的 v0.4 HUD/UI 修改使 `player_input_and_ui_test.gd` 当前出现面板可见性断言失败；该问题不属于 v0.2 战斗范围，本次未修改对应 UI 行为。

## 2026-07-08 v0.5 实机操作问题修复

完成：

- 修复 HUD 鼠标点击无效问题：移除 `UIRoot` 内重复实例化的 HUD，避免高层 CanvasLayer 抢占 Bag / Equip 按钮点击；`Main/HUD` 继续作为唯一可点击 HUD。
- 调整 `UIRoot` 的 demo 状态加载，使它只在存在兄弟节点 `HUD` 时同步血量、蓝量、经验、金币和等级，不再依赖自身包含 HUD。
- 为玩家 `start_attack()` 增加短暂 `ATTACK` 动作状态和朝向位移反馈，使 `Space` / `J` 攻击时有可见动作，同时保留原有 AttackHitbox 伤害逻辑。
- 修复底部 HUD 装饰框和可点击底板高度不一致的问题，使底部 UI 底板高度跟随生成 UI frame。
- 为 Bag / Equip 增加二次点击关闭逻辑：当前页已打开时再次点击对应按钮会关闭菜单。
- 为玩家攻击增加 `AttackSlash` 武器挥击可视节点，攻击开始显示，攻击判定结束时隐藏。
- 补充回归测试，覆盖攻击可见状态和 `UIRoot` 不再包含重复 HUD 的约束。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`

待人工复核：

- Godot GUI 下重新试玩：点击 Bag / Equip 应打开对应界面；按 `Space` / `J` 应看到角色短促攻击动作，并能命中近处怪物。

## 2026-07-07 v0.4 GUI 截图验收与布局修正

完成：

- 使用 Godot 正常渲染模式运行 `/private/tmp/pixeldragoncity_v04_ui_capture.gd`，生成并检查 v0.4 背包、装备、对话和商店截图。
- 修复 GUI 截图中发现的面板可读性问题：为背包、装备、对话、商店、物品格和 tooltip 添加暗色底板与青铜边框。
- 调整装备面板半身立绘位置，避免装备槽位与立绘区域重叠。
- 调整对话面板位置，避免按钮和对话底板压住底部 HUD。
- 更新 `TODO.md`、`README.md` 和 `docs/11_DevelopmentPlan.md`，同步 v0.4 GUI 截图验收完成状态。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --path godot --script /private/tmp/pixeldragoncity_v04_ui_capture.gd`
- 截图输出：
  - `/private/tmp/pixeldragoncity_v04_inventory.png`
  - `/private/tmp/pixeldragoncity_v04_equipment.png`
  - `/private/tmp/pixeldragoncity_v04_dialogue.png`
  - `/private/tmp/pixeldragoncity_v04_shop.png`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`

待完成：

- 后续美术精修仍需把物品图标从 sheet 正式裁切接入；当前背包和装备槽位以占位格、数量和半身像预览验证布局。

## 2026-07-07 v0.5 headless 验收复核

完成：

- 复跑 v0.5 自动化验收，确认地图、NPC、任务、敌人/Boss、掉落装备、保存读取和 UI 数据链路仍保持通过。
- 复跑资源和剑士动作审计相关 headless 测试，确认当前资源可加载，动作审计图可生成。
- 保留 `TODO.md` 中 `v0.5 10 分钟手动验收` 为未完成，因为尚未进行 Godot GUI 人工路线试玩。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_sprite_asset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/swordsman_walk_audit_image.gd`
- `jq empty data/items.json data/monsters.json data/maps.json data/npcs.json data/shops.json data/skills.json data/ui_demo_state.json`

已知限制：

- `visual_snapshot_test.gd` 在 headless dummy renderer 下失败，错误为无法获取 viewport 图像；该测试需要非 dummy renderer 或 GUI 环境。
- v0.5 仍需要人工 GUI 路线验收：从青木村出生、接任务、进黑狼林、战斗、拾取装备、击败 Boss、回村交付、保存读取。

## 2026-07-07 v0.5 headless 闭环状态收口

完成：

- 更新 `README.md`，将当前阶段从 v0.4 headless 闭环改为 v0.5 新手流程 headless 闭环完成，下一步聚焦 10 分钟 GUI 手动验收和 v0.4 UI 观感补验。
- 更新 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`，补齐 Task 1、Task 5 和 Task 7 的已完成复选框，并说明最小掉落/拾取/背包/装备闭环复用 v0.3 `InventoryModel`、`EquipmentModel` 和 `DroppedItem`。
- 更新旧 DevLog 段落，把已经由 2026-07-05 到 2026-07-06 后续条目完成的黑狼头目、真实任务死亡事件、保存读取和占位 TileSet 风险改为后续完成说明。

验证：

- `jq empty data/items.json data/monsters.json data/maps.json data/npcs.json data/shops.json data/ui_demo_state.json`
- `test -f docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`

待完成：

- v0.5 10 分钟 Godot GUI 手动验收。
- v0.4 UI 布局、按钮、tooltip 和遮挡观感补验。
- v0.2 战斗手感人工验收。

## 2026-07-06 剑士步行动作帧审计

完成：

- 新增 `godot/scripts/tests/swordsman_walk_audit_image.gd`，将剑士 blockout atlas 与 v2 atlas 按 `9` 行方向、每行 `4` 帧拼成审计图。
- 新增 `docs/art/swordsman_walk_cycle_audit_2026-07-06.md`，记录完整步行动作帧审计结论。
- 确认 `swordsman_walk_blockout_v1_atlas.png` 四帧步态变化明显，适合继续作为当前动作验证资源。
- 确认 `swordsman_walk_9dir_v2_atlas.png` 外观更接近最终方向，但步态变化偏弱，暂不建议直接替换 blockout。
- 更新 `TODO.md` 和 `docs/art/gui_visual_audit_2026-07-02.md`，把“动作帧可读”与“人工实机手感”拆开跟踪。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/swordsman_walk_audit_image.gd`
- 输出包含 `swordsman_walk_audit_image: PASS /tmp/pixeldragoncity_swordsman_walk_audit.png 1192x1296`。

待完成：

- 人工移动试玩确认剑士 blockout atlas 在实际连续移动中的手感。
- 后续正式剑士 walk atlas 需要结合 v2 外观和 blockout 动作幅度重新绘制。

## 2026-07-06 Git 管理初始化

完成：

- 初始化项目 Git 仓库，并将默认分支设为 `main`。
- 扩展 `.gitignore`，忽略本地代理状态、macOS 噪声、Godot 生成缓存、导出包、日志、临时文件和本地录屏。
- 保留 Godot `.import` 与 `.uid` 等项目资源元数据进入版本管理，避免资源引用在其他工作区丢失。
- 更新 v0.2 与 v0.5 实施计划中“当前不是 Git 仓库”的过期说明。

验证：

- `git diff --cached --check` 通过。
- 已创建初始提交 `Initial project import`，纳入 221 个项目文件，作为后续开发基线。

## 2026-07-06 v0.5 地图占位 TileSet 接入

完成：

- 新增 `godot/resources/tilesets/environment_placeholder_tileset.tres`，用现有原创 `environment_tileset_v1.png` 创建可替换占位 TileSet。
- 更新 `godot/scenes/maps/greenwood_village.tscn` 和 `godot/scenes/maps/black_wolf_forest.tscn`，为两张 v0.5 地图加入 `PlaceholderTileLayer`。
- 扩展 `godot/scripts/tests/asset_load_test.gd`，验证占位 TileSet 可加载为 `TileSet`，并验证两张地图都引用了占位 tile 层。
- 更新 `TODO.md` 和 `docs/11_DevelopmentPlan.md`，标记 v0.5 的青木村/黑狼林 tileset 或占位 tileset 完成；正式 `32x32` tileset 美术制作仍留在美术管线待办中。

验证：

- 红灯验证：`asset_load_test.gd` 曾失败于缺少 `res://resources/tilesets/environment_placeholder_tileset.tres`、`GreenwoodVillage/PlaceholderTileLayer` 和 `BlackWolfForest/PlaceholderTileLayer`。
- 绿灯验证：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot -s res://scripts/tests/asset_load_test.gd` 输出 `asset_load_test: PASS`。

待完成：

- v0.5 10 分钟 Godot GUI 手动验收。
- 正式青木村和黑狼林 `32x32` tileset 美术制作与替换。

## 2026-07-05 v0.5 保存与读取

完成：

- 新增 `godot/scripts/game/save_manager.gd`，提供 v0.5 JSON 存档 payload 构建、写入、读取、缺档新游戏 payload 和版本不匹配可恢复失败。
- 更新 `godot/scenes/main.tscn`，在主场景中加入 `SaveManager` 节点。
- 扩展 `godot/scripts/tests/v05_new_player_loop_test.gd`，覆盖当前地图、出生点、玩家位置、金币、背包、装备、`first_hunt` 状态、野狼击败数和黑狼头目击败标记的保存 payload。
- 测试覆盖临时 JSON 存档写读、缺少存档时创建新游戏 payload、错误版本存档返回 `unsupported_version` 且不崩溃。
- 更新 `TODO.md`、v0.5 实施计划和 `docs/11_DevelopmentPlan.md`，同步保存读取 headless 闭环状态。

验证：

- 红灯验证：`v05_new_player_loop_test.gd` 曾因 `res://scripts/game/save_manager.gd` 不存在而解析失败。
- 绿灯验证：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot -s res://scripts/tests/v05_new_player_loop_test.gd` 输出 `v05_new_player_loop_test: PASS`。

待完成：

- v0.5 10 分钟 Godot GUI 手动验收。

## 2026-07-05 v0.5 黑狼林敌人与 Boss 任务推进

完成：

- 扩展 `godot/scripts/tests/v05_new_player_loop_test.gd`，覆盖黑狼林真实野狼死亡计数、黑狼头目死亡后 `first_hunt` 进入 `ready_to_turn_in`。
- 更新 `godot/scenes/maps/black_wolf_forest.tscn`，在 `Enemies` 下放置 3 只 `wild_wolf` 和 1 个使用 `black_wolf_leader` 配置的临时黑狼头目。
- 更新 `godot/scripts/game/map_manager.gd`，新增 `map_loaded` 信号，便于主场景在地图切换后接入地图内实体。
- 更新 `godot/scripts/game/main.gd`，把敌人 `HealthComponent.died` 信号接到 `QuestManager`，让真实死亡事件推进 `first_hunt`。
- 更新 `TODO.md`、v0.5 实施计划和 `docs/11_DevelopmentPlan.md`，同步第一个 Boss 与真实任务战斗事件状态。

验证：

- 红灯验证：`v05_new_player_loop_test.gd` 曾失败于 `Black Wolf Forest should include actual enemy instances`。
- 绿灯验证：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd` 输出 `v05_new_player_loop_test: PASS`。

待完成：

- v0.5 保存与读取。
- v0.5 10 分钟 Godot GUI 手动验收。
- 青木村和黑狼林第一版 tileset 或可替换占位 tileset。

## 2026-07-02 HUD 与调试预览遮挡修正

完成：

- 更新 `godot/scenes/ui/hud.tscn`，扩宽并左移 `StatusLabel`，同时左移 Bag / Equip 按钮区域，减少等级、经验、金币文本与按钮挤压和右侧裁切风险。
- 更新 `godot/scenes/ui/art_preview.tscn`，将 `ArtPreview` 默认隐藏，保留节点用于调试和资源审计。
- 更新 `godot/scenes/ui/hud.tscn`，将 `CharacterPortrait` 默认隐藏，避免角色立绘方向稿常驻遮挡地图画面。
- 扩展 `godot/scripts/tests/player_input_and_ui_test.gd`，加入 HUD 状态区域宽度、按钮间距、右边缘风险、ArtPreview 默认隐藏和 HUD 角色立绘默认隐藏断言。
- 更新 `docs/art/gui_visual_audit_2026-07-02.md` 和 `TODO.md`，记录修正结果与剩余步行动作手感审计。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://scripts/tests/visual_snapshot_test.gd`
- 非 headless 快照输出包含 `visual_snapshot_test: PASS /tmp/pixeldragoncity_visual_snapshot.png`。

待完成：

- 人工移动试玩，确认剑士 blockout atlas 的完整步行动作手感。
- 后续 UI 精修时可为右侧状态文本单独制作像素状态底板。

## 2026-07-02 像素美术资源 GUI 观感审计

完成：

- 新增 `godot/scripts/tests/visual_snapshot_test.gd`，用于非 headless Godot 运行主场景并保存视口截图到 `/tmp/pixeldragoncity_visual_snapshot.png`。
- 新增 `docs/art/gui_visual_audit_2026-07-02.md`，记录 GUI 视口截图审计结论。
- 确认 headless dummy renderer 无法提供 viewport texture；脚本会明确报错，非资源加载失败。
- 使用非 headless Godot 成功生成截图，并确认剑士 blockout 在当前相机和窗口尺寸下静态比例可读。
- 更新 `TODO.md`，标记 GUI 观感审计完成，并保留完整步行动作手感、HUD 右侧挤压、ArtPreview 默认显示等后续任务。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/visual_snapshot_test.gd`
- 输出说明 headless/dummy renderer 无法截图。
- `/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://scripts/tests/visual_snapshot_test.gd`
- 输出包含 `visual_snapshot_test: PASS /tmp/pixeldragoncity_visual_snapshot.png`。

待完成：

- 人工移动试玩，确认剑士 blockout atlas 的完整步行动作手感。
- 修正 HUD 右侧等级、经验、金币文字挤压和裁切风险。
- 将 `ArtPreview` 改为 debug-only 或默认隐藏。

## 2026-07-02 v0.4 正式地图 NPC 交互收口

完成：

- 更新 `godot/scripts/actors/npc_interaction.gd`，让正式地图 NPC 的 `interact()` 自动查找主场景 `UIRoot` 并调用 `show_dialogue(npc_id)`，同时保留原有 `interacted` 信号。
- 扩展 `godot/scripts/tests/ui_panels_test.gd`，覆盖青木村 `VillageChiefNpc`、`MerchantNpc` 和 `BlacksmithNpc` 的正式地图交互入口。
- 验证村长交互仍会保持 `first_hunt` 任务行为，商人对话可打开 `merchant_general_store`，铁匠对话可打开 `blacksmith_basic_gear`。
- 更新 `README.md`、`TODO.md`、`docs/02_Roadmap.md` 和 `docs/11_DevelopmentPlan.md`，将 v0.4 标记为 headless 闭环完成、GUI 手动验收待完成。

验证：

- `jq empty data/items.json data/monsters.json data/maps.json data/npcs.json data/shops.json data/ui_demo_state.json`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`

待完成：

- 手动运行 Godot GUI 验收 v0.4 UI 布局、重叠、按钮和 tooltip 观感。
- v0.5 黑狼头目、真实任务战斗事件、保存读取和占位 TileSet 层已在 2026-07-05 到 2026-07-06 的后续条目中完成；当前仅剩 v0.5 10 分钟手动验收。

## 2026-07-02 像素美术资源静态审计

完成：

- 新增 `docs/art/current_asset_audit_2026-07-02.md`，记录当前玩家、怪物、物品、UI、tileset 和测试背景资源的静态视觉审计。
- 检查关键 PNG 尺寸，确认剑士 blockout atlas 与 v2 atlas 均为 `768x1728`，对应规则 `4x9`、`192x192` cell。
- 确认 `swordsman_walk_blockout_v1_atlas.png` 适合作为当前动作验证资源，但不代表最终美术精度。
- 确认 `swordsman_walk_9dir_v2_atlas.png` 是外观更好的正式候选，但步态帧变化偏弱，需要 GUI 对比后再决定是否替换。
- 更新 `assets/ASSET_MANIFEST.md` 和 `TODO.md`，记录静态审计结论和后续 GUI 观感审计待办。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- 输出包含 `asset_load_test: PASS`。

待完成：

- 运行 Godot GUI 观感审计，确认剑士 blockout atlas、v2 atlas、UI 和地图背景在实际窗口中的缩放、遮挡和重叠情况。
- 制作野狼正式或半正式 atlas、第一批 `32x32` 物品图标规则 sheet、UI 核心拆件和黑狼林第一版 tileset。

## 2026-07-02 像素美术资源开发计划

完成：

- 新增 `docs/13_ArtAssetPlan.md`，作为像素美术资源开发、状态分级、阶段推进和文档维护的总计划。
- 新增 `docs/superpowers/plans/2026-07-02-pixeldragoncity-art-assets.md`，作为后续 AI 或开发者推进美术资源管线的实施计划。
- 更新 `docs/12_ArtDirection.md`，把美术方向与资源生产计划连接起来，并明确方向稿、原型资源、blockout 和正式候选的区别。
- 更新 `assets/ASSET_MANIFEST.md`，增加 `reference`、`prototype`、`blockout`、`production_candidate`、`production_ready` 状态口径，并为当前资源补充分类。
- 更新 `TODO.md`，新增像素美术资源管线任务。
- 更新 `prompts/art.md`，补充美术生成标准输出契约和拒收条件。
- 更新 `docs/11_DevelopmentPlan.md`，加入 `docs/13_ArtAssetPlan.md` 作为美术资源开发计划入口。

待完成：

- 完成当前 Godot GUI 观感审计，确认剑士 blockout atlas 的方向和步行动作。
- 制作剑士普通攻击 atlas、野狼正式或半正式 atlas、第一批 `32x32` 物品图标规则 sheet。
- 拆分 UI atlas 核心面板和格子资源，制作黑狼林与青木村第一版 tileset。

## 2026-07-02 v0.4 UI、NPC 与商店实现

完成：

- 新增 `data/npcs.json`、`data/shops.json` 和 `data/ui_demo_state.json`，提供 NPC 对话、商店商品和 v0.4 UI 演示状态。
- 新增 `godot/scripts/data/json_data_loader.gd` 与 `godot/scripts/tests/ui_data_load_test.gd`，验证 Godot 可读取 v0.4 JSON 数据。
- 新增 `godot/scripts/ui/hud.gd` 并更新 `godot/scenes/ui/hud.tscn`，为 HUD 提供生命、魔法、经验、等级、金币和快捷栏更新接口。
- 新增可复用 `item_slot` 与 `item_tooltip` 场景/脚本。
- 新增 `inventory_panel`、`equipment_panel`、`dialogue_panel`、`shop_item_row`、`shop_panel` 和 `ui_root` 场景/脚本。
- 更新 `godot/scenes/ui/menu_overlay.tscn`，保留旧菜单兼容性的同时挂入新的背包和装备面板。
- 更新 `godot/scenes/main.tscn` 与 `godot/scripts/game/main_menu_controller.gd`，并入 `UIRoot`，同时保留旧 `MenuOverlay` 回归行为。
- 新增 `docs/13_UIStyleGuide.md`，记录 v0.4 像素 UI 的尺寸、颜色、tooltip、品质色和模态规则。
- 更新 `TODO.md`，标记已通过 headless 验证的 v0.4 UI 子任务。
- 将商人 `MerchantNpc` 和铁匠 `BlacksmithNpc` 接入青木村正式地图。
- 更新 `godot/scripts/game/main.gd`，玩家与最近 NPC 交互时会通过 `UIRoot.show_dialogue(npc_id)` 打开 NPC 对话；商人对话可继续打开 `merchant_general_store` 商店。
- 更新 `godot/scripts/actors/village_chief_npc.gd`，村长交互会打开对话面板，同时保留 `first_hunt` 启动和提交逻辑。
- 扩展 `godot/scripts/tests/ui_panels_test.gd`，覆盖青木村村长对话、商人商店和铁匠商店入口。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_sprite_asset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`

待完成：

- 手动运行 Godot GUI 验收 v0.4 UI 布局、重叠、按钮和 tooltip 观感。
- 当前 v0.4 已完成 UI 层、演示数据和正式青木村 NPC 对话/商店入口的 headless 验证。

## 2026-07-02 v0.5 村长 NPC 与 first_hunt 状态

完成：

- 扩展 `godot/scripts/tests/v05_new_player_loop_test.gd`，覆盖 `first_hunt` 初始状态、村长交互接任务、野狼击败计数、黑狼头目击败后可交付、再次交互完成任务。
- 确认主场景包含 `QuestManager`，青木村包含 `Npcs/VillageChiefNpc`。
- 为玩家控制器新增 `interact_requested` 信号，并将 `interact` 输入绑定到该信号。
- 在 `godot/scripts/game/main.gd` 中连接玩家交互请求到当前地图最近 NPC 的 `interact()`。
- 更新 v0.5 计划，标记新手 NPC 与 `first_hunt` 任务状态完成。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`

后续完成：

- 真实野狼/黑狼头目死亡事件已在 2026-07-05 的 v0.5 黑狼林敌人与 Boss 任务推进中接入。
- 保存读取已在 2026-07-05 的 v0.5 保存与读取中完成。
- 完整 10 分钟手动验收仍待完成。

## 2026-07-02 v0.3 掉落、背包与装备实现

完成：

- 完成 `GameData`、`InventoryModel`、`EquipmentModel`、`StatCalculator`、`LootTable` 和 `DroppedItem` 的 v0.3 最小实现。
- 读取 `data/items.json` 与 `data/monsters.json`，并校验怪物掉落引用的 `item_id`。
- 实现金币、可堆叠材料、独立装备条目、武器/防具装备栏和装备替换。
- 实现基础属性加法计算，支持 `attack`、`magic_attack`、`defense`、`max_hp`、`max_mp`、`speed` 和 `crit_rate`。
- 实现怪物掉落表计算、掉落物 payload、掉落物拾取到背包，以及野狼死亡后生成真实掉落物。
- 将现有背包/装备菜单接入最小数据显示，可显示金币、物品条目、装备槽位和基础属性。
- 更新 `TODO.md`、`README.md`、`docs/02_Roadmap.md` 和 `docs/11_DevelopmentPlan.md`，同步 v0.3 已完成状态。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_sprite_asset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`

后续修复：

- `ui_panels_test.gd` 的商店 buy request 覆盖已在 v0.4 UI 实现中修复。
- `v05_new_player_loop_test.gd` 的玩家 `interact_requested` 信号与青木村 NPC 交互入口已在 v0.4/v0.5 后续实现中修复。

待完成：

- 运行 Godot GUI 手动验收掉落拾取、背包显示和装备显示手感。
- 下一步进入 v0.4 UI、NPC 与商店实现。

## 2026-07-02 v0.5 地图切换与数据基础

完成：

- 新增 `godot/scripts/tests/v05_new_player_loop_test.gd`，用 headless 测试覆盖 v0.5 初始地图和青木村到黑狼林切换。
- 新增 `godot/scripts/game/map_manager.gd`，支持 `load_map(map_id, spawn_id)`、当前地图 id、当前出生点 id 和玩家出生点定位。
- 新增 `godot/scenes/maps/greenwood_village.tscn`，包含 `VillageSpawn`、`ToBlackWolfForest` 和 `VillageChief` 预留点。
- 新增 `godot/scenes/maps/black_wolf_forest.tscn`，包含 `ForestEntry`、`ToGreenwoodVillage`、野狼刷新点和黑狼头目刷新点。
- 更新 `godot/scenes/main.tscn` 和 `godot/scripts/game/main.gd`，主场景改为通过 `MapRoot` / `MapManager` 默认加载青木村。
- 更新 `data/maps.json`，补充 v0.5 所需的 `default_spawn`、`spawns` 和 `transitions` 元数据。
- 为已有 v0.3 测试补齐最小数据、背包、装备、属性计算、掉落表和掉落物场景：`game_data.gd`、`inventory_model.gd`、`equipment_model.gd`、`stat_calculator.gd`、`loot_table.gd`、`dropped_item.gd`。
- 更新菜单覆盖层和 HUD，使现有 UI/数据绑定测试恢复通过。

验证记录：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`
- `jq empty data/items.json data/monsters.json data/maps.json`

后续修复：

- `v05_new_player_loop_test.gd` 的玩家 `interact_requested` 信号、村长任务状态、商人/铁匠地图节点和商店入口覆盖已在后续实现中补齐。

后续完成：

- `v05_new_player_loop_test.gd` 已在后续实现中扩展到真实野狼/黑狼头目死亡、保存读取和最小掉落/装备状态。
- v0.5 当前剩余风险集中在 10 分钟 GUI 手动验收和路线手感，而不是 headless 功能缺口。

## 2026-07-02 v0.4 UI、NPC 与商店计划

完成：

- 新增 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.4-ui-npc-shop.md`，作为 v0.4 UI、NPC 与商店的详细实施计划。
- 明确 v0.4 范围：HUD、背包 UI、装备 UI、NPC 对话 UI、商店 UI、UI Root、像素 UI 风格规范和半身立绘预留区域。
- 明确 v0.4 暂不主动实现：战斗、掉落、任务主线、职业技能、地图切换和保存读取。
- 更新 `docs/09_UI.md`，补充 HUD、背包、装备、对话、商店、面板模态规则和数据边界。
- 更新 `docs/11_DevelopmentPlan.md` 和 `TODO.md`，加入 v0.4 计划入口和拆分任务。

待完成：

- 按 v0.4 计划添加 NPC、商店和 UI 演示数据。
- 实现 HUD 更新接口、背包/装备/对话/商店面板和 UI Root。
- 新增并运行 v0.4 headless UI 验证。

## 2026-07-02 v0.2 基础战斗实现

完成：

- 新增 `godot/scripts/combat/health_component.gd`，实现生命值、伤害、防御、治疗和死亡信号。
- 新增 `godot/scripts/combat/hitbox.gd` 与 `godot/scripts/combat/hurtbox.gd`，实现近战攻击判定与受击转发。
- 更新 `godot/scenes/actors/player.tscn` 与 `godot/scripts/actors/player_controller.gd`，为玩家接入生命组件、受击区、攻击区、攻击输入、攻击冷却和命中窗口。
- 新增 `godot/scenes/actors/wild_wolf.tscn` 与 `godot/scripts/actors/wild_wolf_controller.gd`，实现野狼追踪、攻击、受击暂停、死亡和碰撞关闭。
- 新增 `godot/scenes/ui/health_bar.tscn`、`godot/scripts/ui/health_bar.gd` 与 `godot/scripts/combat/damage_number.gd`，实现玩家/怪物血条和基础伤害飘字。
- 更新 `godot/scenes/main.tscn` 与 `godot/scripts/game/main.gd`，在测试地图中放置野狼，绑定玩家 HUD 生命显示，并将野狼目标指向玩家。
- 新增 `godot/scripts/tests/combat_component_test.gd` 和 `godot/scripts/tests/combat_flow_test.gd`，覆盖生命组件、hitbox/hurtbox、玩家攻击、野狼追踪、死亡、血条和伤害数字。
- 更新 `README.md`、`TODO.md` 和 `docs/11_DevelopmentPlan.md`，同步 v0.2 已实现状态。
- 启动 Godot GUI 验收时项目能加载，但当前环境无法可靠截取/观察窗口画面，因此未把 GUI 手感验收标记完成。
- 新增 `godot/scripts/tests/combat_playthrough_test.gd`，作为 GUI 不可观测时的主场景级 headless 验收代理，覆盖 HUD 生命绑定、玩家攻击野狼、野狼攻击玩家和野狼死亡。
- 修正 `godot/scenes/actors/player.tscn` 的玩家 atlas 引用，改回已有导入文件 `swordsman_walk_9dir_v2_atlas.png`。
- 修正 `godot/scripts/ui/menu_overlay.gd` 的类型推断解析错误。
- 更新 `godot/scripts/tests/asset_load_test.gd`，适配当前 `MapManager` 加载 `GreenwoodVillage` 的主场景结构和掉落物场景检查。
- 清理 `godot/scripts/tests/combat_flow_test.gd` 中越界的主场景掉落断言，掉落逻辑留给 v0.3 测试覆盖。
- 修正 `godot/scripts/actors/wild_wolf_controller.gd` 中临时 `GameData`/`LootTable` 节点未释放的问题，消除战斗测试退出时的资源泄漏警告。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_playthrough_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd`

待完成：

- 运行 Godot GUI 手动验收 v0.2 战斗手感。
- 下一步进入 v0.3 掉落、背包与装备实现。

## 2026-07-02 v0.3 掉落、背包与装备计划

完成：

- 新增 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.3.md`，作为 v0.3 掉落、背包与装备的实施计划。
- 明确 v0.3 范围：读取物品和怪物 JSON、校验掉落引用、背包数据结构、装备槽位、基础属性计算、掉落表、掉落物拾取和最小菜单数据显示。
- 明确 v0.3 暂不处理：完整战斗实现、NPC、商店、任务、地图切换、存档、经验、技能栏、随机词缀和完整像素 UI。
- 更新 `docs/06_Items.md`，补充物品字段、堆叠规则、装备槽位、掉落行格式和 v0.3 属性计算规则。
- 更新 `README.md`、`AGENTS.md`、`docs/02_Roadmap.md`、`docs/11_DevelopmentPlan.md` 和 `TODO.md`，加入 v0.3 计划入口和拆分任务。

待完成：

- 先完成或确认 v0.2 基础战斗的死亡事件。
- 按 v0.3 计划实现数据读取、背包、装备、属性、掉落和测试。
- 若 v0.2 死亡事件尚未实现，v0.3 先用独立测试验证掉落算法和拾取数据结构。

## 2026-07-02 v0.5 新手流程计划

完成：

- 新增 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`，作为 v0.5 新手流程的详细实施计划。
- 明确 v0.5 范围：青木村、黑狼林、地图切换、新手 NPC、`first_hunt`、黑狼头目、最小掉落装备和保存读取。
- 明确 v0.5 不主动扩展：完整任务编辑器、完整商店、完整背包装备 UI、职业技能和大规模美术生产。
- 更新 `docs/01_GDD.md`，细化 MVP 玩家流程和 v0.5 验收标准。
- 更新 `docs/08_Maps.md`，补充青木村与黑狼林第一版灰盒布局、地图切换规则。
- 更新 `docs/10_SaveSystem.md`，补充 v0.5 存档字段、任务状态和读取失败策略。
- 更新 `docs/11_DevelopmentPlan.md`、`TODO.md` 和 `README.md`，同步 v0.5 计划状态。

待完成：

- 等用户确认后，再进入 v0.5 Godot 实现。
- 实施时先做地图切换和任务状态，再接入战斗、掉落装备和保存读取。

## 2026-07-02 v0.2 计划补强

完成：

- 复核 `docs/superpowers/plans/2026-06-29-pixeldragoncity-v0.2.md`，确认 v0.2 仍处于计划已完成、功能未实现状态。
- 在 v0.2 计划末尾新增执行补强章节，明确攻击输入建议、开发 gate 顺序、文档更新矩阵、验证命令和实现风险。
- 未开始修改 Godot 战斗功能代码。

待完成：

- 按 v0.2 计划从生命值组件和 headless 测试开始实施。

## 2026-06-29 v0.2 基础战斗计划

完成：

- 新增 `docs/superpowers/plans/2026-06-29-pixeldragoncity-v0.2.md`，作为 v0.2 基础战斗的实施计划。
- 明确 v0.2 范围：生命值、受击判定、近战攻击、野狼追踪、攻击、死亡、血条和伤害反馈。
- 明确 v0.2 暂不处理：真实掉落、背包、装备属性计算、经验、技能栏、NPC、地图切换和存档。
- 更新 `README.md`，修正“Godot 工程尚未创建”的过期状态。
- 更新 `AGENTS.md`、`docs/02_Roadmap.md`、`docs/11_DevelopmentPlan.md` 和 `TODO.md`，将当前主线切换到 v0.2 基础战斗。

待完成：

- 按 v0.2 计划开始实现战斗组件与测试。
- 完成后追加 v0.2 实现记录和验证命令。

## 2026-06-28

完成：

- 建立项目文档结构。
- 创建 README、AGENTS、TODO 和 CHANGELOG。
- 整理 v0.1 GDD、世界观、职业、战斗、物品、怪物、地图、UI、存档设计。
- 创建 prompts 和 data 初稿。
- 创建第一版开发计划。
- 确认基础画面方向：原创像素美术、经典 2D 斜俯视 ARPG 语法、像素 HUD 和像素半身立绘用途。
- 新增 `docs/11_DevelopmentPlan.md`，整理版本计划、当前进度、主要系统拆分和近期优先级。
- 扩展 `TODO.md`，加入人物立绘、地图美术、UI/HUD、tileset 和内容扩展任务。

待完成：

- 开始 v0.2 基础战斗。
- 创建生命值组件、受击判定和近战攻击判定。
- 创建野狼怪物和基础伤害反馈。

## 2026-06-28 v0.1 可移动原型

完成：

- 创建 Godot 4 工程 `godot/project.godot`。
- 创建主场景 `godot/scenes/main.tscn`。
- 创建玩家场景 `godot/scenes/actors/player.tscn`。
- 实现 WASD 八方向移动。
- 实现基础动画状态记录：idle/walk 和上下左右朝向。
- 实现 Camera2D 跟随，使用 2x 缩放验证角色比例。
- 创建测试地图 `godot/scenes/maps/test_map.tscn`。
- 创建地图边界碰撞。
- 创建临时像素风玩家占位剪影和斜俯视测试地图块面。
- 根据实机验证反馈，将 Camera2D 缩放调整为 1.75x，并将玩家视觉缩放调整为 0.82x，让角色更小并显示更多地图背景。
- 根据实机验证反馈，将默认视口从 1280x720 调整为 1600x900，保持 16:9 并扩大整体画面长宽。
- 生成并保存第一版美术方向参考图：人物立绘、场景、UI、装备图标和怪物立绘。
- 确认 `assets/references/ui_direction_primary_v1.png` 作为第一版 UI 主参考。
- 新增 `docs/12_ArtDirection.md`，记录当前美术方向和后续制作口径。
- 生成第一批 Godot 可引用美术资源：玩家 sprite sheet、怪物 sprite sheet、道具图标 sheet、场景 tileset、UI atlas。
- 将处理后的资源复制到 `godot/assets/`，用于 `res://assets/...` 引用。
- 新增 `assets/ASSET_MANIFEST.md`，记录资源路径和使用注意。
- 运行 Godot 导入流程，为新 PNG 资源生成 `.png.import` 配置。
- 新增 `godot/scripts/tests/asset_load_test.gd`，验证新资源可通过 `ResourceLoader.load()` 加载为 `Texture2D`。
- 将玩家场景从多边形占位外观切换为生成的剑士 sprite sheet 第一帧预览。
- 新增 `godot/scenes/ui/art_preview.tscn`，在主场景右上角展示玩家、怪物、道具、tileset 和 UI atlas 预览。
- 将测试地图接入 `environment_tileset_v1.png`，显示生成的草地、道路、森林、木屋、矿洞和矿石视觉块。
- 将 HUD 接入 `ui_atlas.png` 作为风格底图，并显示角色立绘参考图。
- 根据实机反馈，移除错位的 tileset 裁切拼贴，改用统一测试地图背景 `test_map_background_v1.png`。
- 新增 `godot/scenes/ui/menu_overlay.tscn`，显示背包、装备、物品图标和角色立绘预览。
- 新增玩家九方向资源 `player_swordsman_9dir_sheet.png`，玩家场景根据移动方向裁切九宫格方向图。
- 将背包和装备菜单改为默认隐藏，通过 HUD 上的 Bag 和 Equip 按钮打开，并可用 X 按钮关闭。
- 生成剑士 v1 设计预览图 `assets/references/swordsman_design_preview_v1.png`，确认“边境佣兵 + 少量流浪剑客”的默认主角方向。
- 生成剑士 8 方向行走动画源图 `assets/sprites/swordsman/swordsman_walk_8dir_v1.png`。
- 新增 `docs/art/swordsman_sprite_animation_spec.md`，定义剑士地图 sprite、方向、帧数、sheet 排布和验收标准。
- 生成透明背景测试图 `swordsman_walk_8dir_test.png` 和规则测试 atlas `swordsman_walk_8dir_test_atlas.png`。
- 将玩家实体替换为剑士行走测试 atlas，按移动方向选择行、按 walk/run 节奏播放帧；左向暂用右向水平翻转。
- 修正剑士测试 atlas 的左右翻转方向；背面行走帧变化较弱，暂用帧偏移强化实机测试中的走路反馈。
- 根据实机反馈，将左右移动映射到测试 atlas 中动作幅度更明显的侧向行，并加大向上移动的背面步伐偏移。
- 根据 Godot 实机观察再次修正测试 atlas 左右翻转：当前临时资源右向不翻转、左向翻转。
- 重新生成剑士 v2 行走源图 `swordsman_walk_9dir_v2_source.png`，裁切为严格 `4x9` atlas `swordsman_walk_9dir_v2_atlas.png`。
- 将玩家实体切换到剑士 v2 atlas，并取消旧测试 atlas 的水平翻转和背面偏移补偿。
- 新增 `tools/build_swordsman_walk_v2_atlas.py`，按透明主体自动识别、去绿幕、重排为 Godot 可裁切 atlas。
- 根据实机反馈，停止继续调 AI walk sheet；新增脚本绘制的 `swordsman_walk_blockout_v1_atlas.png` 作为确定性动作基底，优先验证左右朝向和步行动作。
- 将玩家实体切换到 blockout atlas，当前美术精度让位于动作可读性。
- 新增美术处理脚本 `tools/make_dark_background_transparent.py` 与 `tools/build_swordsman_walk_test_atlas.py`，用于从 AI 源图生成可测试 atlas。
- 添加底部最小 HUD，占位显示生命、魔法、快捷栏、等级、经验和金币。
- 添加鼠标移动：左键点击走路，右键点击跑步。
- 添加鼠标长按连续移动：长按左键持续走向鼠标方向，长按右键持续跑向鼠标方向。
- 添加临时移动动画反馈：占位角色移动时上下轻微起伏，左右移动时翻转方向。
- 添加 headless 行为测试 `godot/scripts/tests/player_input_and_ui_test.gd`。
- 生成剑士单人半身立绘 `assets/portraits/swordsman_portrait_v1.png`，并接入 HUD、装备面板、对话面板和菜单 overlay 的人物立绘引用。

验证：

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit`
- 输出包含 `Pixel Dragon City v0.1 prototype loaded`。
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd`
- 输出包含 `player_input_and_ui_test: PASS`。

待完成：

- v0.2 基础战斗。
- 怪物生命值、追踪 AI、受击和死亡。
- 玩家和怪物血条。
