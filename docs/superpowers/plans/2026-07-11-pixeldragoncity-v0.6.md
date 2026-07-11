# v0.6 职业雏形 · 剑士技能系统实施计划

创建日期：2026-07-11

## 目标

在现有战斗基础上引入数据驱动的技能系统，先落地剑士两个技能（普通斩击、重斩），
绑定到 HUD 快捷栏，支持冷却、MP 消耗与伤害倍率，为后续法师/灵术师职业扩展打基础。

## 范围（本期）

- 只做剑士近战技能与通用技能框架；法师火球（projectile）仅保留数据，暂不实现投射物。
- 快捷栏先用键 1 / 2 触发技能槽 0 / 1；普通攻击键（空格 / J）复用技能槽 0（普通斩击）。

## 数据契约

`data/skills.json` 每条：`id`、`name`、`class`、`level`、`type`、`icon_index`、
`multiplier`（伤害倍率）、`cooldown`（秒）、`mp_cost`。

## 任务

- [x] `GameData` 读取 `skills.json`，提供 `get_skill` / `get_skills_for_class`。
- [x] 玩家新增 MP 资源（`max_mp`、`current_mp`、`mp_regen`、`mana_changed` 信号）。
- [x] 玩家技能系统 `use_skill`：按技能冷却、MP、`multiplier` 结算伤害并触发攻击判定。
- [x] 输入映射新增 `skill_slot_1` / `skill_slot_2`（键 1 / 2）。
- [x] 生成剑士技能像素图标 `ui/skill_icons_sheet.png`。
- [x] HUD 快捷栏显示技能图标、键位数字与冷却遮罩；接入真实 MP 显示。
- [x] `main.gd` 装配剑士技能栏、连接 MP 与冷却刷新。
- [x] headless 技能系统测试 `v07_skill_system_test.gd`。

## 验收标准

- 快捷栏 1、2 槽显示普通斩击 / 重斩图标和键位。
- 普通斩击 0 MP、倍率 1.0；重斩消耗 5 MP、倍率 1.8、冷却更长。
- MP 不足或冷却中时技能不触发，MP 会随时间回复。
- 技能伤害随装备后的攻击力缩放。

## 验证

- `Godot --headless --path godot --script res://scripts/tests/v07_skill_system_test.gd` → `PASS`。
- 全量 headless 测试 14/15 `PASS`（仅 `visual_snapshot_test` 需真实渲染器）。
- 实机截图：HUD 显示 MP 40/40 与 1/2 技能图标。

## 后续（v0.6 剩余）

- 法师火球投射物、灵术师技能雏形。
- 三职业地图 sprite 与像素半身立绘方向。
- 技能命中飘字 / 命中反馈强化。
