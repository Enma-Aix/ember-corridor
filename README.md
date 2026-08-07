# 余烬回廊（Ember Corridor）

原创、完全离线的 2D 横版卷轴动作 RPG。M0、MOV-001/002/003 与 CMB-001 已完成；当前分支实现 M1 的 CMB-002 数据驱动攻击时间线，不包含实际命中、伤害、敌人、关卡或高保真 UI。

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
4. 按 F5 启动 M1 移动、跳跃、闪避与攻击时间线沙盒。
5. 使用 WASD / 左摇杆移动、K / XInput A 跳跃、L / XInput B 闪避、J / XInput X 预览攻击时间线。

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

测试失败时返回非零退出码，JUnit XML 和 JSON 报告写入 build/test-results。CI 会在 Linux 和 Windows 原生环境运行测试，并实际启动导出的 Windows EXE。

## M1 当前范围

- MOV-001：八方向地面移动。
- 横向速度 320 px/s，纵深速度为横向的 90%。
- 只有水平输入改变左右朝向，纯纵深移动不翻转角色。
- CharacterBody2D 与 WorldStatic 灰盒边界碰撞。
- MOV-002：视觉高度、竖直速度、重力、跳跃和稳定落地。
- VisualRoot 随 elevation 上移；CharacterBody2D 地面坐标与 Shadow 保持在地面平面。
- min_hit_height / max_hit_height 高度范围查询，可测试低位判定是否被跳过。
- MOV-003：24 tick 八方向闪避，第 4 至 13 tick 无敌，45 tick 冷却。
- 闪避距离 70.4 px；无输入沿当前朝向；CharacterBody2D 阻止穿越 WorldStatic。
- CMB-001：显式合法转换表、事务性配置、结构化非法转换拒绝与信号。
- 状态机核心不依赖场景或表现层；终止状态、reset、对象释放与固定 tick 稳定性可测试。
- CMB-002：AttackDefinition 的 startup/active/recovery、hit stop 与包含首尾的取消窗。
- Debug 色条按 6/3/11 tick 比例可视化；运行时使用 Resource 深复制快照并显式逐 tick 推进。
- 正常、边界、无效输入、真实墙体、状态转换和攻击时间线自动化测试。

详细测试边界见 docs/M1-MOV-001-TEST-PLAN.md、docs/M1-MOV-002-TEST-PLAN.md、docs/M1-MOV-003-TEST-PLAN.md、docs/M1-CMB-001-TEST-PLAN.md 与 docs/M1-CMB-002-TEST-PLAN.md。

## M0 完成范围

- FND-001：Godot 4.7.1 工程、Compatibility renderer、规划目录。
- FND-002：Input Action、键盘/XInput 默认绑定、设备切换信号与调试探针。
- FND-003：10 个命名 2D 碰撞层及自动校验。
- FND-004：带时间/级别/模块的日志、版本信息、统一错误上报。
- FND-005：typed Resource 基类、定义子类、DataRegistry、重复 ID 和无效数据阻断。
- FND-006：单命令 headless 测试、非零失败码、JUnit/JSON 报告。
- FND-007：Windows Debug 导出预设与 GitHub Actions 构建产物。
- FND-008：Godot 许可说明和第三方资产登记表。

完整冻结方案位于项目交接文档。下一项玩家战斗基础为 CMB-003 Hitbox/Hurtbox 与命中去重。

## 版权边界

本项目只借鉴横版卷轴动作 RPG 的类型经验，不复制 DNF 或其他已发行游戏的素材、名称、职业、技能、地图、音乐或 UI。仓库公开不等于项目代码和原创内容已授予复用许可；项目自身许可证尚待仓库所有者另行决定。
