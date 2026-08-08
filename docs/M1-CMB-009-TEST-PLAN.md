# M1 CMB-009 破线突技能测试计划

## 目标

CMB-009 提供刃契者首个数据驱动主动技能“破线突”。技能的身份、冷却、攻击时间线、伤害、位移、阻挡层、穿透层和取消规则均来自 `SkillDefinition`、`AttackDefinition` 与 `SkillMovementProfile`；核心模型不读取场景、动画、UI、音频或全局输入。

## 数据基线

| 项目 | 基线 |
| --- | --- |
| Skill ID | `skill.bladebound.linebreaker` |
| 输入 | U / XInput Y（`skill_1`） |
| 冷却数据 | 5 秒；实际冷却组件属于后续 SKL-002 |
| 时间线 | startup 2 / active 8 / recovery 10，共 20 tick |
| 位移 | tick 1–10，每 tick 17.6 px，共 176 px，按起手左右朝向镜像 |
| 阻挡 | `WorldStatic`，collision mask 1 |
| 穿透 | `EnemyBody`，collision mask 4；目标标签 `enemy.size.small` |
| 攻击取消 | tick 10–20 → `action.attack` |
| 闪避取消 | tick 12–20 → `action.dodge` |

普通三连段仅在各自 Resource 声明的 `action.skill_1` 窗口内允许转入破线突，并且沙盒要求当前段已经产生至少一次命中确认。A1/A2/A3 的技能窗分别为 9–18、10–21、13–27。

## 自动化验收

1. `SkillDefinition` 的必需字段、嵌套攻击、移动配置和取消规则全部通过验证，DataRegistry 索引 11 份顶层定义。
2. 位移在 tick 1 与 tick 10 均生效，tick 0 与 tick 11 均为零；左右累计精确为 +176 / -176 px。
3. 运行时深复制 Resource；配置完成后修改源 Resource 不改变当前技能。
4. 技能在第 20 tick 完整结束；非法朝向、运行中重启和非法配置不会部分修改状态。
5. 提前攻击输入在 age 7、技能 tick 10 被消费；tick 20 仍可取消，完成后的输入不改变已结束动作。
6. A1/A2/A3 的技能取消窗前、首 tick、末 tick和后一 tick结果准确；未声明的取消被拒绝。
7. 真实物理场景中玩家穿过两个 `EnemyBody` 训练目标，各命中一次，最终移动 176 px；靠近右侧 `WorldStatic` 时停在墙前。
8. 沙盒完成 A1 命中确认 → 破线突，以及破线突提前缓冲攻击 → A1 的双向取消。
9. 技能结束后恢复玩家 collision mask、普通移动、朝向更新和判定框关闭状态。

当前整套回归预期为 `PROJECT TEST SUMMARY: 87 passed, 0 failed`。

## 人工验收

1. 启动 `scenes/tests/movement_sandbox.tscn`，确认日志包含 `[LinebreakerSandbox] CMB-009 linebreaker ready`。
2. 面向右侧按 U / XInput Y，确认玩家水平突进并穿过两个训练目标，两个目标各结算一次。
3. 在右墙前重复，确认角色停在墙前且技能按 20 tick 正常结束，不发生状态锁死。
4. 面向左侧重复，确认位移、判定框和青蓝色调试轨迹完全镜像。
5. A1 命中后在 tick 9–18 输入技能，确认能取消；面向空处落空时相同输入不得走命中确认取消路径。
6. 技能早期输入 J / XInput X，确认输入保留至 tick 10 并进入 A1；tick 12–20 输入闪避可离开技能。

## 已知限制与下一项

当前技能轨迹仍是原创调试几何表现，不是发行级角色动画。CMB-010 已实现与战斗逻辑解耦的 Hit Stop、相机、VFX 与 SFX 请求；下一项 DBG-001 负责训练假人与战斗调试 HUD，SKL-002 才负责通用技能槽与冷却组件。

## 依赖与版权

依赖 CMB-008、CMB-003 与 CMB-007。没有新增第三方代码、插件或运行时素材。
