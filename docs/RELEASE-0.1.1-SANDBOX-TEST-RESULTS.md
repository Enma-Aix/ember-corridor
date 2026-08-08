# Ember Corridor 0.1.1 M1 Tech Preview 沙盒测试结果

- 测试日期：2026-08-07（America/Los_Angeles）
- 引擎：Godot 4.7.1 Stable official (`a13da4feb`)
- 目标包：Windows 10/11 x64 Portable Release
- 版本：`0.1.1-m1-tech-preview`

## 结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 工程静态契约 | PASS | 85 个必需文件、14 个 Input Action、10 个碰撞层、6 个 Autoload |
| Godot 工程导入 | PASS | 无 GDScript 解析或导入错误 |
| Resource 数据 | PASS | 15/15 份定义加载并校验 |
| 自动化回归 | PASS | 87 passed、0 failed |
| 主场景启动 | PASS | MOV-001/002/003 与 CMB-001～010 全部出现就绪标记 |
| 场景级输入与战斗 | PASS | 覆盖移动、跳跃、闪避、三连段、破线突、穿敌/撞墙、命中与反馈 |
| 导出 PCK 再启动 | PASS | 从导出数据包启动并重新加载 15 份定义与 CMB-010 |
| Release 调试信息守卫 | PASS | 三块调试 UI 均由 `OS.is_debug_build()` 控制 |
| Windows 文件格式 | PASS | PE32+ GUI、x86-64、嵌入式 PCK |
| 发布边界 | PASS | 未包含 `design/`、`node_modules`、测试、文档或构建目录 |

## 产物校验

| 文件 | 大小 | SHA-256 |
| --- | ---: | --- |
| `EmberCorridor.exe` | 109,276,080 bytes | `d72028f679102a6af88d7bf07f2058d576e29de1d08a782f16a5823a7f7d7de2` |
| 导出验证 PCK | 204,704 bytes | `2e6651352edab569c8a387f9d6c8a91c4a87014a508eb290052444c1efae3a4a` |

首次导出检查发现 `design/` 下的概念图、网页字体与 `node_modules` 被错误包含，PCK 达到 22,918,936 bytes。修正导出边界后，最终 PCK 为 204,704 bytes；最终导出日志中不存在 `res://design/` 条目。

## 当前环境不能完成的检查

本沙盒没有 Windows 运行环境、Wine、X11、Wayland 或虚拟显示服务。Godot 的 headless dummy renderer 无法生成有效画面帧，因此以下项目没有伪装成已通过：

- Windows EXE 原生窗口启动。
- 真实键盘连续操作与手感。
- 实体 XInput 手柄。
- Release 画面截图和人工视觉验收。

Windows EXE 使用与已在 Linux 沙盒启动通过的 PCK 相同的导出范围，并通过 PE 架构与嵌入包检查；仍建议在 Windows 10/11 解压后直接运行，完成最后的窗口与输入验收。
