extends Node2D

const StateMachineModelScript := preload(
	"res://scripts/combat/state_machine_model.gd"
)
const InputBufferModelScript := preload(
	"res://scripts/combat/input_buffer_model.gd"
)
const NormalAttackComboModelScript := preload(
	"res://scripts/combat/normal_attack_combo_model.gd"
)
const LinebreakerSkillModelScript := preload(
	"res://scripts/combat/linebreaker_skill_model.gd"
)
const HitResolverModelScript := preload(
	"res://scripts/combat/hit_resolver_model.gd"
)
const DamagePacketScript := preload("res://scripts/combat/damage_packet.gd")
const DamageResolverModelScript := preload(
	"res://scripts/combat/damage_resolver_model.gd"
)
const HitFeedbackRequestScript := preload(
	"res://scripts/combat/hit_feedback_request.gd"
)
const CombatantModelScript := preload("res://scripts/combat/combatant_model.gd")
const PreviewAttackA1 := preload("res://data/attacks/dev_a1.tres")
const PreviewAttackA2 := preload("res://data/attacks/dev_a2.tres")
const PreviewAttackA3 := preload("res://data/attacks/dev_a3.tres")
const PreviewLinebreakerSkill := preload(
	"res://data/skills/bladebound_linebreaker.tres"
)
const PreviewNormalReactionProfile := preload(
	"res://data/combat/reaction_profiles/normal.tres"
)
const PreviewEliteReactionProfile := preload(
	"res://data/combat/reaction_profiles/elite.tres"
)
const PreviewBossReactionProfile := preload(
	"res://data/combat/reaction_profiles/boss.tres"
)
const PreviewLauncherProfile := preload(
	"res://data/combat/launch_profiles/dev_launcher.tres"
)
const PreviewGroundPursuitProfile := preload(
	"res://data/combat/launch_profiles/dev_ground_pursuit.tres"
)
const PreviewLightFeedbackProfile := preload(
	"res://data/combat/feedback_profiles/light.tres"
)
const PreviewMediumFeedbackProfile := preload(
	"res://data/combat/feedback_profiles/medium.tres"
)
const PreviewHeavyFeedbackProfile := preload(
	"res://data/combat/feedback_profiles/heavy.tres"
)
const PreviewFinisherFeedbackProfile := preload(
	"res://data/combat/feedback_profiles/finisher.tres"
)

const PREVIEW_BASE_ATTACK := 100.0
const PREVIEW_CRIT_CHANCE := 0.05
const PREVIEW_CRIT_MULTIPLIER := 1.5
const PREVIEW_CRITICAL_ROLL := 0.5
const DUMMY_A_DEFENSE := 25.0
const DUMMY_B_DEFENSE := 100.0
const DUMMY_MAXIMUM_HEALTH := 300
const DUMMY_A_MAXIMUM_POISE := 24.0
const DUMMY_B_MAXIMUM_POISE := 12.0
const DUMMY_MINIMUM_HIT_HEIGHT := 0.0
const DUMMY_MAXIMUM_HIT_HEIGHT := 56.0

@onready var player: PlayerGroundMovementController = %PlayerRoot
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var movement_label: Label = %MovementLabel
@onready var attack_timeline_panel: PanelContainer = %AttackTimelinePanel
@onready var startup_segment: PanelContainer = %StartupSegment
@onready var startup_label: Label = %StartupLabel
@onready var active_segment: PanelContainer = %ActiveSegment
@onready var active_label: Label = %ActiveLabel
@onready var recovery_segment: PanelContainer = %RecoverySegment
@onready var recovery_label: Label = %RecoveryLabel
@onready var timeline_title: Label = %TimelineTitle
@onready var timeline_status_label: Label = %TimelineStatusLabel
@onready var cancel_windows_label: Label = %CancelWindowsLabel
@onready var input_buffer_label: Label = %InputBufferLabel
@onready var hit_contact_label: Label = %HitContactLabel
@onready var feedback_status_label: Label = %FeedbackStatusLabel
@onready var hit_feedback_service: HitFeedbackService = %HitFeedbackService
@onready var hit_feedback_presenter: HitFeedbackPresenter = %HitFeedbackPresenter
@onready var player_visual_root: Node2D = player.get_node("VisualRoot") as Node2D
@onready var player_body: Polygon2D = player.get_node("VisualRoot/Body") as Polygon2D
@onready var attack_trail: Polygon2D = (
	player.get_node("VisualRoot/AttackTrail") as Polygon2D
)
@onready var player_hurtbox: HurtboxComponent = (
	player.get_node("Hurtbox") as HurtboxComponent
)
@onready var player_hitbox: HitboxComponent = (
	player.get_node("HitboxContainer/DevA1Hitbox") as HitboxComponent
)
@onready var dummy_a_hurtbox: HurtboxComponent = %DummyAHurtbox
@onready var dummy_b_hurtbox: HurtboxComponent = %DummyBHurtbox

var elevation_component: ElevationComponent
var attack_definition: AttackDefinition
var input_buffer: InputBufferModel = InputBufferModelScript.new()
var normal_attack_combo: NormalAttackComboModel = NormalAttackComboModelScript.new()
var linebreaker_skill: LinebreakerSkillModel = LinebreakerSkillModelScript.new()
var attack_timeline: AttackTimelineModel
var hit_resolver: HitResolverModel = HitResolverModelScript.new()
var damage_resolver: DamageResolverModel = DamageResolverModelScript.new()
var _attack_sequence := 0
var _attack_facing_sign := 1
var _current_hit_id: StringName = &""
var _accepted_contact_count := 0
var _duplicate_contact_count := 0
var _control_rejection_count := 0
var _resolved_damage_count := 0
var _total_preview_damage := 0
var _minimum_preview_damage := 0
var _maximum_preview_damage := 0
var _critical_preview_count := 0
var _combatants: Dictionary[int, CombatantModel] = {}
var _launch_profiles: Dictionary[StringName, CombatLaunchProfile] = {}
var _dummy_visual_base_y: Dictionary[int, float] = {}
var _current_normal_attack_hit := false


func _ready() -> void:
	elevation_component = player.get_node("Elevation") as ElevationComponent
	debug_panel.visible = OS.is_debug_build()
	attack_timeline_panel.visible = OS.is_debug_build()
	feedback_status_label.visible = OS.is_debug_build()
	GameLog.info(&"MovementSandbox", "MOV-001 sandbox ready")
	GameLog.info(&"ElevationSandbox", "MOV-002 sandbox ready")
	GameLog.info(&"DodgeSandbox", "MOV-003 sandbox ready")
	_verify_state_machine_core()
	_configure_normal_attack_combo()
	_configure_linebreaker_skill()
	_configure_attack_timeline_preview()
	_configure_hit_detection_preview()
	_configure_damage_preview()
	_configure_hit_feedback_preview()
	_configure_combatant_preview()


func _physics_process(_delta: float) -> void:
	_advance_combatant_preview()
	_sync_player_hurtbox()
	input_buffer.advance_tick()
	if Input.is_action_just_pressed(&"attack"):
		input_buffer.record_pressed(&"attack")
	if Input.is_action_just_released(&"attack"):
		input_buffer.record_released(&"attack")
	if Input.is_action_just_pressed(&"skill_1"):
		input_buffer.record_pressed(&"skill_1")
	if Input.is_action_just_released(&"skill_1"):
		input_buffer.record_released(&"skill_1")
	if linebreaker_skill.is_active() and Input.is_action_just_pressed(&"dodge"):
		input_buffer.record_pressed(&"dodge")
	if linebreaker_skill.is_active() and Input.is_action_just_released(&"dodge"):
		input_buffer.record_released(&"dodge")

	if linebreaker_skill.is_active():
		var skill_displacement := linebreaker_skill.advance_tick(input_buffer)
		if not player.queue_action_displacement(skill_displacement):
			push_error("[CMB-009] linebreaker produced invalid displacement")
		_resolve_linebreaker_cancel()
	else:
		normal_attack_combo.advance_tick(input_buffer, not player.is_dodging())
		_try_start_linebreaker_from_buffer()
	if attack_timeline != null and attack_timeline.is_running:
		_sync_attack_hitbox()
	elif player_hitbox.is_active:
		player_hitbox.deactivate()
	_sync_attack_visual()
	_update_attack_timeline_preview()


func _process(_delta: float) -> void:
	if not debug_panel.visible:
		return
	var facing_label := "right" if player.facing_sign() > 0 else "left"
	var hit_range := elevation_component.hit_height_range()
	var low_probe_overlap := elevation_component.overlaps_height_range(0.0, 24.0)
	var debug_text := (
		"Ground: (%.1f, %.1f)\n"
		+ "Move velocity: (%.1f, %.1f)\n"
		+ "Facing: %s\n"
		+ "Elevation: %.1f\n"
		+ "Vertical velocity: %.1f\n"
		+ "Grounded: %s\n"
		+ "Hit height: %.1f - %.1f\n"
		+ "Low probe 0-24: %s\n"
		+ "Dodge: %s · tick %d\n"
		+ "Invulnerable: %s\n"
		+ "Dodge cooldown: %d\n"
		+ "Dodge direction: (%.2f, %.2f)\n"
		+ "Linebreaker: %s"
	)
	movement_label.text = debug_text % [
		player.global_position.x,
		player.global_position.y,
		player.velocity.x,
		player.velocity.y,
		facing_label,
		elevation_component.elevation(),
		elevation_component.vertical_velocity(),
		str(elevation_component.is_grounded()),
		hit_range.x,
		hit_range.y,
		"overlap" if low_probe_overlap else "clear",
		"active" if player.is_dodging() else "idle",
		player.dodge_tick(),
		str(player.is_dodge_invulnerable()),
		player.dodge_cooldown_ticks(),
		player.dodge_direction().x,
		player.dodge_direction().y,
		(
			"tick %d" % linebreaker_skill.timeline.action_tick
			if linebreaker_skill.is_active()
			else "idle"
		),
	]
	_update_feedback_status_label()


func _verify_state_machine_core() -> void:
	var state_machine: StateMachineModel = StateMachineModelScript.new()
	var configuration_errors := state_machine.configure(
		&"Idle",
		{
			&"Idle": PackedStringArray(["Move"]),
			&"Move": PackedStringArray(["Idle"]),
		}
	)
	if not configuration_errors.is_empty():
		for message: String in configuration_errors:
			push_error("[CMB-001] %s" % message)
		return
	GameLog.info(&"StateMachineSandbox", "CMB-001 core ready")


func _configure_normal_attack_combo() -> void:
	var buffer_errors := input_buffer.configure(InputBufferModel.DEFAULT_BUFFER_TICKS)
	for message: String in buffer_errors:
		push_error("[CMB-007] %s" % message)
	var attack_sequence: Array[AttackDefinition] = [
		PreviewAttackA1 as AttackDefinition,
		PreviewAttackA2 as AttackDefinition,
		PreviewAttackA3 as AttackDefinition,
	]
	var combo_errors := normal_attack_combo.configure(attack_sequence)
	for message: String in combo_errors:
		push_error("[CMB-008] %s" % message)
	if not buffer_errors.is_empty() or not combo_errors.is_empty():
		set_physics_process(false)
		return
	normal_attack_combo.attack_started.connect(_on_normal_attack_started)
	normal_attack_combo.attack_finished.connect(_on_normal_attack_finished)
	normal_attack_combo.attack_start_rejected.connect(_on_normal_attack_start_rejected)
	attack_timeline = normal_attack_combo.timeline
	attack_definition = normal_attack_combo.sequence_attack(0)
	GameLog.info(&"InputBufferSandbox", "CMB-007 input buffer ready")
	GameLog.info(&"NormalComboSandbox", "CMB-008 three-hit combo ready")


func _configure_linebreaker_skill() -> void:
	var source_skill := PreviewLinebreakerSkill as SkillDefinition
	if source_skill == null:
		push_error("[CMB-009] linebreaker SkillDefinition could not be loaded")
		set_physics_process(false)
		return
	var configuration_errors := linebreaker_skill.configure(source_skill)
	for message: String in configuration_errors:
		push_error("[CMB-009] %s" % message)
	if not configuration_errors.is_empty():
		set_physics_process(false)
		return
	linebreaker_skill.skill_started.connect(_on_linebreaker_started)
	linebreaker_skill.skill_finished.connect(_on_linebreaker_finished)
	linebreaker_skill.skill_start_rejected.connect(_on_linebreaker_start_rejected)
	GameLog.info(&"LinebreakerSandbox", "CMB-009 linebreaker ready")


func _configure_attack_timeline_preview() -> void:
	if attack_definition == null:
		push_error("[CMB-002] preview AttackDefinition could not be loaded")
		return
	var validation_errors := attack_definition.validation_errors()
	if not validation_errors.is_empty():
		for message: String in validation_errors:
			push_error("[CMB-002] %s" % message)
		return

	_render_attack_definition_preview()
	_update_attack_timeline_preview()
	GameLog.info(&"AttackTimelineSandbox", "CMB-002 timeline ready")


func _render_attack_definition_preview() -> void:
	if attack_definition == null:
		return
	const PIXELS_PER_TICK := 18.0
	startup_segment.custom_minimum_size.x = (
		float(attack_definition.startup_ticks) * PIXELS_PER_TICK
	)
	active_segment.custom_minimum_size.x = (
		float(attack_definition.active_ticks) * PIXELS_PER_TICK
	)
	recovery_segment.custom_minimum_size.x = (
		float(attack_definition.recovery_ticks) * PIXELS_PER_TICK
	)
	startup_label.text = _phase_segment_label(
		"Startup",
		attack_definition.phase_tick_range(AttackDefinition.TimelinePhase.STARTUP)
	)
	active_label.text = _phase_segment_label(
		"Active",
		attack_definition.phase_tick_range(AttackDefinition.TimelinePhase.ACTIVE)
	)
	recovery_label.text = _phase_segment_label(
		"Recovery",
		attack_definition.phase_tick_range(AttackDefinition.TimelinePhase.RECOVERY)
	)
	var cancel_summaries := PackedStringArray()
	for cancel_window: AttackCancelWindow in attack_definition.cancel_windows:
		cancel_summaries.append(
			"tick %d-%d → %s"
			% [
				cancel_window.start_tick,
				cancel_window.end_tick,
				", ".join(PackedStringArray(cancel_window.target_tags)),
			]
		)
	cancel_windows_label.text = "Cancel: %s" % " · ".join(cancel_summaries)
	if linebreaker_skill.is_active():
		timeline_title.text = (
			"CMB-009 · 破线突 · %s"
			% String(attack_definition.definition_id)
		)
		return
	var display_index := normal_attack_combo.combo_index + 1
	if display_index < 1:
		display_index = _sequence_index_for_attack(attack_definition) + 1
	timeline_title.text = (
		"CMB-008 · A%d · %s"
		% [display_index, String(attack_definition.definition_id)]
	)


func _configure_hit_detection_preview() -> void:
	player_hurtbox.bind_resolver(hit_resolver)
	dummy_a_hurtbox.bind_resolver(hit_resolver)
	dummy_b_hurtbox.bind_resolver(hit_resolver)
	hit_resolver.hit_accepted.connect(_on_hit_accepted)
	hit_resolver.hit_rejected.connect(_on_hit_rejected)
	_sync_player_hurtbox()
	_update_hit_contact_label()
	GameLog.info(&"HitboxSandbox", "CMB-003 hit detection ready")


func _configure_damage_preview() -> void:
	var packet := _build_preview_damage_packet()
	if packet == null:
		push_error("[CMB-004] preview DamagePacket could not be created")
		return
	var packet_errors := packet.validation_errors()
	if not packet_errors.is_empty():
		for message: String in packet_errors:
			push_error("[CMB-004] %s" % message)
		return
	var result := damage_resolver.resolve(packet, DUMMY_A_DEFENSE)
	if not result.accepted or result.final_damage != 88:
		push_error("[CMB-004] preview formula baseline did not resolve to 88")
		return
	GameLog.info(&"DamageSandbox", "CMB-004 formula ready")


func _configure_hit_feedback_preview() -> void:
	var profiles: Array[HitFeedbackProfile] = [
		PreviewLightFeedbackProfile as HitFeedbackProfile,
		PreviewMediumFeedbackProfile as HitFeedbackProfile,
		PreviewHeavyFeedbackProfile as HitFeedbackProfile,
		PreviewFinisherFeedbackProfile as HitFeedbackProfile,
	]
	var errors := hit_feedback_service.configure(profiles)
	errors.append_array(hit_feedback_presenter.bind_service(hit_feedback_service))
	for message: String in errors:
		push_error("[CMB-010] %s" % message)
	if not errors.is_empty():
		set_physics_process(false)
		return
	_update_feedback_status_label()
	GameLog.info(&"HitFeedbackSandbox", "CMB-010 feedback service ready")


func _configure_combatant_preview() -> void:
	var normal_profile := PreviewNormalReactionProfile as CombatReactionProfile
	var elite_profile := PreviewEliteReactionProfile as CombatReactionProfile
	var boss_profile := PreviewBossReactionProfile as CombatReactionProfile
	if normal_profile == null or elite_profile == null or boss_profile == null:
		push_error("[CMB-005] preview reaction profiles could not be loaded")
		return

	var normal_combatant: CombatantModel = CombatantModelScript.new()
	var normal_errors := normal_combatant.configure(
		dummy_a_hurtbox.combatant_instance_id,
		&"enemy",
		DUMMY_MAXIMUM_HEALTH,
		DUMMY_A_MAXIMUM_POISE,
		DUMMY_A_DEFENSE,
		normal_profile
	)
	var elite_combatant: CombatantModel = CombatantModelScript.new()
	var elite_errors := elite_combatant.configure(
		dummy_b_hurtbox.combatant_instance_id,
		&"enemy",
		DUMMY_MAXIMUM_HEALTH,
		DUMMY_B_MAXIMUM_POISE,
		DUMMY_B_DEFENSE,
		elite_profile
	)
	var boss_contract: CombatantModel = CombatantModelScript.new()
	var boss_errors := boss_contract.configure(
		999_005,
		&"enemy",
		1000,
		36.0,
		150.0,
		boss_profile
	)
	for message: String in normal_errors:
		push_error("[CMB-005] normal preview: %s" % message)
	for message: String in elite_errors:
		push_error("[CMB-005] elite preview: %s" % message)
	for message: String in boss_errors:
		push_error("[CMB-005] boss contract: %s" % message)
	if (
		not normal_errors.is_empty()
		or not elite_errors.is_empty()
		or not boss_errors.is_empty()
	):
		return
	if (
		normal_combatant.reaction_strategy != &"normal"
		or elite_combatant.reaction_strategy != &"elite"
		or boss_contract.reaction_strategy != &"boss"
	):
		push_error("[CMB-005] reaction profiles did not preserve their strategies")
		return
	if (
		not normal_combatant.can_be_launched
		or elite_combatant.can_be_launched
		or boss_contract.can_be_launched
	):
		push_error("[CMB-006] reaction profiles do not preserve launch immunity")
		return
	_combatants[normal_combatant.instance_id] = normal_combatant
	_combatants[elite_combatant.instance_id] = elite_combatant
	if not _configure_launch_profiles():
		return
	_capture_dummy_visual(normal_combatant.instance_id, dummy_a_hurtbox)
	_capture_dummy_visual(elite_combatant.instance_id, dummy_b_hurtbox)
	_sync_combatant_presentation()
	_update_hit_contact_label()
	GameLog.info(&"CombatantSandbox", "CMB-005 combatant reactions ready")
	GameLog.info(&"JuggleSandbox", "CMB-006 airborne control ready")


func _start_attack_hitbox() -> void:
	if player_hitbox.is_active:
		player_hitbox.deactivate()
	_attack_sequence += 1
	_current_hit_id = StringName(
		"%d:%s:%d"
		% [player.get_instance_id(), String(attack_definition.definition_id), _attack_sequence]
	)
	var hitbox_errors := player_hitbox.activate(
		attack_definition,
		_current_hit_id,
		player.get_instance_id(),
		&"player",
		_attack_facing_sign,
		elevation_component.elevation()
	)
	for message: String in hitbox_errors:
		push_error("[CMB-003] %s" % message)
	if not hitbox_errors.is_empty():
		_rollback_failed_attack_start()


func _rollback_failed_attack_start() -> void:
	if player_hitbox.is_active:
		player_hitbox.deactivate()
	if linebreaker_skill.is_active():
		linebreaker_skill.reset()
		player.end_action_motion()
	else:
		normal_attack_combo.reset()
	_current_normal_attack_hit = false
	player.set_facing_locked(false)
	attack_timeline = normal_attack_combo.timeline
	attack_definition = normal_attack_combo.sequence_attack(0)
	_render_attack_definition_preview()


func _sync_attack_hitbox() -> void:
	if not player_hitbox.is_active:
		return
	player_hitbox.set_facing_sign(_attack_facing_sign)
	player_hitbox.set_action_tick(attack_timeline.action_tick)
	player_hitbox.set_contact_enabled(attack_timeline.is_hitbox_active())


func _sync_player_hurtbox() -> void:
	var height_range := elevation_component.hit_height_range()
	player_hurtbox.set_hit_height_range(height_range.x, height_range.y)
	player_hurtbox.set_invulnerable(player.is_dodge_invulnerable())


func _on_normal_attack_started(
	new_attack: AttackDefinition,
	_combo_index: int
) -> void:
	attack_definition = new_attack
	attack_timeline = normal_attack_combo.timeline
	_attack_facing_sign = player.facing_sign()
	_current_normal_attack_hit = false
	player.set_facing_locked(true)
	_render_attack_definition_preview()
	_start_attack_hitbox()


func _on_normal_attack_finished(
	_attack_id: StringName,
	_combo_index: int,
	_reason: StringName
) -> void:
	if player_hitbox.is_active:
		player_hitbox.deactivate()
	_current_normal_attack_hit = false
	player.set_facing_locked(false)


func _on_normal_attack_start_rejected(errors: PackedStringArray) -> void:
	for message: String in errors:
		push_error("[CMB-008] %s" % message)


func _try_start_linebreaker_from_buffer() -> void:
	if (
		linebreaker_skill.is_active()
		or player.is_dodging()
		or not elevation_component.is_grounded()
		or not input_buffer.has_buffered_press(&"skill_1")
	):
		return
	if normal_attack_combo.timeline.is_running:
		if (
			not _current_normal_attack_hit
			or not normal_attack_combo.can_cancel_to(&"action.skill_1")
		):
			return
		if not input_buffer.consume(&"skill_1"):
			return
		if not normal_attack_combo.cancel_to(&"action.skill_1"):
			push_error("[CMB-009] declared normal-to-skill cancel was rejected")
			return
	elif not input_buffer.consume(&"skill_1"):
		return
	if not linebreaker_skill.try_start(player.facing_sign()):
		push_error("[CMB-009] buffered linebreaker start was rejected")


func _resolve_linebreaker_cancel() -> void:
	if linebreaker_skill.last_finish_reason != LinebreakerSkillModel.FINISH_CANCELED:
		return
	match linebreaker_skill.last_cancel_target:
		&"action.attack":
			if not normal_attack_combo.start_first_attack_immediately():
				push_error("[CMB-009] linebreaker could not cancel into A1")
		&"action.dodge":
			if not player.try_start_dodge(Vector2.ZERO):
				push_error("[CMB-009] linebreaker could not cancel into dodge")
		_:
			push_error(
				"[CMB-009] unsupported cancel target: %s"
				% String(linebreaker_skill.last_cancel_target)
			)


func _on_linebreaker_started(
	_skill_id: StringName,
	new_attack: AttackDefinition
) -> void:
	var movement_profile := linebreaker_skill.movement_profile
	if (
		movement_profile == null
		or not player.begin_action_motion(movement_profile.blocking_collision_mask)
	):
		push_error("[CMB-009] player could not enter linebreaker motion")
		linebreaker_skill.reset()
		return
	attack_definition = new_attack
	attack_timeline = linebreaker_skill.timeline
	_attack_facing_sign = player.facing_sign()
	_current_normal_attack_hit = false
	player.set_facing_locked(true)
	_render_attack_definition_preview()
	_start_attack_hitbox()


func _on_linebreaker_finished(
	_skill_id: StringName,
	_reason: StringName,
	_cancel_target: StringName
) -> void:
	if player_hitbox.is_active:
		player_hitbox.deactivate()
	player.end_action_motion()
	player.set_facing_locked(false)
	attack_timeline = normal_attack_combo.timeline
	attack_definition = normal_attack_combo.sequence_attack(0)
	_render_attack_definition_preview()


func _on_linebreaker_start_rejected(errors: PackedStringArray) -> void:
	for message: String in errors:
		push_error("[CMB-009] %s" % message)


func _on_hit_accepted(contact: HitContact) -> void:
	_accepted_contact_count += 1
	if normal_attack_combo.timeline.is_running:
		_current_normal_attack_hit = true
	var target: CombatantModel = _combatants.get(contact.target_instance_id)
	if target == null or not target.can_receive_hit():
		push_error("[CMB-005] accepted contact has no available target combatant")
		_update_hit_contact_label()
		return
	var packet := _build_preview_damage_packet()
	if packet == null:
		push_error("[CMB-004] accepted contact could not create a DamagePacket")
		_update_hit_contact_label()
		return
	var result := damage_resolver.resolve(packet, target.defense)
	if not result.accepted:
		push_error("[CMB-004] damage resolution rejected: %s" % result.rejection_code)
		_update_hit_contact_label()
		return
	var launch_profile := _launch_profile_for_packet(packet)
	var applied_result := target.apply_damage(packet, result, launch_profile)
	if not applied_result.accepted:
		if applied_result.rejection_code in [
			CombatantModel.REJECTION_TARGET_KNOCKDOWN_PROTECTED,
			CombatantModel.REJECTION_GROUND_PURSUIT_LIMIT,
		]:
			_control_rejection_count += 1
			_update_hit_contact_label()
			return
		push_error(
			"[CMB-005/006] combatant application rejected: %s"
			% applied_result.rejection_code
		)
		_update_hit_contact_label()
		return
	_request_hit_feedback(contact, packet, applied_result, target)
	_resolved_damage_count += 1
	_total_preview_damage += applied_result.final_damage
	if _resolved_damage_count == 1:
		_minimum_preview_damage = applied_result.final_damage
		_maximum_preview_damage = applied_result.final_damage
	else:
		_minimum_preview_damage = mini(_minimum_preview_damage, applied_result.final_damage)
		_maximum_preview_damage = maxi(_maximum_preview_damage, applied_result.final_damage)
	if applied_result.critical:
		_critical_preview_count += 1
	if target.is_defeated:
		var target_hurtbox := _target_hurtbox(contact.target_instance_id)
		if target_hurtbox != null:
			target_hurtbox.set_accepting_hits(false)
	_update_hit_contact_label()


func _request_hit_feedback(
	contact: HitContact,
	packet: DamagePacket,
	result: HitResult,
	target: CombatantModel
) -> void:
	var target_hurtbox := _target_hurtbox(contact.target_instance_id)
	if target_hurtbox == null:
		push_error("[CMB-010] accepted feedback has no target Hurtbox")
		return
	var target_root := target_hurtbox.get_parent() as Node2D
	if target_root == null:
		push_error("[CMB-010] target Hurtbox parent is not a Node2D")
		return
	var impact_position := (
		target_root.global_position
		+ Vector2(0.0, -22.0 - target.elevation)
	)
	var request: HitFeedbackRequest = HitFeedbackRequestScript.from_outcome(
		contact,
		result,
		impact_position,
		packet.direction
	)
	var errors := hit_feedback_service.request_feedback(request)
	for message: String in errors:
		push_error("[CMB-010] %s" % message)


func _on_hit_rejected(_contact: HitContact, reason_code: StringName) -> void:
	if reason_code == HitResolverModel.REJECTION_DUPLICATE_HIT:
		_duplicate_contact_count += 1
	_update_hit_contact_label()


func _update_hit_contact_label() -> void:
	var display_hit_id := "idle" if _current_hit_id == &"" else String(_current_hit_id)
	hit_contact_label.text = (
		"Contacts: %d accepted · %d duplicate blocked · %d control blocked · hit_id %s\n"
		+ "Damage: %d resolved · total %d · range %d-%d · crit %d\n"
		+ "%s"
	) % [
		_accepted_contact_count,
		_duplicate_contact_count,
		_control_rejection_count,
		display_hit_id,
		_resolved_damage_count,
		_total_preview_damage,
		_minimum_preview_damage,
		_maximum_preview_damage,
		_critical_preview_count,
		_combatant_preview_summary(),
	]


func _build_preview_damage_packet() -> DamagePacket:
	return DamagePacketScript.from_attack(
		player.get_instance_id(),
		attack_definition,
		PREVIEW_BASE_ATTACK,
		PREVIEW_CRIT_CHANCE,
		PREVIEW_CRIT_MULTIPLIER,
		PREVIEW_CRITICAL_ROLL,
		Vector2(float(_attack_facing_sign), 0.0)
	)


func _advance_combatant_preview() -> void:
	for combatant: CombatantModel in _combatants.values():
		combatant.advance_tick()
	if not _combatants.is_empty():
		_sync_combatant_presentation()
		_update_hit_contact_label()


func _configure_launch_profiles() -> bool:
	for source: Resource in [PreviewLauncherProfile, PreviewGroundPursuitProfile]:
		var profile := source as CombatLaunchProfile
		if profile == null:
			push_error("[CMB-006] preview launch profile could not be loaded")
			return false
		var errors := profile.validation_errors()
		if not errors.is_empty():
			for message: String in errors:
				push_error("[CMB-006] launch profile: %s" % message)
			return false
		_launch_profiles[profile.definition_id] = profile
	return true


func _launch_profile_for_packet(packet: DamagePacket) -> CombatLaunchProfile:
	if packet == null or packet.launch_profile == &"none":
		return null
	return _launch_profiles.get(packet.launch_profile) as CombatLaunchProfile


func _capture_dummy_visual(target_instance_id: int, hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	var target_root := hurtbox.get_parent() as Node2D
	var body := target_root.get_node_or_null("Body") as Node2D
	if body != null:
		_dummy_visual_base_y[target_instance_id] = body.position.y


func _sync_combatant_presentation() -> void:
	for target_instance_id: int in _combatants:
		var combatant: CombatantModel = _combatants[target_instance_id]
		var hurtbox := _target_hurtbox(target_instance_id)
		if hurtbox == null:
			continue
		var height_range := combatant.hit_height_range(
			DUMMY_MINIMUM_HIT_HEIGHT,
			DUMMY_MAXIMUM_HIT_HEIGHT
		)
		hurtbox.set_hit_height_range(height_range.x, height_range.y)
		var target_root := hurtbox.get_parent() as Node2D
		var body := target_root.get_node_or_null("Body") as Node2D
		if body != null and _dummy_visual_base_y.has(target_instance_id):
			body.position.y = (
				_dummy_visual_base_y[target_instance_id] - combatant.elevation
			)


func _target_hurtbox(target_instance_id: int) -> HurtboxComponent:
	if target_instance_id == dummy_a_hurtbox.combatant_instance_id:
		return dummy_a_hurtbox
	if target_instance_id == dummy_b_hurtbox.combatant_instance_id:
		return dummy_b_hurtbox
	return null


func _combatant_preview_summary() -> String:
	var normal: CombatantModel = _combatants.get(dummy_a_hurtbox.combatant_instance_id)
	var elite: CombatantModel = _combatants.get(dummy_b_hurtbox.combatant_instance_id)
	if normal == null or elite == null:
		return "Targets: awaiting CMB-005/006 setup"
	return (
		"Targets: Normal HP %d/%d · Poise %.1f/%.1f · %s · Air %.1f · JR %.1f | "
		+ "Elite HP %d/%d · Poise %.1f/%.1f · %s · Air %.1f · JR %.1f"
	) % [
		normal.current_health,
		normal.maximum_health,
		normal.current_poise,
		normal.maximum_poise,
		String(normal.reaction_type),
		normal.elevation,
		normal.juggle_resistance,
		elite.current_health,
		elite.maximum_health,
		elite.current_poise,
		elite.maximum_poise,
		String(elite.reaction_type),
		elite.elevation,
		elite.juggle_resistance,
	]


func _update_feedback_status_label() -> void:
	if feedback_status_label == null or not feedback_status_label.visible:
		return
	var sfx_label := (
		"idle"
		if hit_feedback_presenter.last_sfx_cue == &""
		else "%s × %d"
		% [
			String(hit_feedback_presenter.last_sfx_cue),
			hit_feedback_presenter.last_sfx_layer_count,
		]
	)
	feedback_status_label.text = (
		"CMB-010 Feedback · requests %d\n"
		+ "Hit Stop: %d tick remaining\n"
		+ "Camera: %.1f px · %d tick · zoom %.1f%%\n"
		+ "VFX: %d total · %d active\n"
		+ "SFX: %d total · %s"
	) % [
		hit_feedback_service.request_count,
		hit_feedback_service.hit_stop_ticks_remaining,
		hit_feedback_service.camera_shake_pixels,
		hit_feedback_service.camera_ticks_remaining,
		hit_feedback_service.camera_zoom_pulse * 100.0,
		hit_feedback_presenter.vfx_request_count,
		hit_feedback_presenter.active_vfx_count,
		hit_feedback_presenter.sfx_request_count,
		sfx_label,
	]


func _phase_segment_label(title: String, tick_range: Vector2i) -> String:
	if tick_range == Vector2i.ZERO:
		return "%s\nnone" % title
	return "%s\n%d-%d" % [title, tick_range.x, tick_range.y]


func _sequence_index_for_attack(definition: AttackDefinition) -> int:
	if definition == null:
		return 0
	for index: int in normal_attack_combo.sequence_size():
		var candidate := normal_attack_combo.sequence_attack(index)
		if candidate != null and candidate.definition_id == definition.definition_id:
			return index
	return 0


func _sync_attack_visual() -> void:
	if attack_trail == null or player_visual_root == null or player_body == null:
		return
	if attack_timeline == null or not attack_timeline.is_running:
		attack_trail.visible = false
		player_visual_root.rotation = 0.0
		player_body.self_modulate = Color.WHITE
		return
	var stage := normal_attack_combo.combo_index
	var progress := (
		float(attack_timeline.action_tick)
		/ maxf(float(attack_timeline.total_ticks()), 1.0)
	)
	attack_trail.visible = attack_timeline.is_hitbox_active()
	if linebreaker_skill.is_active():
		attack_trail.rotation = lerpf(-0.12, 0.08, progress)
		attack_trail.scale = Vector2(1.7, 0.68)
		attack_trail.color = Color(0.2, 0.9, 1.0, 0.88)
		player_visual_root.rotation = lerpf(-0.16, 0.06, progress)
		player_body.self_modulate = (
			Color(0.72, 1.18, 1.2, 1.0)
			if attack_timeline.is_hitbox_active()
			else Color(0.86, 1.06, 1.1, 1.0)
		)
		return
	match stage:
		0:
			attack_trail.rotation = lerpf(-0.6, 0.35, progress)
			attack_trail.scale = Vector2(1.0, 0.82)
			attack_trail.color = Color(1.0, 0.42, 0.08, 0.78)
			player_visual_root.rotation = lerpf(-0.08, 0.08, progress)
		1:
			attack_trail.rotation = lerpf(0.65, -0.45, progress)
			attack_trail.scale = Vector2(1.18, 1.08)
			attack_trail.color = Color(0.22, 0.82, 1.0, 0.75)
			player_visual_root.rotation = lerpf(0.12, -0.1, progress)
		2:
			attack_trail.rotation = lerpf(0.45, -1.05, progress)
			attack_trail.scale = Vector2(1.12, 1.34)
			attack_trail.color = Color(1.0, 0.72, 0.2, 0.9)
			player_visual_root.rotation = lerpf(0.16, -0.16, progress)
	player_body.self_modulate = (
		Color(1.16, 1.08, 0.94, 1.0)
		if attack_timeline.is_hitbox_active()
		else Color.WHITE
	)


func _update_attack_timeline_preview() -> void:
	if attack_definition == null or not attack_timeline_panel.visible:
		return
	if attack_timeline.total_ticks() == 0:
		timeline_status_label.text = (
			"Combo: idle · press J / XInput X · A1 total %d tick"
			% normal_attack_combo.sequence_attack(0).total_ticks()
		)
		input_buffer_label.text = "CMB-007 Buffer: empty · capacity 8 tick"
		_set_timeline_highlight(AttackDefinition.TimelinePhase.BEFORE_START)
		return
	var cancel_targets := attack_timeline.available_cancel_targets()
	var cancel_text := "none" if cancel_targets.is_empty() else ", ".join(cancel_targets)
	if linebreaker_skill.is_active():
		timeline_status_label.text = (
			"Linebreaker: tick %d/%d · %s · travel %.1f px · cancel %s"
			% [
				attack_timeline.action_tick,
				attack_timeline.total_ticks(),
				String(attack_timeline.current_phase_name()),
				linebreaker_skill.movement_profile.distance_pixels,
				cancel_text,
			]
		)
	else:
		timeline_status_label.text = (
			"Combo A%d: tick %d/%d · %s · hitbox %s · cancel %s"
			% [
				normal_attack_combo.combo_index + 1,
				attack_timeline.action_tick,
				attack_timeline.total_ticks(),
				String(attack_timeline.current_phase_name()),
				"on" if attack_timeline.is_hitbox_active() else "off",
				cancel_text,
			]
		)
	var pending_summaries := PackedStringArray()
	for action: StringName in input_buffer.pending_actions():
		pending_summaries.append(
			"%s age %d/7" % [String(action), input_buffer.input_age_ticks(action)]
		)
	input_buffer_label.text = (
		"CMB-007 Buffer: %s" % " · ".join(pending_summaries)
		if not pending_summaries.is_empty()
		else "CMB-007 Buffer: empty · capacity 8 tick"
	)
	_set_timeline_highlight(attack_timeline.current_phase)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and input_buffer != null:
		input_buffer.clear()


func _set_timeline_highlight(phase: AttackDefinition.TimelinePhase) -> void:
	startup_segment.self_modulate = (
		Color.WHITE
		if phase == AttackDefinition.TimelinePhase.STARTUP
		else Color(0.58, 0.58, 0.58, 1.0)
	)
	active_segment.self_modulate = (
		Color.WHITE
		if phase == AttackDefinition.TimelinePhase.ACTIVE
		else Color(0.58, 0.58, 0.58, 1.0)
	)
	recovery_segment.self_modulate = (
		Color.WHITE
		if phase == AttackDefinition.TimelinePhase.RECOVERY
		else Color(0.58, 0.58, 0.58, 1.0)
	)
