# Swordsman Sprite Animation Spec

## 目标

剑士是《像素龙城》的默认玩家角色。地图 sprite 需要解决当前“人物漂移”的问题，让玩家移动时有明确腿部动作、披肩摆动和方向变化。

## 当前参考资源

- 角色设计预览：`assets/references/swordsman_design_preview_v1.png`
- 当前九方向静态图：`assets/sprites/player_swordsman_9dir_sheet.png`
- 行走动画源图：`assets/sprites/swordsman/swordsman_walk_8dir_v1.png`
- Godot 可引用动画源图：`res://assets/sprites/swordsman/swordsman_walk_8dir_v1.png`
- 当前接入测试 atlas：`res://assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png`
- 当前动作验证 atlas：`res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png`

`swordsman_walk_8dir_v1.png` 是第一版动画源图，不是最终严格网格切图。后续需要按本规格裁切或重绘。
`swordsman_walk_9dir_v2_atlas.png` 是重新生成并裁切后的第二版，当前用于 Godot 实机测试。
`swordsman_walk_blockout_v1_atlas.png` 是脚本绘制的动作验证资源，当前玩家实体使用它来优先确认方向和步行动作。

## 角色视觉要求

- 气质：边境佣兵 + 少量流浪剑客。
- 识别元素：暗红围巾或短披肩、铁肩甲、皮革胸甲、旅行腰包、单手宽剑。
- 比例：非 Q 版，地图中偏小但轮廓清楚。
- 尺寸目标：每帧建议 `96x96`，角色主体高度约 `58-70px`。
- 锚点：脚底中心为角色逻辑位置。
- 碰撞：碰撞框不随 sprite 变化，继续使用脚底区域。

## 方向

正式行走动画使用 8 个移动方向 + 1 个 idle/front 参考：

| 方向 id | 说明 |
| --- | --- |
| `down` | 正下 |
| `down_right` | 右下 |
| `right` | 正右 |
| `up_right` | 右上 |
| `up` | 正上 |
| `up_left` | 左上 |
| `left` | 正左 |
| `down_left` | 左下 |
| `idle_front` | 正面待机参考 |

当前 Godot 控制器用九宫格方向逻辑：

```text
up_left    up    up_right
left       idle  right
down_left  down  down_right
```

## 行走帧

每个移动方向至少 4 帧：

| 帧 | 姿态 |
| --- | --- |
| 0 | 重心居中，准备迈步 |
| 1 | 左腿前 / 右腿后，披肩轻微反向摆动 |
| 2 | 重心回中，身体略微下沉 |
| 3 | 右腿前 / 左腿后，披肩反向摆动 |

播放建议：

- walk：8 到 10 FPS。
- run：12 到 14 FPS，短期可复用 walk 帧。
- idle：1 到 2 帧轻微呼吸即可，后续再做。

## Sheet 排布建议

正式 sheet 建议使用严格网格：

```text
cell: 96x96
columns: 4 frames
rows: 8 directions + 1 idle row
image: 384x864
```

推荐行顺序：

1. `down`
2. `down_right`
3. `right`
4. `up_right`
5. `up`
6. `up_left`
7. `left`
8. `down_left`
9. `idle_front`

每个 cell 中角色脚底中心对齐到 `(48, 78)` 附近，避免动画播放时人物上下左右乱跳。

## 后续接入

当前 `player_controller.gd` 已经有方向 cell 选择逻辑。正式动画接入时：

1. 把 `Sprite2D` 改为 `AnimatedSprite2D` 或通过 `Sprite2D.region_rect` 按帧更新。
2. 根据 `get_animation_key()` 选择方向。
3. 根据 `animation_state` 和移动速度选择 walk/run/idle。
4. 保持 `CollisionShape2D` 不变，避免动画影响碰撞。

## 验收标准

- 按 WASD 或鼠标移动时，腿部有清楚交替动作。
- 披肩或围巾有轻微摆动，强化方向感。
- 八个移动方向的身体朝向明显不同。
- 停止移动时回到 idle/front 或最后方向 idle。
- 人物不再像平移贴图一样漂移。
