# CMB-002 AttackDefinition 与时间线

## 范围

- 扩展 typed `AttackDefinition`，数据化 startup、active、recovery、hit stop 和取消窗口。
- 新增嵌套 `AttackCancelWindow` Resource，使用包含首尾的 action tick 与目标标签。
- 新增 `AttackTimelineModel`，以显式 60 Hz tick 推进攻击快照。
- Debug 沙盒以分段色条显示时间线，并可用 attack Action 启动运行时预览。
- 不创建实际 Hitbox，不结算命中、伤害、受击或动画。

## 固定边界

- action tick 从 1 开始；tick 0 表示尚未开始。
- startup = 6、active = 3、recovery = 11 时，总时长为 20 tick。
- startup：tick 1–6；active：tick 7–9；recovery：tick 10–20；tick 21 起 complete。
- active 阶段是唯一报告 `is_hitbox_active = true` 的阶段。
- 首个占位 A1 数据的闪避取消窗为 tick 15–20，包含首尾。
- 运行时开始时深复制 Resource；热修改源数据不改变已经开始的动作。

## 自动化验证

- 三阶段起止、总时长、零 startup/zero recovery 边界和 active 判定。
- 非法时长、空/反向/越界取消窗、无效或重复目标标签被拒绝。
- 重叠取消窗按 tick 返回去重、排序后的目标标签。
- 运行时精确推进 20 tick，阶段信号只在 1、7、10 tick 切换并只完成一次。
- timeline 运行期间拒绝重启；无显式 advance 时暂停稳定；reset 清空快照。
- `data/attacks/dev_a1.tres` 可加载、校验并由 DataRegistry 索引。
- 灰盒色条宽度与 6/3/11 tick 比例一致，Release 隐藏调试面板。
- Linux 与 Windows 原生 Godot 测试，以及 Windows 导出 EXE 启动。

## 人工验收

1. 使用 Godot 4.7.1 Debug 构建启动主场景。
2. 确认底部时间线显示 Startup 1–6、Active 7–9、Recovery 10–20。
3. 按 J 或 XInput X 启动预览，观察当前 tick 与阶段顺序。
4. 确认 tick 15–20 显示 `action.dodge` 取消目标。
5. 连续按 attack，确认运行中的时间线不会重启。
6. 重复移动、跳跃与闪避验收，确认攻击预览不改变玩家玩法状态。

## 明确未实现

- CMB-003 Hitbox/Hurtbox 与命中去重。
- CMB-004 DamagePacket、HitResult 与伤害公式。
- CMB-007 输入缓冲和实际取消执行。
- CMB-008 普通三连段的动画、位移、命中和状态接线。
