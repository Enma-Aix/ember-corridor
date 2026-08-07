# Vertical Slice 实现提示词

前提：M1 战斗沙盒已经通过手感评审和自动化测试。

目标：完成沉降工厂的 15 至 25 分钟纵向切片。

阅读：

- 02-GDD.md
- 03-COMBAT-DESIGN.md
- 04-CLASS-AND-SKILLS.md
- 05-DUNGEON-DESIGN.md
- 06-PROGRESSION-ECONOMY.md
- 08-ART-AND-UI-GUIDE.md
- 12-FIGMA-UX-UI-WORKFLOW.md
- 10-BACKLOG.md 的 M2
- 11-ACCEPTANCE-TEST-PLAN.md

执行方式：

1. 按 10-BACKLOG.md 的依赖顺序拆分小任务。
2. 先完成灰盒全流程，再逐步加入正式视觉和音频。
3. 每加入一个敌人、技能或房间，都建立独立测试场景。
4. 存档与奖励使用固定样例做故障注入。
5. 每周至少执行一次完整新存档通关。
6. UI-001 至 UI-004 开始前确认 UID-001、UID-002 已冻结。
7. UI 完成后执行 UID-003，不把“基本相似”当作还原验收。

不得因为内容开发修改已冻结的战斗基础规则。确需修改时，先提供：

- 问题证据。
- 最小调整。
- 受影响测试。
- 对既有技能和敌人的回归范围。

完成后按 11-ACCEPTANCE-TEST-PLAN.md 第 12 节执行完整流程，并提交性能、存档、手柄和许可证报告。
