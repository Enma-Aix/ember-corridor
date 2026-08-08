# M1 CMB-007 输入缓冲与取消窗口执行测试计划

## 目标

CMB-007 建立独立于场景和渲染帧的 fixed-tick 输入缓冲。缓冲模型只记录输入事实并提供单次消费；具体动作是否可取消，仍由当前 `AttackDefinition.cancel_windows` 决定。

## 本项范围

- 默认缓冲长度为 8 tick。
- 每项输入记录 `action`、`pressed_tick`、`released_tick`，消费时补充 `consumed_tick`。
- 同一 action 的新按下替换尚未消费的旧按下；不同 action 相互隔离。
- 输入在 age 0 至 7 有效，age 8 过期。
- 一个按下事件最多消费一次。
- 暂停期间没有 fixed tick，缓冲年龄不推进。
- 应用失焦时清空尚未消费的输入，返回窗口后不得自动出招。
- 沙盒只通过 Input action 读取攻击，不查询具体键码。

不在本项内：输入重绑定 UI、UI/战斗 Context 栈、手柄断开弹窗、自动普通连击辅助选项、技能冷却和敌人 AI。

## 自动化验收

1. 正常路径：按下攻击后在 age 0 至 7 均可查询并消费。
2. 边界：第 7 tick 仍有效，第 8 tick 必须过期并从 pending 集合移除。
3. 释放：消费前和消费后的 release 均回写到该输入事件历史。
4. 单次消费：第二次消费返回空结果。
5. 多 action：消费 attack 不得删除 dodge。
6. 暂停：只改变模拟渲染 delta、不调用 `advance_tick()` 时状态完全不变。
7. 无效输入：空 action 与 0/超上限缓冲长度被拒绝；失败配置不得破坏先前有效配置。
8. 生命周期：`clear()` 清除 pending，`reset()` 同时清除 tick 与历史。

## 人工验收

1. 启动 M1 沙盒，确认日志出现 `[InputBufferSandbox] CMB-007 input buffer ready`。
2. 在 A1/A2 取消窗前提前按攻击，观察 HUD 缓冲年龄递增并在窗口开启时清空。
3. 暂停后等待，再恢复，确认缓冲没有因渲染时间流逝而过期。
4. 按攻击后立即切出窗口，再返回，确认没有延迟自动攻击。
5. 用 J 与 XInput X 重复相同节奏，结果一致。

当前整套回归预期为 `PROJECT TEST SUMMARY: 87 passed, 0 failed`。

## 依赖与版权

依赖 FND-002 与 CMB-002。没有新增第三方代码、插件或素材。
