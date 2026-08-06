# M0 实现记录

基线日期：2026-08-06

## Backlog 对照

| ID | 实现入口 | 自动验收 |
| --- | --- | --- |
| FND-001 | project.godot、目录占位文件 | tools/validate_project.py、Godot headless import |
| FND-002 | SettingsService、boot 调试场景 | test_runner 输入 Action 测试、人工设备切换 |
| FND-003 | project.godot layer_names | test_runner 碰撞层测试 |
| FND-004 | GameLog、VersionInfo、ErrorBoundary、App | 启动日志、静态结构校验 |
| FND-005 | scripts/data、DataRegistry | 有效、重复和非法 ID 测试 |
| FND-006 | tests/test_runner.gd | 非零失败码、JUnit XML、JSON |
| FND-007 | export_presets.cfg、m0-ci.yml | GitHub Actions Windows Debug artifact |
| FND-008 | licenses、资产登记表 | 静态表头和文件存在校验 |

## 可逆决策

- M0 的 XInput 按钮映射只用于验证全部 Action。M1 实现 Input Context 与输入缓冲时，可在不改变业务调用方的情况下调整组合键。
- typed Resource 子类只冻结身份字段与类别，不提前冻结战斗、敌人、物品和关卡的完整 schema。
- M0 启动画面是 Debug 探针，不是正式 UI；Release 构建自动隐藏调试面板。

## 官方依据

- Godot 4.7.1 归档：https://godotengine.org/download/archive/4.7.1-stable/
- Godot 命令行：https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html
- InputMap：https://docs.godotengine.org/en/latest/classes/class_inputmap.html
- Godot 许可合规：https://docs.godotengine.org/en/latest/about/complying_with_licenses.html

