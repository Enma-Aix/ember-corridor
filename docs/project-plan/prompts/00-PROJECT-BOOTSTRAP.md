# 交给 Coding 的首轮提示词

你接手的是一个尚未创建工程的游戏项目方案。请先完整阅读：

- README-HANDOFF.md
- 01-PROJECT-VISION.md
- 03-COMBAT-DESIGN.md
- 07-TECHNICAL-ARCHITECTURE.md
- 09-MILESTONES.md
- 10-BACKLOG.md
- AGENTS.md

本轮只完成 M0 的 FND-001 至 FND-008，不实现正式玩家战斗或关卡。

目标：

1. 建立 Godot 4.7.1 Stable、typed GDScript、Compatibility renderer 工程。
2. 按技术架构创建目录。
3. 配置输入 Action 和命名碰撞层。
4. 建立最小 DataRegistry、Resource 基线和数据校验。
5. 建立 headless 测试入口。
6. 建立 Windows Debug 导出和 CI 配置。
7. 建立 licenses 与资产登记模板。
8. 写 DEVELOPMENT.md，说明环境、运行、测试和导出命令。

限制：

- 不引入第三方插件。
- 不下载或加入任何 DNF 素材。
- 不实现联机、账号或商店 SDK。
- 不提前实现战斗。
- 不覆盖工作区已有更改。

开始前先报告：

- 你理解的范围。
- 计划创建或修改的文件。
- 每个 FND 任务的验证方式。
- 发现的冲突或阻断。

完成后报告：

- 各 FND ID 的状态。
- 实际执行的测试和结果。
- Windows Debug 构建位置。
- 已知限制。
- 下一轮建议从哪个 Backlog ID 开始。

