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
const PreviewAttackDefinition := preload("res://data/attacks/dev_a1.tres")

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
var _attack_sequence := 0
var _current_hit_id: StringName = &""
var _accepted_contact_count := 0
var _duplicate_contact_count := 0


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


func _physics_process(_delta: float) -> void:
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


func _on_hit_accepted(_contact: HitContact) -> void:
	_accepted_contact_count += 1
	_update_hit_contact_label()


func _on_hit_rejected(_contact: HitContact, reason_code: StringName) -> void:
	if reason_code == HitResolverModel.REJECTION_DUPLICATE_HIT:
		_duplicate_contact_count += 1
	_update_hit_contact_label()


func _update_hit_contact_label() -> void:
	var display_hit_id := "idle" if _current_hit_id == &"" else String(_current_hit_id)
	hit_contact_label.text = (
		"Contacts: %d accepted · %d duplicate blocked · hit_id %s"
		% [_accepted_contact_count, _duplicate_contact_count, display_hit_id]
	)


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
