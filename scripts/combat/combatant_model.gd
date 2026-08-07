class_name CombatantModel
extends RefCounted

const HitResultScript := preload("res://scripts/combat/hit_result.gd")
const JuggleModelScript := preload("res://scripts/combat/juggle_model.gd")

signal health_changed(previous_health: int, current_health: int)
signal poise_changed(previous_poise: float, current_poise: float)
signal reaction_changed(previous_reaction: StringName, current_reaction: StringName)
signal poise_broken(duration_ticks: int)
signal launched(upward_velocity: float, juggle_resistance: float)
signal forced_landed(airborne_control_ticks: int)
signal knocked_down(duration_ticks: int, forced: bool)
signal knockdown_recovered
signal defeated

const TICKS_PER_SECOND := 60
const POISE_RECOVERY_DELAY_TICKS := 3 * TICKS_PER_SECOND
const POST_BREAK_PROTECTION_TICKS := 1 * TICKS_PER_SECOND

const REACTION_NONE := &"none"
const REACTION_HIT_STUN := &"hit_stun"
const REACTION_POISE_BREAK := &"poise_break"
const REACTION_AIRBORNE := &"airborne"
const REACTION_KNOCKDOWN := &"knockdown"
const REACTION_DEFEATED := &"defeated"

const REJECTION_NOT_CONFIGURED := &"target_not_configured"
const REJECTION_TARGET_DEFEATED := &"target_defeated"
const REJECTION_INVALID_PACKET := &"invalid_packet"
const REJECTION_INVALID_RESULT := &"invalid_hit_result"
const REJECTION_INVALID_LAUNCH_PROFILE := &"invalid_launch_profile"
const REJECTION_TARGET_KNOCKDOWN_PROTECTED := &"target_knockdown_protected"
const REJECTION_GROUND_PURSUIT_LIMIT := &"ground_pursuit_limit_reached"

var instance_id: int:
	get:
		return _instance_id
var faction_id: StringName:
	get:
		return _faction_id
var maximum_health: int:
	get:
		return _maximum_health
var current_health: int:
	get:
		return _current_health
var maximum_poise: float:
	get:
		return _maximum_poise
var current_poise: float:
	get:
		return _current_poise
var defense: float:
	get:
		return _defense
var reaction_profile_id: StringName:
	get:
		return _profile.definition_id if _profile != null else &""
var reaction_strategy: StringName:
	get:
		return StringName(_profile.strategy) if _profile != null else &""
var reaction_type: StringName:
	get:
		return _reaction_type
var reaction_ticks_remaining: int:
	get:
		return _reaction_ticks_remaining
var poise_recovery_delay_ticks_remaining: int:
	get:
		return _poise_recovery_delay_ticks_remaining
var post_break_protection_ticks_remaining: int:
	get:
		return _post_break_protection_ticks_remaining
var elevation: float:
	get:
		return _juggle_model.elevation if _juggle_model != null else 0.0
var vertical_velocity: float:
	get:
		return _juggle_model.vertical_velocity if _juggle_model != null else 0.0
var juggle_resistance: float:
	get:
		return _juggle_model.juggle_resistance if _juggle_model != null else 0.0
var airborne_control_ticks: int:
	get:
		return _juggle_model.airborne_control_ticks if _juggle_model != null else 0
var knockdown_ticks_remaining: int:
	get:
		return _juggle_model.knockdown_ticks_remaining if _juggle_model != null else 0
var ground_pursuit_hits_used: int:
	get:
		return _juggle_model.ground_pursuit_hits_used if _juggle_model != null else 0
var can_be_launched: bool:
	get:
		return _juggle_model.can_be_launched if _juggle_model != null else false
var is_airborne: bool:
	get:
		return _juggle_model != null and _juggle_model.is_airborne
var is_knocked_down: bool:
	get:
		return _juggle_model != null and _juggle_model.is_knocked_down
var is_broken: bool:
	get:
		return _reaction_type == REACTION_POISE_BREAK
var is_defeated: bool:
	get:
		return _reaction_type == REACTION_DEFEATED

var _instance_id := 0
var _faction_id: StringName = &""
var _maximum_health := 0
var _current_health := 0
var _maximum_poise := 0.0
var _current_poise := 0.0
var _defense := 0.0
var _profile: CombatReactionProfile
var _juggle_model: JuggleModel
var _reaction_type: StringName = REACTION_NONE
var _reaction_ticks_remaining := 0
var _poise_recovery_delay_ticks_remaining := 0
var _post_break_protection_ticks_remaining := 0
var _configured := false


func configure(
	new_instance_id: int,
	new_faction_id: StringName,
	new_maximum_health: int,
	new_maximum_poise: float,
	new_defense: float,
	new_profile: CombatReactionProfile
) -> PackedStringArray:
	var errors := PackedStringArray()
	if new_instance_id <= 0:
		errors.append("instance_id must be greater than 0")
	if new_faction_id not in [&"player", &"enemy"]:
		errors.append("faction_id must be player or enemy")
	if new_maximum_health < 1:
		errors.append("maximum_health must be at least 1")
	if not _is_finite(new_maximum_poise) or new_maximum_poise <= 0.0:
		errors.append("maximum_poise must be finite and greater than 0")
	if not _is_finite(new_defense):
		errors.append("defense must be finite")
	if new_profile == null:
		errors.append("reaction profile is required")
	else:
		for message: String in new_profile.validation_errors():
			errors.append("reaction profile: %s" % message)
	if not errors.is_empty():
		return errors

	var profile_snapshot := new_profile.duplicate(true) as CombatReactionProfile
	var juggle_candidate: JuggleModel = JuggleModelScript.new()
	for message: String in juggle_candidate.configure(profile_snapshot):
		errors.append("juggle model: %s" % message)
	if not errors.is_empty():
		return errors

	_instance_id = new_instance_id
	_faction_id = new_faction_id
	_maximum_health = new_maximum_health
	_current_health = new_maximum_health
	_maximum_poise = new_maximum_poise
	_current_poise = new_maximum_poise
	_defense = new_defense
	_profile = profile_snapshot
	_juggle_model = juggle_candidate
	_reaction_type = REACTION_NONE
	_reaction_ticks_remaining = 0
	_poise_recovery_delay_ticks_remaining = 0
	_post_break_protection_ticks_remaining = 0
	_configured = true
	return errors


func can_receive_hit() -> bool:
	return _configured and not is_defeated and _current_health > 0


func hit_height_range(minimum_height: float = 0.0, maximum_height: float = 56.0) -> Vector2:
	if (
		not _is_finite(minimum_height)
		or not _is_finite(maximum_height)
		or minimum_height < 0.0
		or maximum_height < minimum_height
	):
		return Vector2.ZERO
	return Vector2(elevation + minimum_height, elevation + maximum_height)


func apply_damage(
	packet: DamagePacket,
	resolved_result: HitResult,
	launch_profile: CombatLaunchProfile = null
) -> HitResult:
	if not _configured:
		return HitResultScript.rejected(REJECTION_NOT_CONFIGURED)
	if not can_receive_hit():
		return HitResultScript.rejected(REJECTION_TARGET_DEFEATED)
	if packet == null or not packet.validation_errors().is_empty():
		return HitResultScript.rejected(REJECTION_INVALID_PACKET)
	if (
		resolved_result == null
		or not resolved_result.accepted
		or not resolved_result.validation_errors().is_empty()
		or not is_equal_approx(resolved_result.poise_damage, packet.poise_damage)
	):
		return HitResultScript.rejected(REJECTION_INVALID_RESULT)
	if not _launch_profile_matches_packet(packet, launch_profile):
		return HitResultScript.rejected(REJECTION_INVALID_LAUNCH_PROFILE)

	var ground_pursuit_consumed := false
	if is_knocked_down:
		if launch_profile == null or not launch_profile.can_hit_downed:
			return HitResultScript.rejected(REJECTION_TARGET_KNOCKDOWN_PROTECTED)
		if not _juggle_model.can_consume_ground_pursuit():
			return HitResultScript.rejected(REJECTION_GROUND_PURSUIT_LIMIT)
		ground_pursuit_consumed = _juggle_model.consume_ground_pursuit()

	_apply_health_damage(resolved_result.final_damage)
	var applied_poise_damage := 0.0
	var started_break := false
	if not is_defeated and not is_broken:
		applied_poise_damage = _effective_poise_damage(resolved_result.poise_damage)
		if applied_poise_damage > 0.0:
			_apply_poise_damage(applied_poise_damage)
		var forced_break := _profile.has_forced_break_tag(packet.hit_tags)
		if forced_break and _current_poise > 0.0:
			_set_current_poise(0.0)
		if forced_break or _current_poise <= 0.0:
			started_break = true
			_enter_break()

	var outcome_reaction := _reaction_type
	var outcome_knockback := Vector2.ZERO
	var outcome_launch_velocity := 0.0
	if is_defeated:
		outcome_reaction = REACTION_DEFEATED
	elif started_break:
		outcome_reaction = REACTION_POISE_BREAK
		outcome_knockback = _directional_knockback(packet.direction, _profile.break_knockback)
	elif is_broken:
		outcome_reaction = REACTION_POISE_BREAK
	elif ground_pursuit_consumed:
		_reaction_ticks_remaining = 0
		_set_reaction(REACTION_KNOCKDOWN)
		outcome_reaction = REACTION_KNOCKDOWN
	else:
		var was_airborne := _juggle_model.is_airborne
		if was_airborne:
			_juggle_model.register_airborne_hit()
		if launch_profile != null and launch_profile.upward_velocity > 0.0:
			outcome_launch_velocity = _juggle_model.launch(launch_profile.upward_velocity)
		if outcome_launch_velocity > 0.0:
			_reaction_ticks_remaining = 0
			_set_reaction(REACTION_AIRBORNE)
			outcome_reaction = REACTION_AIRBORNE
			launched.emit(outcome_launch_velocity, _juggle_model.juggle_resistance)
		elif _juggle_model.is_airborne:
			_reaction_ticks_remaining = 0
			_set_reaction(REACTION_AIRBORNE)
			outcome_reaction = REACTION_AIRBORNE
		elif _profile.react_on_health_hit:
			_enter_hit_reaction()
			outcome_reaction = REACTION_HIT_STUN
			outcome_knockback = _directional_knockback(packet.direction, _profile.hit_knockback)
		else:
			outcome_reaction = REACTION_NONE

	var reported_ground_pursuit := (
		ground_pursuit_consumed and outcome_reaction == REACTION_KNOCKDOWN
	)
	return resolved_result.with_application_outcome(
		applied_poise_damage,
		started_break,
		outcome_reaction,
		outcome_knockback,
		outcome_launch_velocity,
		_juggle_model.juggle_resistance,
		reported_ground_pursuit
	)


func heal(amount: int) -> int:
	if not _configured or is_defeated or amount <= 0:
		return 0
	var previous_health := _current_health
	_current_health = mini(_maximum_health, _current_health + amount)
	var restored := _current_health - previous_health
	if restored > 0:
		health_changed.emit(previous_health, _current_health)
	return restored


func advance_tick() -> void:
	if not _configured or is_defeated:
		return
	if is_broken:
		_reaction_ticks_remaining = maxi(0, _reaction_ticks_remaining - 1)
		if _reaction_ticks_remaining == 0:
			_set_current_poise(_maximum_poise)
			_post_break_protection_ticks_remaining = POST_BREAK_PROTECTION_TICKS
			_set_reaction(REACTION_NONE)
		return

	var juggle_transition := _juggle_model.advance_tick()
	match juggle_transition:
		JuggleModel.TRANSITION_LANDED:
			_enter_knockdown(false)
		JuggleModel.TRANSITION_FORCED_LANDED:
			forced_landed.emit(_juggle_model.airborne_control_ticks)
			_enter_knockdown(true)
		JuggleModel.TRANSITION_RECOVERED:
			_reaction_ticks_remaining = 0
			_set_reaction(REACTION_NONE)
			knockdown_recovered.emit()
		_:
			pass

	if _juggle_model.is_airborne:
		_reaction_ticks_remaining = 0
		_set_reaction(REACTION_AIRBORNE)
	elif _juggle_model.is_knocked_down:
		_reaction_ticks_remaining = 0
		_set_reaction(REACTION_KNOCKDOWN)
	elif _reaction_type == REACTION_HIT_STUN:
		_reaction_ticks_remaining = maxi(0, _reaction_ticks_remaining - 1)
		if _reaction_ticks_remaining == 0:
			_set_reaction(REACTION_NONE)

	if _post_break_protection_ticks_remaining > 0:
		_post_break_protection_ticks_remaining -= 1

	if _current_poise >= _maximum_poise:
		return
	if _poise_recovery_delay_ticks_remaining > 0:
		_poise_recovery_delay_ticks_remaining -= 1
		if _poise_recovery_delay_ticks_remaining > 0:
			return
	if _profile.poise_recovery_per_tick > 0.0:
		_set_current_poise(
			minf(_maximum_poise, _current_poise + _profile.poise_recovery_per_tick)
		)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not _configured:
		errors.append("combatant is not configured")
		return errors
	if _instance_id <= 0 or _faction_id not in [&"player", &"enemy"]:
		errors.append("combatant runtime identity is invalid")
	if _maximum_health < 1 or _current_health < 0 or _current_health > _maximum_health:
		errors.append("combatant health invariant is invalid")
	if (
		not _is_finite(_maximum_poise)
		or not _is_finite(_current_poise)
		or _maximum_poise <= 0.0
		or _current_poise < 0.0
		or _current_poise > _maximum_poise
	):
		errors.append("combatant poise invariant is invalid")
	if not _is_finite(_defense):
		errors.append("combatant defense is invalid")
	if _profile == null or not _profile.validation_errors().is_empty():
		errors.append("combatant reaction profile is invalid")
	if _juggle_model == null or not _juggle_model.validation_errors().is_empty():
		errors.append("combatant juggle model is invalid")
	if is_broken and (_reaction_ticks_remaining < 1 or _current_poise > 0.0):
		errors.append("broken combatant state is inconsistent")
	if is_airborne and _reaction_type != REACTION_AIRBORNE:
		errors.append("airborne combatant reaction is inconsistent")
	if is_knocked_down and _reaction_type != REACTION_KNOCKDOWN:
		errors.append("knocked-down combatant reaction is inconsistent")
	if _reaction_type == REACTION_AIRBORNE and not is_airborne:
		errors.append("airborne reaction has no airborne control state")
	if _reaction_type == REACTION_KNOCKDOWN and not is_knocked_down:
		errors.append("knockdown reaction has no knockdown control state")
	if is_defeated and _current_health != 0:
		errors.append("defeated combatant must have zero health")
	if is_defeated and (is_airborne or is_knocked_down):
		errors.append("defeated combatant retained airborne control state")
	return errors


func _launch_profile_matches_packet(
	packet: DamagePacket,
	launch_profile: CombatLaunchProfile
) -> bool:
	if packet.launch_profile == &"none":
		return launch_profile == null
	return (
		launch_profile != null
		and launch_profile.definition_id == packet.launch_profile
		and launch_profile.validation_errors().is_empty()
	)


func _apply_health_damage(damage: int) -> void:
	var previous_health := _current_health
	_current_health = maxi(0, _current_health - damage)
	if _current_health != previous_health:
		health_changed.emit(previous_health, _current_health)
	if _current_health == 0:
		_juggle_model.interrupt_to_ground()
		_reaction_ticks_remaining = 0
		_set_reaction(REACTION_DEFEATED)
		defeated.emit()


func _effective_poise_damage(base_poise_damage: float) -> float:
	if _post_break_protection_ticks_remaining > 0:
		return base_poise_damage * _profile.post_break_poise_damage_multiplier
	return base_poise_damage


func _apply_poise_damage(damage: float) -> void:
	_set_current_poise(maxf(0.0, _current_poise - damage))
	_poise_recovery_delay_ticks_remaining = POISE_RECOVERY_DELAY_TICKS


func _enter_hit_reaction() -> void:
	_reaction_ticks_remaining = _profile.hit_reaction_ticks
	_set_reaction(REACTION_HIT_STUN)


func _enter_break() -> void:
	_juggle_model.interrupt_to_ground()
	_reaction_ticks_remaining = _profile.break_duration_ticks
	_poise_recovery_delay_ticks_remaining = 0
	_post_break_protection_ticks_remaining = 0
	_set_reaction(REACTION_POISE_BREAK)
	poise_broken.emit(_profile.break_duration_ticks)


func _enter_knockdown(forced: bool) -> void:
	_reaction_ticks_remaining = 0
	_set_reaction(REACTION_KNOCKDOWN)
	knocked_down.emit(JuggleModel.KNOCKDOWN_DURATION_TICKS, forced)


func _set_current_poise(new_poise: float) -> void:
	var previous_poise := _current_poise
	_current_poise = clampf(new_poise, 0.0, _maximum_poise)
	if not is_equal_approx(previous_poise, _current_poise):
		poise_changed.emit(previous_poise, _current_poise)


func _set_reaction(new_reaction: StringName) -> void:
	if _reaction_type == new_reaction:
		return
	var previous_reaction := _reaction_type
	_reaction_type = new_reaction
	reaction_changed.emit(previous_reaction, _reaction_type)


func _directional_knockback(direction: Vector2, strength: float) -> Vector2:
	if direction.is_zero_approx() or strength <= 0.0:
		return Vector2.ZERO
	return direction.normalized() * strength


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
