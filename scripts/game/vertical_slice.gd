extends Node2D

const PLAYER_SHEET := preload(
	"res://assets/runtime/characters/corridor_ranger_sheet_v01.png"
)
const ENEMY_SHEET := preload(
	"res://assets/runtime/characters/furnace_enemies_sheet_v01.png"
)
const SKILL_SHEET := preload(
	"res://assets/runtime/ui/skill_icons_runtime_v01.png"
)

const PLAYER_FRAME_SIZE := Vector2(512.0, 512.0)
const PLAYER_SCALE := 0.45
const PLAYER_BASELINES := [
	442.0,
	442.0,
	442.0,
	380.0,
	390.0,
	385.0,
]
const FONT_SUBSETS := [
	"res://assets/runtime/fonts/noto-sans-sc-57-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-103-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-104-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-105-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-106-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-107-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-108-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-109-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-110-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-111-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-112-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-113-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-114-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-115-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-116-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-117-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-118-wght-normal.woff2",
	"res://assets/runtime/fonts/noto-sans-sc-119-wght-normal.woff2",
]
const ENEMY_FRAME_SIZE := Vector2(418.0, 470.5)
const SHIELD_SCALE := 0.42
const SPIDER_SCALE := 0.42
const PLAYER_MAX_HEALTH := 100

@onready var combat_core: Node2D = $CombatCore
@onready var player: PlayerGroundMovementController = (
	$CombatCore/Actors/PlayerRoot as PlayerGroundMovementController
)
@onready var shield_target: CharacterBody2D = (
	$CombatCore/Actors/Targets/DummyB as CharacterBody2D
)
@onready var spider_target: CharacterBody2D = (
	$CombatCore/Actors/Targets/DummyA as CharacterBody2D
)
@onready var title_root: Control = %TitleRoot
@onready var hud_root: Control = %HudRoot
@onready var end_root: Control = %EndRoot
@onready var start_button: Button = %StartButton
@onready var retry_button: Button = %RetryButton
@onready var player_health_bar: ProgressBar = %PlayerHealthBar
@onready var player_health_label: Label = %PlayerHealthLabel
@onready var shield_health_bar: ProgressBar = %ShieldHealthBar
@onready var spider_health_bar: ProgressBar = %SpiderHealthBar
@onready var objective_label: Label = %ObjectiveLabel
@onready var combat_status_label: Label = %CombatStatusLabel
@onready var end_title: Label = %EndTitle
@onready var end_summary: Label = %EndSummary

var _player_sprite: Sprite2D
var _enemy_sprites: Dictionary = {}
var _enemy_models: Dictionary = {}
var _enemy_states: Dictionary = {}
var _player_health := PLAYER_MAX_HEALTH
var _run_started := false
var _run_completed := false
var _elapsed_seconds := 0.0
var _player_damage_flash := 0.0


func _ready() -> void:
	_configure_runtime_font()
	_configure_runtime_presentation()
	_configure_skill_icons()
	_configure_enemy_models()
	_configure_initial_positions()
	start_button.pressed.connect(_start_run)
	retry_button.pressed.connect(_restart_run)
	combat_core.process_mode = Node.PROCESS_MODE_DISABLED
	hud_root.visible = false
	end_root.visible = false
	title_root.visible = true
	start_button.grab_focus()
	_update_hud()
	print("[VisualSlice] playable presentation ready")


func _configure_runtime_font() -> void:
	var primary := load(
		"res://assets/runtime/fonts/noto-sans-sc-latin-wght-normal.woff2"
	) as Font
	if primary == null:
		push_error("[VisualSlice] runtime Latin font could not be loaded")
		return
	primary = primary.duplicate() as Font
	var fallbacks: Array[Font] = []
	for path: String in FONT_SUBSETS:
		var fallback := load(path) as Font
		if fallback == null:
			push_error("[VisualSlice] runtime font subset missing: %s" % path)
			continue
		fallbacks.append(fallback)
	primary.fallbacks = fallbacks
	var runtime_theme := Theme.new()
	runtime_theme.default_font = primary
	title_root.theme = runtime_theme
	hud_root.theme = runtime_theme
	end_root.theme = runtime_theme


func _physics_process(delta: float) -> void:
	if not _run_started or _run_completed:
		return
	_elapsed_seconds += delta
	_player_damage_flash = maxf(0.0, _player_damage_flash - delta)
	_update_player_animation()
	_update_enemy(spider_target, delta)
	_update_enemy(shield_target, delta)
	_update_hud()
	_check_outcome()


func _unhandled_input(event: InputEvent) -> void:
	if not _run_started and _is_confirm_event(event):
		_start_run()
		get_viewport().set_input_as_handled()
		return
	if _run_completed and _is_restart_event(event):
		_restart_run()
		get_viewport().set_input_as_handled()


func _configure_runtime_presentation() -> void:
	for path: NodePath in [
		NodePath("Background"),
		NodePath("Arena"),
		NodePath("DepthBandBack"),
		NodePath("CenterGuide"),
		NodePath("Hud/Title"),
		NodePath("Hud/Instruction"),
		NodePath("Hud/FeedbackStatusLabel"),
		NodePath("Hud/DebugPanel"),
		NodePath("Hud/AttackTimelinePanel"),
		NodePath("Actors/PlayerRoot/VisualRoot/Body"),
		NodePath("Actors/PlayerRoot/VisualRoot/Core"),
		NodePath("Actors/PlayerRoot/VisualRoot/FacingMarker"),
		NodePath("Actors/PlayerRoot/VisualRoot/AttackTrail"),
		NodePath("Actors/PlayerRoot/Hurtbox/DebugShape"),
		NodePath("Actors/Targets/DummyA/Body"),
		NodePath("Actors/Targets/DummyA/DummyAHurtbox/DebugShape"),
		NodePath("Actors/Targets/DummyB/Body"),
		NodePath("Actors/Targets/DummyB/DummyBHurtbox/DebugShape"),
	]:
		var canvas_item := combat_core.get_node_or_null(path) as CanvasItem
		if canvas_item != null:
			canvas_item.visible = false

	var player_shadow := player.get_node("Shadow") as Polygon2D
	player_shadow.scale = Vector2(2.8, 1.6)
	player_shadow.color = Color(0.0, 0.0, 0.0, 0.48)

	_player_sprite = _new_region_sprite(
		PLAYER_SHEET,
		Rect2(Vector2.ZERO, PLAYER_FRAME_SIZE),
		Vector2.ONE * PLAYER_SCALE
	)
	_player_sprite.name = "CorridorRangerSprite"
	_player_sprite.z_index = 4
	player.get_node("VisualRoot").add_child(_player_sprite)
	_set_player_frame(0)

	var spider_sprite := _new_region_sprite(
		ENEMY_SHEET,
		_enemy_region(false, 0),
		Vector2.ONE * SPIDER_SCALE
	)
	spider_sprite.name = "EmberSpiderSprite"
	spider_sprite.position = Vector2(0.0, -39.0)
	spider_sprite.z_index = 3
	spider_target.add_child(spider_sprite)
	_enemy_sprites[spider_target] = spider_sprite
	_add_enemy_shadow(spider_target, Vector2(68.0, 13.0))

	var shield_sprite := _new_region_sprite(
		ENEMY_SHEET,
		_enemy_region(true, 0),
		Vector2.ONE * SHIELD_SCALE
	)
	shield_sprite.name = "FurnaceShieldSprite"
	shield_sprite.position = Vector2(0.0, -86.0)
	shield_sprite.z_index = 3
	shield_target.add_child(shield_sprite)
	_enemy_sprites[shield_target] = shield_sprite
	_add_enemy_shadow(shield_target, Vector2(76.0, 15.0))


func _configure_initial_positions() -> void:
	player.position = Vector2(318.0, 525.0)
	spider_target.position = Vector2(760.0, 535.0)
	shield_target.position = Vector2(1015.0, 510.0)
	for target: CharacterBody2D in [spider_target, shield_target]:
		var model: CombatantModel = _enemy_models.get(target)
		if model != null:
			combat_core._dummy_visual_base_y[model.instance_id] = target.position.y


func _configure_enemy_models() -> void:
	var spider_hurtbox := (
		$CombatCore/Actors/Targets/DummyA/DummyAHurtbox as HurtboxComponent
	)
	var shield_hurtbox := (
		$CombatCore/Actors/Targets/DummyB/DummyBHurtbox as HurtboxComponent
	)
	var spider_model: CombatantModel = combat_core._combatants.get(
		spider_hurtbox.combatant_instance_id
	)
	var shield_model: CombatantModel = combat_core._combatants.get(
		shield_hurtbox.combatant_instance_id
	)
	_enemy_models[spider_target] = spider_model
	_enemy_models[shield_target] = shield_model
	_enemy_states[spider_target] = {
		"shield": false,
		"speed": 68.0,
		"range": 82.0,
		"damage": 8,
		"cooldown": 0.35,
		"windup": 0.0,
		"strike_done": false,
	}
	_enemy_states[shield_target] = {
		"shield": true,
		"speed": 38.0,
		"range": 108.0,
		"damage": 14,
		"cooldown": 0.9,
		"windup": 0.0,
		"strike_done": false,
	}
	if spider_model != null:
		spider_health_bar.max_value = spider_model.maximum_health
	if shield_model != null:
		shield_health_bar.max_value = shield_model.maximum_health


func _configure_skill_icons() -> void:
	var icon_nodes: Array[TextureRect] = [
		%SkillIcon1 as TextureRect,
		%SkillIcon2 as TextureRect,
		%SkillIcon3 as TextureRect,
		%SkillIcon4 as TextureRect,
	]
	var cell_size := Vector2(
		float(SKILL_SHEET.get_width()) / 4.0,
		float(SKILL_SHEET.get_height()) / 2.0
	)
	for index: int in icon_nodes.size():
		var atlas := AtlasTexture.new()
		atlas.atlas = SKILL_SHEET
		atlas.region = Rect2(Vector2(cell_size.x * index, 0.0), cell_size)
		icon_nodes[index].texture = atlas


func _start_run() -> void:
	if _run_started:
		return
	_run_started = true
	title_root.visible = false
	hud_root.visible = true
	combat_core.process_mode = Node.PROCESS_MODE_INHERIT
	objective_label.text = "任务 · 清除熔炉守卫"


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _update_player_animation() -> void:
	var frame := 0
	if combat_core.linebreaker_skill.is_active() or player.is_dodging():
		frame = 5
	elif combat_core.normal_attack_combo.timeline.is_running:
		frame = 3 if combat_core.normal_attack_combo.combo_index == 0 else 4
	elif player.velocity.length_squared() > 64.0:
		frame = 1 + (int(Time.get_ticks_msec() / 120) % 2)
	_set_player_frame(frame)
	_player_sprite.self_modulate = (
		Color(0.55, 0.94, 1.0, 1.0)
		if combat_core.linebreaker_skill.is_active()
		else Color(1.0, 0.62, 0.55, 1.0)
		if _player_damage_flash > 0.0
		else Color.WHITE
	)


func _update_enemy(target: CharacterBody2D, delta: float) -> void:
	var model: CombatantModel = _enemy_models.get(target)
	if model == null:
		return
	var state: Dictionary = _enemy_states[target]
	var is_shield := bool(state["shield"])
	var sprite: Sprite2D = _enemy_sprites[target]
	sprite.flip_h = player.position.x > target.position.x

	if model.is_defeated:
		_set_enemy_frame(target, 3)
		sprite.self_modulate = Color(0.35, 0.35, 0.4, 0.72)
		return
	if model.reaction_type != CombatantModel.REACTION_NONE:
		_set_enemy_frame(target, 3)
		sprite.self_modulate = Color(1.0, 0.72, 0.55, 1.0)
		return
	sprite.self_modulate = Color.WHITE

	var windup := float(state["windup"])
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		state["windup"] = windup
		_set_enemy_frame(target, 2 if is_shield else 3)
		if windup <= 0.22 and not bool(state["strike_done"]):
			state["strike_done"] = true
			_try_enemy_strike(target, state)
		if windup <= 0.0:
			state["cooldown"] = 1.45 if is_shield else 0.95
		_enemy_states[target] = state
		return

	state["cooldown"] = maxf(0.0, float(state["cooldown"]) - delta)
	var offset := player.position - target.position
	var close_enough := (
		absf(offset.x) <= float(state["range"])
		and absf(offset.y) <= 58.0
	)
	if close_enough and float(state["cooldown"]) <= 0.0:
		state["windup"] = 0.72 if is_shield else 0.48
		state["strike_done"] = false
		_enemy_states[target] = state
		return

	if not close_enough:
		var pursuit := Vector2(offset.x, offset.y * 0.72).normalized()
		target.position += pursuit * float(state["speed"]) * delta
		target.position.x = clampf(target.position.x, 130.0, 1150.0)
		target.position.y = clampf(target.position.y, 465.0, 604.0)
		combat_core._dummy_visual_base_y[model.instance_id] = target.position.y
		var walk_frame := 1
		if not is_shield:
			walk_frame = 1 + (int(Time.get_ticks_msec() / 150) % 2)
		_set_enemy_frame(target, walk_frame)
	else:
		_set_enemy_frame(target, 0)
	_enemy_states[target] = state


func _try_enemy_strike(target: CharacterBody2D, state: Dictionary) -> void:
	if player.is_dodge_invulnerable():
		combat_status_label.text = "闪避成功"
		return
	var offset := player.position - target.position
	if (
		absf(offset.x) > float(state["range"]) + 28.0
		or absf(offset.y) > 68.0
	):
		combat_status_label.text = "避开攻击"
		return
	_player_health = maxi(0, _player_health - int(state["damage"]))
	_player_damage_flash = 0.18
	player.position.x += signf(offset.x) * 18.0
	combat_status_label.text = "受到 %d 点伤害" % int(state["damage"])


func _update_hud() -> void:
	player_health_bar.value = _player_health
	player_health_label.text = "%d / %d" % [_player_health, PLAYER_MAX_HEALTH]
	var spider_model: CombatantModel = _enemy_models.get(spider_target)
	var shield_model: CombatantModel = _enemy_models.get(shield_target)
	if spider_model != null:
		spider_health_bar.value = spider_model.current_health
	if shield_model != null:
		shield_health_bar.value = shield_model.current_health
	var remaining := 0
	for model: CombatantModel in _enemy_models.values():
		if model != null and not model.is_defeated:
			remaining += 1
	objective_label.text = "任务 · 清除熔炉守卫  %d / 2" % (2 - remaining)
	if combat_core.normal_attack_combo.timeline.is_running:
		combat_status_label.text = "连段 A%d" % (
			combat_core.normal_attack_combo.combo_index + 1
		)
	elif combat_core.linebreaker_skill.is_active():
		combat_status_label.text = "破线突"


func _check_outcome() -> void:
	if _player_health <= 0:
		_finish_run(false)
		return
	for model: CombatantModel in _enemy_models.values():
		if model != null and not model.is_defeated:
			return
	_finish_run(true)


func _finish_run(victory: bool) -> void:
	if _run_completed:
		return
	_run_completed = true
	combat_core.process_mode = Node.PROCESS_MODE_DISABLED
	end_root.visible = true
	end_title.text = "回廊已肃清" if victory else "作战中断"
	end_summary.text = (
		"熔炉守卫已清除 · 用时 %.1f 秒\n这是接入正式美术与 HUD 的首个可玩竖切"
		% _elapsed_seconds
		if victory
		else "你倒在了熔炉回廊\n按 R 或选择下方按钮重新挑战"
	)
	retry_button.grab_focus()


func _set_player_frame(frame: int) -> void:
	frame = clampi(frame, 0, 5)
	var column := frame % 3
	var row := frame / 3
	_player_sprite.region_rect = Rect2(
		Vector2(column, row) * PLAYER_FRAME_SIZE,
		PLAYER_FRAME_SIZE
	)
	_player_sprite.position.y = (
		18.0 - (PLAYER_BASELINES[frame] - PLAYER_FRAME_SIZE.y * 0.5)
		* PLAYER_SCALE
	)


func _set_enemy_frame(target: CharacterBody2D, frame: int) -> void:
	var state: Dictionary = _enemy_states.get(target, {})
	if state.is_empty():
		return
	var sprite: Sprite2D = _enemy_sprites[target]
	sprite.region_rect = _enemy_region(bool(state["shield"]), clampi(frame, 0, 3))


func _enemy_region(shield: bool, frame: int) -> Rect2:
	return Rect2(
		Vector2(float(frame) * ENEMY_FRAME_SIZE.x, 0.0 if shield else ENEMY_FRAME_SIZE.y),
		ENEMY_FRAME_SIZE
	)


func _new_region_sprite(
	texture: Texture2D,
	region: Rect2,
	sprite_scale: Vector2
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


func _add_enemy_shadow(target: CharacterBody2D, size: Vector2) -> void:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for index: int in 24:
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle) * size.x, sin(angle) * size.y))
	shadow.polygon = points
	shadow.color = Color(0.0, 0.0, 0.0, 0.45)
	shadow.position = Vector2(0.0, -2.0)
	shadow.z_index = -1
	target.add_child(shadow)


func _is_confirm_event(event: InputEvent) -> bool:
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"attack"):
		return true
	return event is InputEventMouseButton and event.pressed


func _is_restart_event(event: InputEvent) -> bool:
	if event.is_action_pressed(&"ui_accept"):
		return true
	return (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_R
	)
