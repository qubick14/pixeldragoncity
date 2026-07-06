# 10 Save System

## 存档目标

MVP 存档只保存玩家继续游玩所需信息，不保存所有世界状态。

## 存档内容

- 玩家位置
- 当前地图 id
- 当前出生点或回退出生点 id
- 等级和经验
- 当前生命和魔法
- 金币
- 背包
- 装备
- 已完成任务
- 进行中任务

## 文件格式

使用 JSON 存档，便于调试。

示例：

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
  "inventory": [],
  "equipment": {},
  "quests": {}
}
```

## 读取策略

- 如果没有存档，创建新角色。
- 如果存档版本不匹配，先提示并保留旧文件。
- 读取失败时不要崩溃，回到主菜单或新游戏。

## v0.1 取舍

v0.1 不实现完整存档，只预留数据结构。v0.5 前完成保存与读取。

## v0.5 存档范围

v0.5 存档只保证新手流程可以继续，不保存所有世界状态。

必须保存：

- `player.map_id`
- `player.spawn_id`
- `player.position`
- `player.level`
- `player.exp`
- `player.current_hp`
- `player.current_mp`
- `player.gold`
- `inventory`
- `equipment.weapon`
- `equipment.armor`
- `quests.first_hunt.state`
- `quests.first_hunt.wild_wolf_defeated`
- `quests.first_hunt.black_wolf_leader_defeated`

`first_hunt` 的任务状态只使用：

- `not_started`
- `active`
- `ready_to_turn_in`
- `completed`

读取失败策略：

- 没有存档：创建新角色并出生在 `greenwood_village` / `village_spawn`。
- 存档版本不匹配：保留旧文件，不覆盖，回到新游戏入口或提示错误。
- 地图 id 无效：回退到 `greenwood_village` / `village_spawn`，并保留背包、装备和任务数据。
