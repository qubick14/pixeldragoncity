# Swordsman Walk Cycle Audit 2026-07-06

本文件记录剑士 `blockout` 与 v2 atlas 的完整步行动作帧审计。它用于判断当前玩家行走动画是否足以继续作为动作验证资源。

## 生成命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/swordsman_walk_audit_image.gd
```

输出：

```text
swordsman_walk_audit_image: PASS /tmp/pixeldragoncity_swordsman_walk_audit.png 1192x1296
```

审计图：

```text
/tmp/pixeldragoncity_swordsman_walk_audit.png
```

## 审计对象

左侧：

- `assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png`
- 状态：`blockout`
- 规格：`4x9`，每格 `192x192`

右侧：

- `assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png`
- 状态：`production_candidate`
- 规格：`4x9`，每格 `192x192`

## 结论

### blockout atlas

优点：

- 四帧之间腿部位置变化明显。
- 左右、上下、斜向行的身体朝向和武器位置可读。
- 披肩与剑的位置能帮助玩家判断方向。
- 适合继续作为当前玩家动作验证资源。

限制：

- 美术精度低，不应作为最终角色资源。
- 角色形体偏粗略，不能体现最终剑士的装备细节。
- 只能证明动作节奏和方向读得出来，不代表最终画面品质。

### v2 atlas

优点：

- 角色造型、盔甲、披肩和武器质量明显更接近最终方向。
- 轮廓和职业识别强。
- 适合作为后续正式重绘的外观参考。

限制：

- 多数方向的四帧步态变化偏弱。
- 实机移动时可能仍有滑行感。
- 暂不建议直接替换 `blockout` 作为当前玩家动作资源。

## 决策

当前玩家继续使用 `swordsman_walk_blockout_v1_atlas.png`。

下一版正式剑士动画建议以 v2 的外观为目标，以 blockout 的腿部交替幅度和方向可读性为动作基准重绘。

## 后续任务

- 制作剑士普通攻击 atlas 时，应沿用 blockout 的方向行顺序和脚底对齐规则。
- 后续若重绘正式 walk atlas，必须保留明显的左右腿交替、披肩摆动和脚底中心稳定。
- 正式替换前，再生成同类审计图并运行 GUI 快照验证。
