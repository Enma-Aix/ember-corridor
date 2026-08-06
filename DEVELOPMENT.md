# 开发与验收

## 分支规则

- main 只通过 Pull Request 更新。
- 每个任务使用独立分支，并在提交与 PR 中标明 Backlog ID。
- M0 分支固定为 codex/m0-foundation。
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
