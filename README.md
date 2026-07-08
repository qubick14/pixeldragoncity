# 像素龙城

《像素龙城》是一款使用 Godot 4 开发的 2D 像素风动作角色扮演游戏。项目目标是先做出一个可试玩、可扩展、配置数据驱动的单机 MVP，再逐步扩展职业、地图、装备、怪物、任务和 Boss 内容。

## 当前阶段

版本：v0.5 新手流程 headless 闭环完成，待 10 分钟 GUI 验收

当前状态：

- v0.1 可移动原型已完成：Godot 工程、主场景、测试地图、玩家移动、相机、最小 HUD 和菜单覆盖层已经存在。
- v0.2 基础战斗原型已完成 headless 验证：生命值、受击判定、近战攻击、野狼追踪、死亡、血条和伤害反馈已接入。
- v0.3 掉落、背包与装备已完成 headless 验证：JSON 数据读取、掉落表、掉落物、背包、装备、基础属性计算和最小菜单数据显示已接入。
- v0.4 UI、NPC 与商店已完成原型：HUD 更新接口、背包/装备/对话/商店面板、UI Root、NPC/商店演示数据、UI 风格规范和青木村村长/商人/铁匠交互入口已接入，并通过 Godot 正常渲染截图验收基础布局。
- v0.5 新手流程已完成 headless 闭环：青木村/黑狼林、地图切换、`first_hunt`、黑狼头目、最小掉落/背包/装备、保存读取和占位 TileSet 层已接入。
- 当前下一步是手动验收 v0.5 10 分钟流程，或继续精修 v0.4 物品图标切片和像素 UI 美术。
- v0.2 实施计划见 `docs/superpowers/plans/2026-06-29-pixeldragoncity-v0.2.md`。
- v0.3 掉落、背包与装备实施计划见 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.3.md`。
- v0.4 UI、NPC 与商店实施计划见 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.4-ui-npc-shop.md`。
- v0.5 实施计划见 `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`。
- `data/` 仍作为设计数据源，后续掉落、装备、怪物和技能逻辑应继续向 JSON 数据驱动演进。

## 技术栈

- 引擎：Godot 4.x
- 语言：GDScript
- 资源风格：原创像素美术
- 数据格式：JSON
- 目标平台：先以桌面端原型为主，后续评估 Web 或移动端

## 目录说明

- `docs/`：游戏设计文档、世界观、系统设计和开发日志
- `prompts/`：用于 AI 协作的代码、美术、设计和测试提示词
- `godot/`：Godot 工程目录
- `assets/`：精灵、地图图块、UI、音频和字体资源
- `data/`：物品、怪物、技能、地图等配置数据
- `tools/`：后续辅助脚本

## 如何运行

1. 安装 Godot 4.x。
2. 打开 `godot/project.godot`。
3. 运行主场景 `res://scenes/main.tscn`。

也可以用 headless 命令做基础验证：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/player_input_and_ui_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_data_load_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/ui_panels_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_component_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/combat_flow_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v0_3_inventory_and_loot_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/v05_new_player_loop_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/asset_load_test.gd
```

## 协作入口

任何 AI 或开发者开始工作前，先阅读：

1. `AGENTS.md`
2. `docs/00_Project.md`
3. `docs/01_GDD.md`
4. `docs/02_Roadmap.md`
5. `docs/superpowers/plans/2026-06-28-pixeldragoncity-v0.1.md`
6. `docs/superpowers/plans/2026-06-29-pixeldragoncity-v0.2.md`
7. `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.3.md`
8. `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.4-ui-npc-shop.md`
9. `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`
