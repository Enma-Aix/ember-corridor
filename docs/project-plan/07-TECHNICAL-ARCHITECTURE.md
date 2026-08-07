# 技术架构

## 1. 技术基线

| 项目 | 决策 |
| --- | --- |
| 引擎 | Godot 4.7.1 Stable |
| 脚本 | Typed GDScript |
| 渲染 | Compatibility renderer |
| 目标平台 | Windows x64 |
| 逻辑帧 | 60 Hz |
| 版本控制 | Git，二进制资源使用 Git LFS |
| 首轮第三方插件 | 不引入 |

截至方案日期，Godot 官方 Windows 下载页提供 4.7.1 稳定维护版；4.7.2 仍处于候选阶段，因此工程固定到 4.7.1，不使用开发或 RC 版本。Godot 引擎采用 MIT 许可，发布时必须在游戏或附带文件中包含其许可证文本。

官方参考：

- [Godot Windows 下载页](https://godotengine.org/download/windows/)
- [Godot 官方版本归档](https://godotengine.org/download/archive/)
- [Godot 引擎许可证](https://godotengine.org/license/)
- [Godot 许可证合规说明](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)

## 2. 架构原则

1. 数据驱动：技能、攻击、敌人、装备和关卡使用 Resource 定义。
2. 组合优先：角色能力使用组件和资源组合，不建立深继承树。
3. 单向依赖：表现层依赖战斗事件，战斗逻辑不依赖具体 VFX 或 UI。
4. 可重建场景：退出房间后所有房间级对象可完整释放。
5. 可测试：核心公式、状态转换和存档迁移不得只存在于场景回调。
6. 无网络假设：不加入账号 ID、服务器时间或联机同步抽象。

## 3. 建议目录

    project/
    ├── project.godot
    ├── addons/
    ├── assets/
    │   ├── audio/
    │   ├── fonts/
    │   ├── sprites/
    │   ├── backgrounds/
    │   └── vfx/
    ├── data/
    │   ├── attacks/
    │   ├── skills/
    │   ├── characters/
    │   ├── enemies/
    │   ├── items/
    │   ├── loot/
    │   └── stages/
    ├── scenes/
    │   ├── boot/
    │   ├── menus/
    │   ├── hub/
    │   ├── actors/
    │   ├── rooms/
    │   ├── ui/
    │   └── tests/
    ├── scripts/
    │   ├── core/
    │   ├── combat/
    │   ├── actors/
    │   ├── ai/
    │   ├── dungeon/
    │   ├── progression/
    │   ├── save/
    │   ├── ui/
    │   └── tools/
    ├── tests/
    │   ├── unit/
    │   ├── integration/
    │   └── fixtures/
    ├── docs/
    └── licenses/

## 4. Autoload 服务

只允许以下全局服务：

| 服务 | 职责 |
| --- | --- |
| App | 启动状态、版本、退出流程 |
| SceneRouter | 场景切换、加载屏和错误回退 |
| EventBus | 少量跨场景领域事件 |
| DataRegistry | 静态 Resource 索引与校验 |
| SaveService | 存档槽、原子写入、迁移与备份 |
| SettingsService | 音频、画面、输入和可访问性 |
| AudioService | 音乐状态和全局总线 |

禁止把玩家、当前房间、敌人列表或临时战斗状态放入 Autoload。

## 5. 场景结构

### Player 场景

    PlayerRoot (CharacterBody2D)
    ├── GroundCollider
    ├── VisualRoot
    │   ├── SpriteOrRig
    │   ├── AnimationPlayer
    │   └── VfxSockets
    ├── Hurtbox
    ├── HitboxContainer
    ├── Shadow
    ├── StateMachine
    ├── Combatant
    ├── SkillLoadout
    └── AudioEmitter

### Enemy 场景

    EnemyRoot (CharacterBody2D)
    ├── GroundCollider
    ├── VisualRoot
    ├── Hurtbox
    ├── HitboxContainer
    ├── StateMachine
    ├── Combatant
    ├── Sensor
    ├── UtilityBrain
    └── AudioEmitter

### Room 场景

    RoomRoot
    ├── Background
    ├── GroundNavigation
    ├── CameraBounds
    ├── SpawnPoints
    ├── Hazards
    ├── Doors
    ├── WaveController
    └── RoomController

## 6. 核心领域对象

### Combatant

持有当前生命、韧性、阵营、属性快照和状态标签，提供：

- can_receive_hit。
- apply_damage。
- apply_status。
- heal。
- defeated 信号。

### Hitbox 与 Hurtbox

- Hitbox 持有 AttackDefinition 引用和本次攻击的 hit_id。
- Hurtbox 只负责接触检测与转发。
- HitResolver 是唯一结算入口。
- 碰撞回调不得直接修改生命值。

### DamagePacket

一次攻击的不可变快照：

- source_instance_id。
- attack_id。
- base_attack。
- coefficient。
- flat_damage。
- poise_damage。
- hit_tags。
- direction。
- launch_profile。
- crit_seed 或已解析暴击结果。

### HitResult

结算结果：

- accepted。
- final_damage。
- critical。
- broke_poise。
- reaction_type。
- knockback。
- hit_stop_ticks。
- feedback_strength。

## 7. 数据 Resource

首轮必须实现：

- AttackDefinition。
- SkillDefinition。
- CharacterDefinition。
- EnemyDefinition。
- ItemDefinition。
- LootTableDefinition。
- RoomDefinition。
- StageDefinition。

要求：

- 每个静态资源有全局唯一字符串 ID。
- ID 只使用小写英文、数字和下划线。
- 保存时校验重复 ID、空引用、负冷却和无效资源路径。
- UI 通过本地化 key 获取文本，不把显示名当作 ID。
- 资源加载失败必须产生可定位错误，不静默回退为错误数值。

## 8. 纵深与视觉高度

地面坐标直接使用 CharacterBody2D 的 global_position。视觉高度由 ElevationComponent 管理：

- elevation。
- vertical_velocity。
- gravity。
- grounded。
- min_hit_height 与 max_hit_height。

VisualRoot 的局部 Y 为负 elevation。Shadow 保持地面位置。碰撞和寻路只在地面平面计算。

该方案避免使用真正 3D 物理，同时保留横版纵深移动、跳跃和空中判定。

## 9. 碰撞层

建议固定：

| 层 | 内容 |
| ---: | --- |
| 1 | WorldStatic |
| 2 | PlayerBody |
| 3 | EnemyBody |
| 4 | PlayerHitbox |
| 5 | EnemyHitbox |
| 6 | PlayerHurtbox |
| 7 | EnemyHurtbox |
| 8 | Interactable |
| 9 | Hazard |
| 10 | Sensor |

项目创建时将层名写入 project.godot。不得使用未命名层。

## 10. AI

AI 使用 Utility 选择加状态机执行：

- Sensor 每 6 至 10 tick 更新一次距离和可见性，不必每物理帧做完整查询。
- UtilityBrain 对候选动作打分。
- AttackCoordinator 控制全房间高危险动作并发。
- ActionState 一旦进入承诺窗口，只能被受击、破防或明确取消条件中断。
- 寻路只解决战斗平面障碍；小房间优先使用简化 steering，避免昂贵路径查询。

## 11. 场景流

启动：

    Boot -> Data validation -> Save recovery -> Main Menu

游戏：

    Main Menu -> Hub -> Dungeon Loader -> Room -> Results -> Hub

房间切换：

1. RoomController 发出 completed。
2. DungeonRun 记录进度和奖励。
3. SaveService 写最近安全检查点。
4. SceneRouter 淡出并释放当前 Room。
5. 实例化下一 Room，绑定 DungeonRun 上下文。
6. 玩家放置到入口并恢复控制。

## 12. 存档

保存目录使用 Godot user 路径。每个槽位：

- slot_N.json：当前有效存档。
- slot_N.backup.json：上一次成功存档。
- slot_N.tmp：写入中的临时文件。

原子写入流程：

1. 生成纯数据 Dictionary。
2. 校验 schema 与必填字段。
3. 写入 tmp。
4. 重新读取并解析 tmp。
5. 当前存档移动为 backup。
6. tmp 替换当前存档。

加载失败时尝试 backup，并向玩家显示可理解提示。存档迁移按 schema_version 顺序执行，不允许在 UI 中临时修复字段。

## 13. 输入

- 只通过 Input action 访问输入。
- 业务代码不得查询具体键码。
- InputBuffer 保存 action、pressed_tick、released_tick。
- 同一物理 tick 统一消费输入，避免不同节点抢先处理。
- UI 和战斗输入使用不同 Context。
- 重绑定配置保存在全局设置，不放入单个存档槽。

## 14. UI 架构

- View 负责 Godot Control 节点。
- ViewModel 提供纯数据和命令。
- 领域服务不得直接查找 UI 节点。
- HUD 订阅玩家和 DungeonRun 事件。
- 弹窗进入时切换输入 Context 并暂停对应游戏树。
- 所有界面必须支持键盘、手柄焦点导航。

## 15. 音频

Audio Bus：

- Master。
- Music。
- SFX。
- UI。
- Ambience。

AudioService 只管理总线和音乐状态。角色局部音效由 AudioEmitter 播放。高频命中音使用并发限制和随机音高小幅变化。

## 16. 性能预算

目标测试场景：玩家、12 个普通敌人、2 个精英、全部战斗 HUD 和中等 VFX。

| 项目 | 预算 |
| --- | --- |
| 逻辑帧 | 60 Hz，无持续积压 |
| 同屏活动敌人 | 默认不超过 14 |
| 同屏活动 hitbox | 不超过 48 |
| 同屏粒子 | 视觉总量需在最低画质稳定 60 FPS |
| 场景切换 | SSD 目标 3 秒内 |
| 首次启动 | SSD 目标 8 秒内进入主菜单 |
| 存档写入 | 正常存档目标 100 ms 内完成 |

对象池只用于经过性能分析确认的高频对象，例如伤害数字和常用命中特效。不要预先池化所有对象。

## 17. 自动化测试

首轮不依赖第三方测试插件，使用 headless 测试场景和断言脚本。后续若引入测试框架，必须固定版本并记录许可证。

最低测试集：

- 伤害公式边界。
- 暴击上限与防御为负的处理。
- 状态机合法与非法转换。
- 输入缓冲边界 tick。
- 命中去重。
- 浮空强制落地。
- 装备预算。
- 掉落确定性。
- 存档写入、备份恢复和版本迁移。
- 房间完成与重置。

CI 最低步骤：

1. 检查 Godot 版本。
2. 无窗口导入项目。
3. 运行数据资源校验。
4. 运行 headless 测试套件。
5. 导出 Windows Debug 构建。
6. 保存测试和导出日志。

## 18. 日志与调试工具

开发构建提供：

- 战斗状态与当前 tick 显示。
- Hitbox/Hurtbox 可视化。
- AI 决策与分数显示。
- 房间事件日志。
- 训练假人伤害统计。
- 快速加载指定房间。
- 模拟装备与等级。

Release 构建默认禁用以上工具。

## 19. 本地化

- 初始语言：简体中文。
- 从第一天使用 localization key。
- UI 不根据中文字数硬编码宽度。
- CSV 或 Godot Translation 资源作为文本源。
- 变量插值统一处理，禁止拼接句子片段。

## 20. 隐私与网络

- 游戏不请求网络权限。
- 不收集遥测、硬件标识或个人数据。
- 崩溃日志只保存在本地，由玩家自愿提供。
- 不集成广告、账号 SDK 或在线成就 SDK 到 Vertical Slice。
