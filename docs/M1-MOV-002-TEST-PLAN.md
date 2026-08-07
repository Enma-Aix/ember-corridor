# MOV-002 视觉高度、跳跃和阴影

## 范围

- 地面坐标继续由 CharacterBody2D 的 global_position 管理。
- ElevationComponent 以独立的 elevation、vertical_velocity 和 gravity 模拟跳跃。
- VisualRoot 的局部 Y 等于基础位置减 elevation；Shadow 保留在地面节点。
- 当前高度范围由 elevation 加 min_hit_height / max_hit_height 得出。
- 不实现攻击、伤害、低矮危险物伤害或空中状态机。

## 固定首轮调试值

- 跳跃初速度：720 px/s。
- 重力：1800 px/s²。
- 角色自身命中高度范围：0 至 56 px，再叠加当前 elevation。
- 物理更新：60 tick/s。

这些数值用于首轮灰盒验证，后续只能在保留测试记录的前提下调整。

## 自动化验证

- 只有 grounded 状态接受跳跃，空中重复跳跃被拒绝。
- 跳跃产生正高度，单次稳定落地并钳制到 elevation = 0。
- 非法跳跃速度、重力、高度范围和 delta 不改变有效状态。
- 高度范围支持相交、不相交、边界相交和反向查询。
- Player 场景跳跃时 CharacterBody2D 地面坐标不变，VisualRoot 上移且 Shadow 不动。
- Linux 与 Windows 原生 Godot 测试，以及 Windows 导出 EXE 启动。

## 人工验收

1. 使用 Godot 4.7.1 Debug 构建启动移动沙盒。
2. 按 K 或 XInput A，确认角色视觉上升后稳定落地。
3. 空中连续按跳跃，确认不会二段跳或重置竖直速度。
4. 跳跃同时使用 WASD，确认地面 X/Y 仍可移动并受房间墙体阻挡。
5. 确认阴影保持在地面投影处，不随 VisualRoot 上升。
6. 观察调试面板：高度、竖直速度、grounded 和命中高度范围连续且合理。
7. 当角色高度完全越过 0 至 24 的低位探针时，面板显示 clear；落地后恢复 overlap。

## 明确未实现

- MOV-003 的闪避、无敌 tick 与冷却。
- CMB-001 的通用有限状态机。
- 攻击 Hitbox/Hurtbox 与实际伤害结算。
- 低矮危险物的正式碰撞、伤害和美术反馈。
