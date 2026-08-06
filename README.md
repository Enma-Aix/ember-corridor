# 余烬回廊（Ember Corridor）

原创、完全离线的 2D 横版卷轴动作 RPG。当前仓库处于 M0 工程基线阶段，只包含可验证的 Godot 工程基础，不包含正式战斗、关卡或高保真 UI。

## 固定技术基线

| 项目 | 决策 |
| --- | --- |
| 引擎 | Godot 4.7.1 Stable（标准版） |
| 脚本 | Typed GDScript |
| 渲染 | Compatibility |
| 逻辑帧 | 60 Hz |
| 首发目标 | Windows 10/11 x64 |
| 模式 | 完全离线单机 |
| 第三方插件 | M0 不引入 |

## 5 分钟启动

1. 从 Godot 官方归档下载 Godot 4.7.1 Standard。
2. 在 Godot Project Manager 中导入本目录的 project.godot。
3. 确认右上角渲染器为 Compatibility。
4. 按 F6 或 F5 启动 M0 调试场景。
5. 在调试构建中按键或操作 XInput 手柄，屏幕会显示当前输入设备和被识别的 Action。

键盘默认映射：

| Action | 默认键 |
| --- | --- |
| 移动 | W / A / S / D |
| 普通攻击 | J |
| 跳跃 | K |
| 闪避 | L |
| 技能 1～4 | U / I / O / P |
| 终极技能 | H |
| 交互 | Space |
| 暂停 | Esc |

XInput 默认映射在 M0 作为工程验证用途；可在启动画面逐项验证。正式输入 Context、技能组合键与重绑定界面属于后续里程碑。

## 自动验证

本机安装 Godot 4.7.1 后，在仓库根目录运行：

    python3 tools/validate_project.py
    godot --headless --path . --import --quit
    godot --headless --path . --script res://scripts/tools/validate_data.gd
    godot --headless --path . --script res://tests/test_runner.gd
    mkdir -p build/windows
    godot --headless --path . --export-debug "Windows Desktop" build/windows/EmberCorridor.exe

测试失败时返回非零退出码，JUnit XML 和 JSON 报告写入 build/test-results。CI 还会把同一导出预设生成为 PCK 并实际启动，验证打包后的动态 Resource 扫描。

## M0 完成范围

- FND-001：Godot 4.7.1 工程、Compatibility renderer、规划目录。
- FND-002：Input Action、键盘/XInput 默认绑定、设备切换信号与调试探针。
- FND-003：10 个命名 2D 碰撞层及自动校验。
- FND-004：带时间/级别/模块的日志、版本信息、统一错误上报。
- FND-005：typed Resource 基类、定义子类、DataRegistry、重复 ID 和无效数据阻断。
- FND-006：单命令 headless 测试、非零失败码、JUnit/JSON 报告。
- FND-007：Windows Debug 导出预设与 GitHub Actions 构建产物。
- FND-008：Godot 许可说明和第三方资产登记表。

完整冻结方案位于 docs/project-plan。下一阶段是 M1 战斗沙盒，未经单独批准不会在本分支实现。

## 版权边界

本项目只借鉴横版卷轴动作 RPG 的类型经验，不复制 DNF 或其他已发行游戏的素材、名称、职业、技能、地图、音乐或 UI。仓库公开不等于项目代码和原创内容已授予复用许可；项目自身许可证尚待仓库所有者另行决定。
