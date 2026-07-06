# AGENTS.md

本文件是《像素龙城》的 AI 协作入口。任何 AI、Codex、脚本代理或开发者在修改项目之前都必须先阅读本文件。

## 项目定位

《像素龙城》是一款 Godot 4 2D 像素风 ARPG。目标不是复刻任何现有商业游戏，而是吸收经典 2D RPG 的清晰反馈、刷怪成长、装备掉落和地图探索乐趣，制作原创世界观、原创素材和可持续扩展的单机游戏。

## Godot 版本

- 使用 Godot 4.x。
- 默认使用 GDScript。
- 新代码应尽量保持模块化，避免把所有逻辑写进一个巨大脚本。

## 命名规范

- 场景文件：`snake_case.tscn`
- 脚本文件：`snake_case.gd`
- 节点名：使用清晰 PascalCase，例如 `Player`, `HealthBar`, `Hitbox`
- 资源目录：小写复数，例如 `sprites/`, `tilesets/`
- JSON id：使用稳定字符串 id，例如 `iron_sword`, `wild_wolf`

## 代码规范

- 优先写简单、可读、可测试的 GDScript。
- 每个脚本承担一个主要职责。
- 玩家、怪物、物品、技能等核心系统要尽量通过配置数据驱动。
- 避免在 UI、战斗、移动之间制造循环依赖。
- 只有复杂逻辑需要注释；注释解释设计意图，不复述代码。

## 文件组织

建议 Godot 工程内部逐步采用：

```text
godot/
  scenes/
    actors/
    maps/
    ui/
  scripts/
    actors/
    combat/
    data/
    inventory/
    ui/
  resources/
```

根目录的 `data/` 是设计数据源。Godot 内可以复制、导入或读取这些 JSON，但不要让运行时代码依赖聊天记录里的隐含设定。

## 当前 Roadmap

1. v0.1：项目骨架、玩家移动、相机、测试地图。
2. v0.2：怪物、血量、受击、近战攻击、死亡。
3. v0.3：掉落、背包、装备、基础数值。
4. v0.4：UI、NPC 对话和商店。
5. v0.5：第一条完整新手流程。

## 当前开发任务

详见：

- `TODO.md`
- `docs/02_Roadmap.md`
- `docs/superpowers/plans/2026-06-28-pixeldragoncity-v0.1.md`
- `docs/superpowers/plans/2026-06-29-pixeldragoncity-v0.2.md`
- `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.3.md`
- `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.4-ui-npc-shop.md`
- `docs/superpowers/plans/2026-07-02-pixeldragoncity-v0.5.md`

## 禁止事项

- 不直接复制《传奇2》或其他商业游戏素材、音频、地图、UI、代码和具体文本。
- 不把项目设计绑定到单一聊天记录中；重要决定必须写入 `docs/`。
- 不在没有说明的情况下大规模改目录结构。
- 不提交生成缓存、临时导出、系统文件或大型二进制草稿。

## AI 工作方式

当用户提出新功能时：

1. 先检查现有文档和代码。
2. 若需求会影响玩法、架构或数据结构，先更新对应文档。
3. 再修改 Godot 工程或数据。
4. 完成后更新 `TODO.md` 或 `docs/DevLog.md`。
5. 报告改了什么、如何验证、还有哪些风险。
