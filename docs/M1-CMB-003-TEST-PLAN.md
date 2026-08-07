# CMB-003 Hitbox/Hurtbox 与命中去重

## 范围

- 为 `AttackDefinition` 增加判定框尺寸、左右偏移、命中高度与 `rehit_interval_ticks`。
- `HitboxComponent` 只在攻击 active tick 开启，并按左右朝向镜像判定框。
- `HurtboxComponent` 检测 Area2D 接触并转发不可变的 `HitContact` 快照。
- `HitResolverModel` 是接触接受/拒绝的唯一入口，处理阵营、无敌、高度与重复命中。
- Debug 沙盒显示玩家 Hitbox、玩家与两个训练目标的 Hurtbox，以及接触计数。
- 不生成 DamagePacket，不修改生命、韧性或角色状态。

## 固定边界

- 去重键由 `source_instance_id + hit_id + target_instance_id` 组成。
- `rehit_interval_ticks = 0` 表示同一 hit_id 对同一目标最多接受一次。
- 正间隔在 `last_accepted_tick + interval` 当 tick 允许再次接触，提前一 tick 拒绝。
- 同一 hit_id 可以各命中多个不同运行时目标一次。
- 多目标批处理按 `target_instance_id` 排序，事件顺序可复现。
- 同阵营、目标无敌、纵深形状不相交或命中高度不相交时拒绝。
- 命中高度区间包含首尾；两个区间只在同一端点接触时视为重叠。
- PlayerHitbox 只检测 EnemyHurtbox；EnemyHitbox 只检测 PlayerHurtbox。

## 自动化验证

- AttackDefinition 判定框字段与非法尺寸、高度和重击间隔校验。
- 同 hit_id 去重、新 hit_id 重置、正 rehit interval 前/内边界。
- 模拟暂停和帧率波动时 action tick 不推进，因此不会重复接受。
- 阵营、无敌、高度 miss 与包含首尾的高度接触。
- 三目标输入乱序时，接受信号按运行时目标 ID 稳定排序。
- 左右偏移精确镜像；碰撞 layer/mask 与命名架构一致。
- 真实 Area2D 一像素纵深重叠成立、分离一像素不成立。
- 同一 Area2D 重叠禁用再启用时由 resolver 阻止重复接触。
- 场景退出后 Hitbox/Hurtbox 节点释放，不留下全局监听。
- Linux 与 Windows 原生 Godot 测试，以及 Windows 导出 EXE 启动。

## 人工验收

1. 使用 Godot 4.7.1 Debug 构建启动主场景。
2. 确认蓝色 Hurtbox 只在 Debug 显示，橙色 Hitbox 初始隐藏。
3. 面向右侧两个训练目标按 J / XInput X，确认橙色 Hitbox 只在 tick 7–9 显示。
4. 确认一次 A1 对两个目标各接受一次；active 的后续 tick 不重复计数。
5. 完成后再次攻击，确认新 hit_id 可再次分别接触两个目标。
6. 移动到目标右侧并向左攻击，确认判定框水平镜像。
7. 沿纵深边缘和跳跃高度反复测试，确认可见交叠与接触计数一致。
8. 暂停后恢复，确认同一攻击不会再次计数；Release 构建不显示碰撞调试图形。

## 明确未实现

- CMB-004 DamagePacket、HitResult、伤害与暴击公式。
- CMB-005 生命、韧性、受击或失败状态。
- CMB-007 输入缓冲和实际取消执行。
- CMB-008 普通三连段状态接线与动画。
