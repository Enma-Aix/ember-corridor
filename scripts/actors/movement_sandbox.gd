extends Node2D

const StateMachineModelScript := preload(
	"res://scripts/combat/state_machine_model.gd"
)
const AttackTimelineModelScript := preload(
	"res://scripts/combat/attack_timeline_model.gd"
)
const HitResolverModelScript := preload(
	"res://scripts/combat/hit_resolver_model.gd"
)
const DamagePacketScript := preload("res://scripts/combat/damage_packet.gd")
const DamageResolverModelScript := preload(
	"res://scripts/combat/damage_resolver_model.gd"
)
const CombatantModelScript := preload("res://scripts/combat/combatant_model.gd")
const PreviewAttackDefinition := preload("res://data/attacks/dev_launcher.tres")
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
@onready var timeline_status_label: Label = %TimelineStatusLabel
@onready var cancel_windows_label: Label = %CancelWindowsLabel
@onready var hit_contact_label: Label = %HitContactLabel
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
var attack_timeline: AttackTimelineModel = AttackTimelineModelScript.new()
var hit_resolver: HitResolverModel = HitResolverModelScript.new()
var damage_resolver: DamageResolverModel = DamageResolverModelScript.new()
var _attack_sequence := 0
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


func _ready() -> void:
	elevation_component = player.get_node("Elevation") as ElevationComponent
	debug_panel.visible = OS.is_debug_build()
	attack_timeline_panel.visible = OS.is_debug_build()
	GameLog.info(&"MovementSandbox", "MOV-001 sandbox ready")
	GameLog.info(&"ElevationSandbox", "MOV-002 sandbox ready")
	GameLog.info(&"DodgeSandbox", "MOV-003 sandbox ready")
	_verify_state_machine_core()
	_configure_attack_timeline_preview()
	_configure_hit_detection_preview()
	_configure_damage_preview()
	_configure_combatant_preview()


func _physics_process(_delta: float) -> void:
	_advance_combatant_preview()
	_sync_player_hurtbox()
	if Input.is_action_just_pressed(&"attack") and not attack_timeline.is_running:
		var start_errors := attack_timeline.start(attack_definition)
		for message: String in start_errors:
			push_error("[CMB-002] %s" % message)
		if start_errors.is_empty():
			_start_attack_hitbox()
	if attack_timeline.is_running:
		attack_timeline.advance_tick()
		_sync_attack_hitbox()
	elif player_hitbox.is_active:
		player_hitbox.deactivate()
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
		+ "Dodge direction: (%.2f, %.2f)"
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
	]


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


func _configure_attack_timeline_preview() -> void:
	attack_definition = PreviewAttackDefinition as AttackDefinition
	if attack_definition == null:
		push_error("[CMB-002] preview AttackDefinition could not be loaded")
		return
	var validation_errors := attack_definition.validation_errors()
	if not validation_errors.is_empty():
		for message: String in validation_errors:
			push_error("[CMB-002] %s" % message)
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
	_update_attack_timeline_preview()
	GameLog.info(&"AttackTimelineSandbox", "CMB-002 timeline ready")


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
		player.facing_sign(),
		elevation_component.elevation()
	)
	for message: String in hitbox_errors:
		push_error("[CMB-003] %s" % message)
	if not hitbox_errors.is_empty():
		attack_timeline.reset()


func _sync_attack_hitbox() -> void:
	if not player_hitbox.is_active:
		return
	player_hitbox.set_facing_sign(player.facing_sign())
	player_hitbox.set_action_tick(attack_timeline.action_tick)
	player_hitbox.set_contact_enabled(attack_timeline.is_hitbox_active())


func _sync_player_hurtbox() -> void:
	var height_range := elevation_component.hit_height_range()
	player_hurtbox.set_hit_height_range(height_range.x, height_range.y)
	player_hurtbox.set_invulnerable(player.is_dodge_invulnerable())


func _on_hit_accepted(contact: HitContact) -> void:
	_accepted_contact_count += 1
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
		Vector2(float(player.facing_sign()), 0.0)
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


func _phase_segment_label(title: String, tick_range: Vector2i) -> String:
	if tick_range == Vector2i.ZERO:
		return "%s\nnone" % title
	return "%s\n%d-%d" % [title, tick_range.x, tick_range.y]


func _update_attack_timeline_preview() -> void:
	if attack_definition == null or not attack_timeline_panel.visible:
		return
	if attack_timeline.total_ticks() == 0:
		timeline_status_label.text = (
			"Preview: idle · press J / XInput X · total %d tick"
			% attack_definition.total_ticks()
		)
		_set_timeline_highlight(AttackDefinition.TimelinePhase.BEFORE_START)
		return
	var cancel_targets := attack_timeline.available_cancel_targets()
	var cancel_text := "none" if cancel_targets.is_empty() else ", ".join(cancel_targets)
	timeline_status_label.text = (
		"Preview: tick %d/%d · %s · hitbox %s · cancel %s"
		% [
			attack_timeline.action_tick,
			attack_timeline.total_ticks(),
			String(attack_timeline.current_phase_name()),
			"on" if attack_timeline.is_hitbox_active() else "off",
			cancel_text,
		]
	)
	_set_timeline_highlight(attack_timeline.current_phase)


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
