# Art Prompt

为《像素龙城》生成原创 2D 像素美术。

风格要求：

- 16x16、24x24 或 32x32 像素基准。
- 清晰轮廓。
- 色彩适合奇幻 RPG。
- 不复制任何商业游戏素材。
- 可用于 Godot 2D 项目。

常用资产：

- 玩家角色八方向行走帧。
- 野狼、野兔、骷髅等怪物。
- 村庄、森林、矿洞 tileset。
- 背包、装备、金币、药水图标。

输出时说明：

- 尺寸
- 帧数
- 动画方向
- 调色板
- 透明背景要求

## 标准输出契约

每次生成或整理美术资源时，必须明确：

- 资源类型：角色、怪物、物品图标、tileset、UI、半身立绘或方向参考。
- 用途状态：`reference`、`prototype`、`blockout`、`production_candidate` 或 `production_ready`。
- 画布尺寸和单格尺寸，例如 `384x864`、`cell 96x96`。
- 动画帧数和方向数，例如 8 方向、每方向 4 帧。
- sheet 行列顺序，例如 `down/down_right/right/up_right/up/up_left/left/down_left/idle_front`。
- 是否透明背景；角色、怪物、图标和 UI 默认需要透明背景。
- 预期保存路径，例如 `assets/sprites/monsters/wild_wolf_walk_v1_atlas.png`。
- Godot 引用路径，例如 `res://assets/sprites/monsters/wild_wolf_walk_v1_atlas.png`。

## 拒收条件

以下结果不能作为正式资源：

- 复制或明显模仿商业游戏素材、地图块、UI、字体、角色造型或具体文本。
- 动画 sheet 不是严格网格，且没有说明裁切方式。
- 角色脚底中心在不同帧大幅漂移。
- UI 把大量中文或英文文字烘焙进按钮图片，导致后续无法本地化或改文案。
- 图标尺寸、边框和品质颜色不统一。
- 地图 tileset 无法区分可行走、不可通行、装饰和交互点。
