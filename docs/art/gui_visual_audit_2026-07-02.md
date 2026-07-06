# GUI Visual Audit 2026-07-02

本文件记录一次 Godot 非 headless 视口截图审计。它用于判断当前玩家、HUD、调试资源预览和地图灰盒在真实渲染窗口里的可读性。

## 验证命令

先尝试 headless 快照：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/tests/visual_snapshot_test.gd
```

结论：headless 使用 dummy renderer，无法取得 viewport texture，脚本会明确报错退出。这不是资源失败，而是 headless 渲染后端限制。

随后使用非 headless Godot 运行同一脚本：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://scripts/tests/visual_snapshot_test.gd
```

结果：

```text
visual_snapshot_test: PASS /tmp/pixeldragoncity_visual_snapshot.png
```

截图路径：

```text
/tmp/pixeldragoncity_visual_snapshot.png
```

## 画面结论

### 玩家与地图比例

- 剑士 blockout 在当前相机和窗口尺寸下可读。
- 玩家主体没有过大，周围地图视野充足。
- blockout 的披肩、剑、身体朝向能看出角色识别点。
- 这次截图只验证静态比例，不验证完整步行动作；步行动作仍需人工移动试玩。

### HUD

- 底部 HUD 风格方向成立，红蓝条、快捷栏、背包和装备按钮能读。
- 左侧 HP/MP 数字清楚。
- 右侧 `Lv.1 EXP 0% Gold 128` 与按钮区域过近，并且在 1600x900 截图中出现挤压和右侧裁切风险。
- Bag / Equip 文本按钮可用，但后续更适合改成图标按钮或更宽固定区域。

### ArtPreview

- 右上角 `Art Preview` 能确认资源已加载。
- 但它占用正常游戏画面，并与地图内容竞争注意力。
- 建议后续只在 debug 模式显示，或改为按键切换，不应作为默认实机画面常驻。

### 地图与场景

- 当前截图是灰盒/原型地图观感，绿色地面和棕色道路能验证通行区域，但不是最终地图美术。
- 画面顶部的棕色矩形和右侧局部文字/预览遮挡说明当前仍是调试构图，不适合作为最终新手村或黑狼林观感。
- 正式 v0.5 仍需要黑狼林与青木村第一版 `32x32` tileset。

## 审计结论

可以标记完成：

- 现有资源 GUI 观感审计。
- 剑士 blockout atlas 静态比例审计。

不能标记完成：

- 剑士 blockout atlas 完整步行动作 GUI 手感确认。
- UI 最终布局验收。
- 正式地图美术验收。

## 建议修正任务

1. 为 `visual_snapshot_test.gd` 保留非 headless 用途，并在文档中说明 headless 不能截图。
2. 调整 HUD 右侧状态文本区域，避免等级、经验和金币与菜单按钮重叠。
3. 将 `ArtPreview` 改为 debug-only 或默认隐藏。
4. 对比 `swordsman_walk_blockout_v1_atlas.png` 和 `swordsman_walk_9dir_v2_atlas.png` 的实际移动效果，再决定是否切换外观候选。
5. 继续制作黑狼林第一版 tileset，替代当前灰盒/原型大色块地图。

## 修正记录

2026-07-02 后续修正：

- `HUD/BottomPanel/StatusLabel` 扩宽并左移，使等级、经验和金币文本不再挤压 Bag / Equip 按钮，也降低右侧裁切风险。
- `HUD/BottomPanel/MenuButtons` 左移，为状态文本留出固定区域。
- `ArtPreview` 默认隐藏，仍保留节点供调试或资源审计时启用。
- `HUD/CharacterPortrait` 默认隐藏，避免把角色立绘方向稿常驻显示在游戏右上角。
- 新增 `player_input_and_ui_test.gd` 布局断言，覆盖 HUD 状态区域、ArtPreview 默认隐藏和 HUD 角色立绘默认隐藏。

修正后非 headless 快照仍输出：

```text
visual_snapshot_test: PASS /tmp/pixeldragoncity_visual_snapshot.png
```
