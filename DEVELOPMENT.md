# 开发与验收

## 分支规则

- main 只通过 Pull Request 更新。
- 每个任务使用独立分支，并在提交与 PR 中标明 Backlog ID。
- M0 分支固定为 codex/m0-foundation。
- M1 MOV-001 分支固定为 codex/m1-mov-001，并叠加在 M0 绿色提交上。
- M1 MOV-002 分支固定为 codex/m1-mov-002，并叠加在 MOV-001 绿色提交上。
- M1 MOV-003 分支固定为 codex/m1-mov-003，并叠加在 MOV-002 绿色提交上。
- 不把构建产物、Godot 导入缓存或本机设置提交到 Git。

## M0 人工验收

1. 用 Godot 4.7.1 Standard 打开工程，确认无解析错误。
2. 启动 scenes/boot/boot.tscn。
3. 用键盘逐项按下 Action，确认 Active actions 更新。
4. 接入 XInput 手柄，移动摇杆并按按钮，确认 Device 切换为 XInput gamepad。
5. 切回键盘，确认 Device 切换回来。
6. 运行 headless 数据校验与测试命令，确认退出码为 0。
7. 创建 build/windows 目录，运行 Windows Desktop Debug 导出，确认生成 EXE 与 PCK 或内嵌 PCK。
8. 检查 GitHub Actions 的 Windows Debug artifact。

## 失败处理

- GDScript 解析错误、数据 ID 冲突、缺失定义或测试失败均阻断合并。
- 日志必须保留时间、级别和模块，不允许静默吞掉错误。
- Release 构建隐藏 M0 调试面板；调试信息只能在 Debug 构建显示。

## M0 明确不做

- 玩家移动、攻击、敌人、房间和掉落玩法。
- 正式 UI 视觉和 Figma 高保真还原。
- 存档实现、联网、账号、PVP、排行榜或云服务。
- 广告、抽卡、付费宝箱、每日任务、体力和高级货币。
- 第三方 Godot 插件。

## MOV-001 人工验收

1. 启动 scenes/tests/movement_sandbox.tscn。
2. 使用 WASD 分别测试四方向与四个对角方向。
3. 确认纵深速度显示为 288 px/s，横向显示为 320 px/s。
4. 纯 W/S 输入不改变朝向，A/D 输入稳定改变朝向。
5. 持续向四面边界移动，确认玩家无法穿过 WorldStatic。
6. Windows Debug EXE 启动后重复键鼠检查；实体 XInput 手柄检查记录为人工验收。

## MOV-002 人工验收

1. 启动 scenes/tests/movement_sandbox.tscn。
2. 使用 K 和 XInput A 分别跳跃，确认只能在 grounded 时起跳。
3. 确认 VisualRoot 上升和下降，CharacterBody2D 地面坐标与 Shadow 不随高度偏移。
4. 跳跃同时移动，确认 X/Y 地面运动和 WorldStatic 墙体阻挡继续生效。
5. 确认调试面板的 elevation 最终稳定回到 0，vertical velocity 回到 0，grounded 为 true。
6. 确认低位 0 至 24 高度探针在跳高后显示 clear，并在落地后恢复 overlap。

## MOV-003 人工验收

1. 启动 scenes/tests/movement_sandbox.tscn。
2. 使用 WASD + L 和左摇杆 + XInput B 测试八方向闪避。
3. 确认无输入闪避沿当前朝向，纯纵深闪避不改变朝向。
4. 确认 HUD 只在第 4 至 13 tick 显示 Invulnerable = true。
5. 确认动作第 24 tick 结束，随后冷却从 45 减至 0 才可再次启动。
6. 贴近四面边界反复闪避，确认 CharacterBody2D 不穿过 WorldStatic。
