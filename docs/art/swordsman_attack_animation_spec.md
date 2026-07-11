# Swordsman Attack Animation Spec

## 目标

本文件定义剑士普通攻击动作验证资源。第一版重点是确认方向、挥剑轨迹、命中帧和脚底稳定，不代表最终像素精度。

## 资源

- 源资源：`assets/sprites/swordsman/swordsman_attack_blockout_v1_atlas.png`
- Godot 路径：`res://assets/sprites/swordsman/swordsman_attack_blockout_v1_atlas.png`
- 生成脚本：`tools/build_swordsman_attack_blockout_atlas.py`
- 状态：`blockout`

## 网格

- cell：`192x192`
- columns：6 帧
- rows：8 个攻击方向 + 1 个正面参考行
- atlas：`1152x1728`
- 背景：RGBA 透明
- 脚底：沿用行走 blockout 的脚底中心

行顺序：

1. `down`
2. `down_left`
3. `left`
4. `up_left`
5. `up`
6. `up_right`
7. `right`
8. `down_right`
9. `idle_front`

## 帧节奏

| 帧 | 阶段 | 建议时长 | 用途 |
| --- | --- | --- | --- |
| 0 | 预备 | 70 ms | 保持朝向，建立攻击起点。 |
| 1 | 蓄力 | 80 ms | 剑向后收，准备挥击。 |
| 2 | 起挥 | 60 ms | 开始前移，可进入攻击前摇末段。 |
| 3 | 命中 | 70 ms | 最大前探，建议开启主要伤害判定。 |
| 4 | 随挥 | 80 ms | 保留挥剑轨迹，可结束伤害判定。 |
| 5 | 收势 | 110 ms | 返回移动或待机状态。 |

总时长建议约 `470 ms`，应与当前 `0.55 s` 攻击冷却保持可读间隔。

## 接入边界

本批只产出和验证 atlas，不修改玩家控制器与场景。正式接入时需要：

1. 按玩家最后朝向选择攻击行。
2. 攻击期间锁定或降低移动速度。
3. 让第 3 帧与 `AttackHitbox` 的主要有效窗口对齐。
4. 接入后替换或隐藏当前程序绘制的 `AttackSlash`，避免双重挥剑效果。
5. GUI 试玩确认八方向剑尖范围与实际碰撞范围一致。

## 验收标准

- 六帧轮廓能读出预备、挥出、命中和收势。
- 八方向挥剑朝向与角色面向一致。
- 每格尺寸固定，脚底不会因帧切换明显漂移。
- 命中帧的剑尖范围明显大于预备帧。
- 接入前保持 `blockout`，不得标记为 `production_ready`。
