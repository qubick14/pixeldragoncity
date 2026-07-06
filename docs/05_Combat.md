# 05 Combat

## 战斗目标

战斗要清楚、直接、容易调数值。玩家应能通过走位、攻击时机和装备成长明显感到变强。

## 基础属性

- `max_hp`：最大生命
- `max_mp`：最大魔法
- `attack`：物理攻击
- `magic_attack`：魔法攻击
- `defense`：物理防御
- `speed`：移动速度
- `crit_rate`：暴击率
- `crit_damage`：暴击伤害倍率

## 伤害公式 v0.2

```text
base_damage = max(1, attacker.attack - defender.defense)
skill_damage = base_damage * skill.multiplier
critical_damage = skill_damage * attacker.crit_damage if critical else skill_damage
final_damage = round(critical_damage)
```

Godot v0.2 原型当前采用最小可验证公式，先不接入暴击、技能倍率和装备修正：

```text
final_damage = max(1, attacker.attack - defender.defense)
```

## 命中与闪避

MVP 阶段不做随机命中。攻击范围碰撞到目标即命中。

## 攻击节奏

- 普通攻击有前摇、命中帧、后摇。
- v0.1 可先用简单冷却代替完整动作帧。
- 后续动画完成后再绑定实际命中帧。
- v0.2 玩家普通攻击使用 `attack_primary` 输入，默认键位为 `J` 和 `Space`。
- v0.2 玩家普通攻击冷却为 0.55 秒，命中窗口为 0.12 秒，攻击范围跟随玩家朝向。

## v0.2 Godot 实现

- `HealthComponent`：维护 `max_hp`、`current_hp`、`defense`，提供 `setup()`、`apply_damage()`、`heal()` 和 `is_dead()`。
- `Hitbox`：维护攻击方、攻击力和启用状态。
- `Hurtbox`：接收 `Hitbox`，过滤禁用 hitbox 和同一 actor 自伤，再把伤害转发给 `HealthComponent`。
- 玩家和野狼都通过 `HealthComponent`、`Hitbox`、`Hurtbox` 组合实现战斗，移动、AI 和 UI 不直接负责伤害计算。

## 怪物 AI

v0.2 采用简单状态机：

- Idle：待机
- Chase：发现玩家并追踪
- Attack：进入攻击距离后攻击
- Hurt：受击短暂停顿
- Dead：死亡并触发掉落

## 受击反馈

最低要求：

- 数字飘字
- 怪物短暂停顿
- 血条变化
- 死亡动画或消失效果
