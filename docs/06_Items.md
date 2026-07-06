# 06 Items

## 物品类型

- 武器
- 防具
- 饰品
- 消耗品
- 材料
- 任务物品

## 装备品质

| 品质 | 颜色 | 说明 |
| --- | --- | --- |
| common | 白 | 普通装备 |
| uncommon | 绿 | 略强，有少量属性 |
| rare | 蓝 | 明显提升 |
| epic | 紫 | 稀有词条 |
| legendary | 橙 | Boss 或高级内容掉落 |
| mythic | 红 | 长期目标，MVP 不做 |

## 初始装备

- 木剑
- 铁剑
- 布衣
- 皮甲
- 草药
- 小型生命药水

## 掉落原则

- 普通怪主要掉落金币、材料和低级装备。
- Boss 必定掉落关键奖励。
- MVP 阶段先保证掉落简单可调，不做复杂随机词缀。
- v0.3 掉落配置来自 `data/monsters.json` 的 `drops` 字段。
- 掉落行格式为 `{ "item_id": "wolf_pelt", "chance": 0.6, "min": 1, "max": 2 }`。
- `chance` 表示 0 到 1 的概率；`min` 和 `max` 为包含边界的数量范围。
- `item_id` 必须存在于 `data/items.json`，实现时应有校验测试。
- 怪物 `gold` 作为独立金币掉落处理，不写入 `items.json`。

## 装备属性

装备可提供：

- attack
- magic_attack
- defense
- max_hp
- max_mp
- speed
- crit_rate

## v0.3 物品数据契约

`data/items.json` 是 v0.3 物品运行时读取的设计源。当前必需字段：

- `id`：稳定唯一字符串，例如 `iron_sword`。
- `name`：中文显示名。
- `type`：物品类型，例如 `weapon`、`armor`、`consumable`、`material`。
- `quality`：品质，例如 `common`、`uncommon`。
- `level`：物品等级。
- `price`：基础价格。

可选字段：

- `stats`：装备属性字典。
- `effect`：消耗品效果字典。
- `slot`：装备槽位；v0.3 只启用 `weapon` 和 `armor`。
- `stackable`：是否可堆叠。
- `max_stack`：最大堆叠数量。
- `icon_region`：道具图标在占位图集中的区域，格式可使用 `[x, y, width, height]`。

默认规则：

- `weapon` 默认装备槽位为 `weapon`，不可堆叠，最大数量 1。
- `armor` 默认装备槽位为 `armor`，不可堆叠，最大数量 1。
- `material` 默认可堆叠，最大数量 99。
- `consumable` 默认可堆叠，最大数量 99。
- 未配置 `icon_region` 时，UI 可先显示文本或使用 `godot/assets/items/item_icons_sheet.png` 的占位区域。

## v0.3 背包与装备规则

- 背包保存金币和物品条目。
- 材料和消耗品按 `item_id` 合并堆叠。
- 武器和防具按独立条目保存，避免未来词条、耐久或强化信息无法区分。
- v0.3 装备栏只做 `weapon` 和 `armor`。
- 装备新武器或防具时，旧装备回到背包。
- 非装备物品不能放入装备栏。

## v0.3 属性计算

v0.3 使用直接加法：

```text
最终属性 = 玩家基础属性 + 所有已装备物品的 stats
```

建议测试用玩家基础属性：

```text
attack: 1
magic_attack: 0
defense: 0
max_hp: 100
max_mp: 30
speed: 140
crit_rate: 0.0
```

例子：

- 装备 `iron_sword` 后，`attack` 从 1 变为 6。
- 装备 `leather_armor` 后，`defense` 从 0 变为 3，`max_hp` 从 100 变为 115。

v0.3 不做随机词缀、耐久、等级需求、职业需求、暴击伤害、临时 buff 或套装效果。
