# CMB-004 DamagePacket、HitResult 与伤害公式

## 范围

- `AttackDefinition` 增加伤害系数、固定伤害、韧性伤害、命中标签、发射配置与反馈强度。
- `DamagePacket` 从攻击资源和攻击者属性生成只读快照；源资源或返回标签被修改后，快照不变化。
- `DamageResolverModel` 是无场景、无表现、无内部随机状态的纯公式层。
- `HitResult` 记录接受状态、公式中间量、最终伤害和后续 CMB-005/CMB-010 所需字段。
- 沙盒对两个训练目标使用 25 / 100 防御，显示顺序无关的总伤害、范围和暴击数。
- 本任务不修改生命、当前韧性、受击状态、相机、音频或 VFX。

## 固定公式

    RawDamage = Attack × SkillCoefficient + FlatDamage
    DefenseMultiplier = 100 / (100 + max(0, Defense))
    FinalDamage = round(max(1, RawDamage × DefenseMultiplier × DamageModifiers × CriticalMultiplier))

- 防御小于 0 时按 0 计算。
- 伤害修正按传入顺序相乘；空修正数组等价于 1，修正为 0 仍受最终最少 1 点规则约束。
- 默认暴击率为 5%，有效暴击率上限为 60%，默认暴击倍率为 1.5。
- 暴击区间为 `critical_roll < effective_crit_chance`，等于上边界时不暴击。
- `critical_roll` 是调用方注入的 `[0, 1)` 已解析随机输入；公式层不读取全局 RNG，固定输入必得固定结果。
- 暴击倍率在最终取整前应用；基础伤害没有随机浮动。

## 拒绝边界

- 空包、无效 ID、负值或非有限攻击数值返回 `invalid_packet`。
- `NaN` / `Infinity` 防御返回 `invalid_defense`。
- 负数或非有限伤害修正返回 `invalid_damage_modifier`。
- 中间计算溢出为非有限值时返回 `non_finite_result`。
- 被拒绝的 `HitResult` 伤害为 0，且不会携带暴击、破防或反应结果。

## 自动化验证

- A1 伤害资源字段与非法系数、标签、发射配置和反馈强度。
- DamagePacket 的深快照、只读标签副本、空资源和全部非法字段边界。
- 100 攻击、1.0 系数、10 固伤对 25 防御得到 88；10.49 / 10.51 的取整边界。
- 负防御、0 防御、100 防御、极大防御和最少 1 点伤害。
- 5% 暴击前一值/上边界、60% 上限前一值/上边界和 1.5 倍取整前计算。
- 多个修正乘算、0 修正、非法修正及 HitResult 延迟字段。
- 240 次混合帧率/暂停式重复计算结果一致；多目标正反顺序结果一致。
- RefCounted 公式对象、快照和结果在持有者释放后均可回收。
- 真实沙盒一次 A1 接受两个目标并得到 88 + 55 = 143，不修改生命。
- Linux 与 Windows 原生 Godot 测试，以及 Windows 导出 EXE 启动。

## 人工验收

1. 使用 Godot 4.7.1 Debug 构建启动 `scenes/tests/movement_sandbox.tscn`。
2. 确认日志包含 `[DamageSandbox] CMB-004 formula ready`，且无持续错误或警告。
3. 面向两个训练目标按 J / XInput X，确认 HUD 显示 2 次结算、总计 143、范围 55–88、暴击 0。
4. 重复攻击并从左右两侧测试，确认每次新 hit_id 增加相同总伤害，朝向不改变公式。
5. 在纵深边缘、跳跃、闪避无敌、暂停恢复后重复，只有 CMB-003 接受的接触才产生公式结果。
6. 确认训练目标没有生命条、失败、韧性扣除或受击反应；这些属于 CMB-005。
7. 确认 Release 构建不显示调试 HUD，但启动日志和公式层无错误。

## 该阶段范围外（历史）

> 当前状态：CMB-005、CMB-006 与 CMB-010 已在后续里程碑实现；以下条目保留本阶段冻结时的职责边界。

- 后续 CMB-005 负责 Combatant 的生命、当前韧性、破防和受击反应。
- 后续 CMB-006 负责浮空、倒地与反无限连。
- 后续 CMB-010 负责 Hit Stop、相机、VFX 与 SFX 请求订阅；伤害数字仍不在当前实现范围内。
- 正式角色属性、装备修正、元素抗性和难度倍率来源。
