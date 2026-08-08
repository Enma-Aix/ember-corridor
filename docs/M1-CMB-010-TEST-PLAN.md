# M1 CMB-010 命中反馈服务测试计划

## 范围

- `HitFeedbackRequest` 从已接受并应用的命中结果创建不可变快照，不回写伤害结算。
- `HitFeedbackProfile` 用四份 Resource 配置 light、medium、heavy、finisher 的 Hit Stop、相机、VFX 与 SFX 预算。
- 房间级 `HitFeedbackService` 只处理固定 tick 停顿、相机合并和四路信号，不成为 Autoload，也不引用具体相机、粒子或音频节点。
- `HitFeedbackPresenter` 是可替换的场景适配器：驱动 Camera2D、原创几何占位 VFX，并记录待交给局部 AudioEmitter 的 SFX cue/层数。

## 固定预算

| 强度 | Hit Stop | 相机 | SFX 层 |
| --- | ---: | --- | ---: |
| light | 2–3 tick | 0.6 px、无缩放 | 1 |
| medium | 4–5 tick | 2.2 px、1% 脉冲 | 2 |
| heavy | 6–8 tick | 4.0 px、2% 脉冲 | 3 |
| finisher | 最多 10 tick | 5.0 px、3% 脉冲 | 3 |

重叠 Hit Stop 取剩余最大值，不求和。相机取当前最大振幅和缩放，只按配置短暂延长，合并后持续时间最多 30 tick。

## 自动化覆盖

1. 四份 Resource、设计预算、SFX 层数和 3% 缩放上限。
2. 命中反馈快照、拒绝结果、非法 ID、非有限坐标、非法方向和强度。
3. Hit Stop、相机、VFX、SFX 四路信号独立发出；无效重配置保持事务性。
4. Hit Stop 的开始、重叠最大值、逐 tick 递减、结束信号和零后稳定性。
5. 相机强度取最大、不相加、短延长、30 tick 封顶与中性复位。
6. 固定输入产生相同相机样本；配置使用深复制；对象释放不残留。
7. 真实沙盒多目标命中会暂停并恢复 SceneTree，表现适配器收到两组 VFX/SFX，房间在停顿中释放仍恢复运行。

当前整套回归预期为 `PROJECT TEST SUMMARY: 87 passed, 0 failed`，DataRegistry 应报告 15 份定义。

## 人工验收

1. 启动 `scenes/tests/movement_sandbox.tscn`，确认日志包含 `[HitFeedbackSandbox] CMB-010 feedback service ready`。
2. A1 同时命中两个目标，确认只停顿 3 tick；A3 与破线突使用 medium 的 4–5 tick 档位。
3. 从左右两侧、纵深边缘分别命中，确认圆环与方向线出现在接触位置，方向随攻击镜像。
4. 连续命中时观察镜头：强度不因多目标求和，结束后位置和缩放完全复位。
5. 暂停再恢复，确认 Hit Stop 不在用户暂停期间自行消耗；停顿中退出场景不会留下全局 paused 状态。
6. Debug 状态应分别显示 feedback、VFX、SFX 数量；Release 不显示调试文字，但反馈服务仍初始化。

## 已知限制与下一项

当前 VFX 是原创几何占位，不是发行级特效。SFX 适配器只完成解耦事件、cue 和层数验证，没有引入音频素材；实际局部播放、并发限制和随机音高属于 AUD-001。下一项为 DBG-001 训练假人与战斗调试 HUD。

当前无显示服务器的执行容器无法完成真实窗口截图和手感验收，因此 Windows 公开候选包的视觉门禁继续关闭。

## 依赖与版权

依赖 CMB-004 的 `HitResult` 字段与既有命中应用链。没有新增第三方代码、插件、音频或图像素材。
