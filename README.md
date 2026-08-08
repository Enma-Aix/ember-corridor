# 余烬回廊（Ember Corridor）

原创、完全离线的 2D 动作可玩竖切片。M0、MOV-001/002/003 与 CMB-001 至 CMB-010 已完成自动化实现；`v0.1.2-visual-slice` 把旧方向的战斗底层接成了一个单房间流程，包含标题页、运行时场景与角色美术、两类敌人 AI、HUD、生命值、目标与胜负重开，但仍不是完整游戏。

## 方向纠正说明

本项目最初希望学习 DNF 类型，但立项阶段没有完成足够的品类调研和可玩参照验证。当前原型虽已实现 X/Y 地面移动与独立视觉高度，却没有建立 DNF 式带纵深横版房间、城镇—副本循环、职业技能体系、装备成长和多人协作等完整产品结构，因此不能称为 DNF 方向原型。

`v0.1.1-m1-tech-preview` 已撤回：它错误地把开发灰盒当成玩家版本。`v0.1.2-visual-slice` 只负责把这条旧方向收尾成能玩的视觉竖切片，仍不是后续正式游戏的玩法或美术基准。继续正式开发前必须先通过同类产品深度调研与方向验证门禁，详见 `docs/PROJECT-DIRECTION-CORRECTION.md`。

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

## 版本状态

`v0.1.0-m1-preview` 与 `v0.1.1-m1-tech-preview` 均已标记为不合格的历史灰盒，不代表当前游戏质量，也不建议作为玩家版本下载。

`v0.1.2-visual-slice` 是当前可运行的 Windows x64 Portable 视觉竖切片。它经过静态校验、Godot 数据校验、88 项自动测试、主场景启动、同资产布局预检和导出 PCK 沙盒冒烟测试；由于本执行环境无法运行 Windows 图形窗口，仍不等同于真实 Windows 可视化验收。公开 GitHub 预发布继续要求真实窗口截图、Windows 键盘完整流程与人工验收。

## 5 分钟启动

1. 从 Godot 官方归档下载 Godot 4.7.1 Standard。
2. 在 Godot Project Manager 中导入本目录的 project.godot。
3. 确认右上角渲染器为 Compatibility。
4. 按 F5 进入标题页，选择“进入熔炉回廊”开始单房间战斗。
5. 使用 WASD / 左摇杆移动、K / XInput A 跳跃、L / XInput B 闪避；连续按 J / XInput X 依次使出横斩、返斩和挑斩，U / XInput Y 使用破线突。击败机械蛛与盾卫即可完成本次竖切片。

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
    godot --headless --path . --export-release "Windows Desktop" build/windows/EmberCorridor.exe

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
- CMB-003：Area2D Hitbox/Hurtbox、阵营/无敌/高度过滤、同 hit_id 去重与可配置重击间隔。
- 判定框左右镜像；多目标事件稳定；暂停恢复、纵深边缘和对象释放可测试。
- CMB-004：不可变 DamagePacket/HitResult 与无场景依赖的纯伤害结算器。
- 负防御按 0 处理；默认暴击率 5%、上限 60%、默认倍率 1.5；无随机浮动并在最终取整前计算暴击。
- CMB-005：CombatantModel 应用生命与韧性，普通目标直接受击，精英保留动作至破防，首领只在特定标签或韧性归零时破防。
- 韧性伤害后 180 tick 开始恢复；破防结束回满并获得 60 tick 可配置减伤；失败为不可重复触发的终止状态。
- CMB-006：普通目标可浮空，每次空中命中增加抗性，使后续浮空降低、下落加快；精英与首领默认浮空免疫。
- 连续空中控制最多 210 tick；落地后倒地 30 tick，期间最多接受一次显式地面追击。
- CMB-007：每个输入记录 action、pressed/released tick；普通攻击缓冲恰好保持 8 个 fixed tick，单次消费，暂停不推进，失焦清空。
- CMB-008：刃契者横斩、返斩、挑斩三段数据驱动连段；A1/A2 只在 Resource 声明的 `action.attack` 窗口进入下一段，A3 结束后稳定回到空闲。
- A1/A2/A3 帧数据分别为 6/3/11、7/3/13、9/4/18；三段 Hitbox 左右镜像，第二段纵深更宽，第三段提供 5 tick 命中停顿数据和浮空配置。
- CMB-009：U / XInput Y 触发数据驱动破线突；20 tick 动作中前 10 tick 水平移动 176 px，穿过 EnemyBody 但由 WorldStatic 阻挡。
- 普攻命中确认后可在各段声明窗口转入破线突；技能在 tick 10–20 可接 A1、tick 12–20 可接闪避，边界均由 8 tick 输入缓冲覆盖。
- CMB-010：四档 Resource 配置驱动 Hit Stop、相机、VFX 与 SFX 请求；四路信号互不依赖，战斗结算不引用具体表现节点。
- 多目标 Hit Stop 取剩余最大值而不相加；相机震动取当前最大强度、短暂延长且封顶 30 tick，缩放脉冲不超过 3%。
- 正常、边界、无效输入、真实墙体、状态转换、攻击时间线、输入缓冲、三连段、破线突、命中接触、伤害公式、命中反馈、三类受击策略、浮空控制与视觉竖切流程共 88 项自动化测试。

详细测试边界见 docs/M1-MOV-001-TEST-PLAN.md、docs/M1-MOV-002-TEST-PLAN.md、docs/M1-MOV-003-TEST-PLAN.md，以及 docs/M1-CMB-001-TEST-PLAN.md 至 docs/M1-CMB-010-TEST-PLAN.md。

## M0 完成范围

- FND-001：Godot 4.7.1 工程、Compatibility renderer、规划目录。
- FND-002：Input Action、键盘/XInput 默认绑定、设备切换信号与调试探针。
- FND-003：10 个命名 2D 碰撞层及自动校验。
- FND-004：带时间/级别/模块的日志、版本信息、统一错误上报。
- FND-005：typed Resource 基类、定义子类、DataRegistry、重复 ID 和无效数据阻断。
- FND-006：单命令 headless 测试、非零失败码、JUnit/JSON 报告。
- FND-007：Windows Debug 导出预设与 GitHub Actions 构建产物。
- FND-008：Godot 许可说明和第三方资产登记表。

完整冻结方案位于项目交接文档。下一项为 DBG-001 训练假人与战斗调试 HUD。

## 版权边界

本项目只借鉴横版卷轴动作 RPG 的类型经验，不复制 DNF 或其他已发行游戏的素材、名称、职业、技能、地图、音乐或 UI。仓库公开不等于项目代码和原创内容已授予复用许可；项目自身许可证尚待仓库所有者另行决定。
