# M1 CMB-006 浮空、倒地与反无限连测试计划

## 目标

CMB-006 在 MOV-002 视觉高度和 CMB-005 CombatantModel 之上，建立完全由 60 Hz fixed tick 驱动的浮空、落地、倒地与追击规则。核心模型不读取 Input、不访问场景树、不播放表现资源，也不使用随机数；因此可在 Linux、Windows、暂停恢复和对象释放场景中确定性复现。

## 本项范围

- 普通目标接受带 `CombatLaunchProfile` 的攻击并进入 `airborne`。
- 每次空中命中增加 `JuggleResistance`。
- 抗性提高后续下落重力，并降低后续浮空速度。
- 连续浮空控制在第 210 个逻辑帧强制落地。
- 落地后进入 30 个逻辑帧的 `knockdown`；期间普通命中被稳定拒绝。
- 每次倒地窗口最多接受一次显式 `can_hit_downed` 地面追击。
- 精英和首领默认浮空免疫；生命、韧性与破防规则继续生效。
- 破防和目标失效优先于浮空/倒地，并清空浮空运行时状态。
- DataRegistry 加载启动器与地面追击两个新定义。

不在本项内：CMB-007 输入缓冲与取消窗执行、CMB-008 连段计数、正式敌人 AI、正式动画/VFX/音频、关卡内容和最终 UI。

## 固定规则与灰盒参数

| 项目 | 值 | 性质 |
| --- | ---: | --- |
| 逻辑频率 | 60 Hz | 工程基线 |
| 最大连续浮空控制 | 210 tick（3.5 秒） | 冻结规则 |
| 倒地窗口 | 30 tick（0.5 秒） | 冻结规则 |
| 每次倒地最多追击 | 1 hit | 冻结规则 |
| 普通目标可浮空 | true | 冻结规则 |
| 精英/首领可浮空 | false | 冻结规则 |
| 启动器初始向上速度 | 720 px/s | 可调灰盒值 |
| 基础浮空重力 | 1800 px/s² | 可调灰盒值 |
| 每次空中命中抗性增长 | 1.0 | 可调灰盒值 |
| 每点抗性重力增量 | 0.25 倍 | 可调灰盒值 |
| 最大重力倍率 | 2.5 倍 | 可调灰盒值 |
| 每点抗性浮空衰减 | 0.15 | 可调灰盒值 |
| 最低浮空倍率 | 0.35 倍 | 可调灰盒值 |

灰盒参数位于 `CombatReactionProfile` 和 `CombatLaunchProfile` Resource。核心规则常量位于 `JuggleModel`，修改冻结规则时必须同步本计划、单元测试和 CI 契约。

## 状态与优先级

状态优先级为：目标失效 > 破防 > 浮空/倒地 > 普通受击。进入破防或目标失效时调用 `interrupt_to_ground()`，避免残留高度或倒地计时器覆盖更高优先级状态。

- `grounded`：高度与竖直速度为 0，抗性和追击计数已清零。
- `airborne`：逐 tick 积累连续控制时间；空中命中先增加抗性，再以衰减倍率重新施加浮空速度。
- `knockdown`：高度固定为 0，倒地剩余帧逐 tick 递减；只允许一次显式地面追击。
- 第 209 次推进后仍可处于空中；第 210 次推进必须强制落地并进入完整 30 tick 倒地窗口。
- 倒地第 29 次推进后仍受保护；第 30 次推进后恢复为 `grounded`。

## 数据与事务边界

| 定义 ID | 用途 |
| --- | --- |
| `attack.dev.launcher_placeholder` | 沙盒 A1 启动攻击，引用启动器配置 |
| `combat.launch.dev_launcher` | 720 px/s 浮空，不可命中倒地目标 |
| `combat.launch.dev_ground_pursuit` | 不提供浮空速度，可命中倒地目标 |

`AttackDefinition.launch_profile` 与传给 `CombatantModel.apply_damage()` 的配置 ID 必须一致。缺失、错配或无效配置返回 `invalid_launch_profile`，且不修改生命、韧性、抗性、倒地追击次数或反应状态。倒地普通命中返回 `target_knockdown_protected`；第二次追击返回 `ground_pursuit_limit_reached`。

## 自动化验收矩阵

1. `ElevationModel`：外部浮空速度、倍率重力、强制落地、NaN/Inf/负值拒绝。
2. Resource 与 DataRegistry：8 个定义唯一且有效；启动器/追击 ID、速度和倒地权限正确。
3. 普通目标：首次启动、空中再命中、抗性增长、重力增大和浮空衰减。
4. 精确边界：第 210 tick 强制落地；30 tick 倒地窗口只允许一次包含边界的地面追击。
5. 免疫与优先级：精英/首领不浮空；破防和目标失效清空浮空状态。
6. 事务性：包与结算结果无效、launch profile 缺失/错配时状态保持不变。
7. 确定性：相同输入得到相同逐 tick 状态；没有 fixed tick 时暂停不推进。
8. 生命周期：模型和临时 Resource 释放后无悬挂场景引用。
9. 沙盒集成：普通训练目标的抽象 hit height 与 VisualRoot 高度同步；精英训练目标保持浮空免疫。
10. 回归：MOV-001/002/003 与 CMB-001 至 CMB-005 全部既有用例继续通过。

预期测试汇总为 `PROJECT TEST SUMMARY: 64 passed, 0 failed`，并且日志中不出现 `ERROR:` 或 `SCRIPT ERROR:`。

## 手工与平台验收

1. 启动 `scenes/tests/movement_sandbox.tscn`，确认出现 `[JuggleSandbox] CMB-006 airborne control ready`。
2. 使用 J / XInput X，确认普通训练目标视觉上升后落地，HUD 的 Air 与 JR 更新；精英目标不升空。
3. 连续命中普通目标，确认后续浮空幅度降低且下落加快。
4. 暂停游戏，确认高度、抗性、210/30 tick 计时均不推进；恢复后继续。
5. Linux 上执行静态校验、干净导入、数据校验、64 项测试、主场景启动和 PCK 启动。
6. GitHub Actions 的 `windows-latest` 作业执行原生导入、数据校验、64 项测试、工程启动，并实际启动导出的 x86-64 EXE。

沙盒只提供启动器的交互预览；一次地面追击上限与逐 tick 精确边界由自动化测试覆盖。正式手感需要在动画、受击反馈和敌人行为接入后再次调参。

## 依赖与版权

本项没有引入第三方代码、插件或素材，只新增原创 GDScript 与 Godot Resource。资产登记和离线边界保持不变。
