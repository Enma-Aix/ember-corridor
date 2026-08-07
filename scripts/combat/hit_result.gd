class_name HitResult
extends RefCounted

var accepted: bool:
	get:
		return _accepted
var rejection_code: StringName:
	get:
		return _rejection_code
var raw_damage: float:
	get:
		return _raw_damage
var defense_multiplier: float:
	get:
		return _defense_multiplier
var damage_modifier: float:
	get:
		return _damage_modifier
var effective_crit_chance: float:
	get:
		return _effective_crit_chance
var final_damage: int:
	get:
		return _final_damage
var critical: bool:
	get:
		return _critical
var poise_damage: float:
	get:
		return _poise_damage
var broke_poise: bool:
	get:
		return _broke_poise
var reaction_type: StringName:
	get:
		return _reaction_type
var knockback: Vector2:
	get:
		return _knockback
var hit_stop_ticks: int:
	get:
		return _hit_stop_ticks
var feedback_strength: StringName:
	get:
		return _feedback_strength
var launch_velocity: float:
	get:
		return _launch_velocity
var juggle_resistance: float:
	get:
		return _juggle_resistance
var ground_pursuit_consumed: bool:
	get:
		return _ground_pursuit_consumed

var _accepted: bool
var _rejection_code: StringName
var _raw_damage: float
var _defense_multiplier: float
var _damage_modifier: float
var _effective_crit_chance: float
var _final_damage: int
var _critical: bool
var _poise_damage: float
var _broke_poise: bool
var _reaction_type: StringName
var _knockback: Vector2
var _hit_stop_ticks: int
var _feedback_strength: StringName
var _launch_velocity: float
var _juggle_resistance: float
var _ground_pursuit_consumed: bool


func _init(
	new_accepted: bool,
	new_rejection_code: StringName,
	new_raw_damage: float,
	new_defense_multiplier: float,
	new_damage_modifier: float,
	new_effective_crit_chance: float,
	new_final_damage: int,
	new_critical: bool,
	new_poise_damage: float,
	new_broke_poise: bool,
	new_reaction_type: StringName,
	new_knockback: Vector2,
	new_hit_stop_ticks: int,
	new_feedback_strength: StringName,
	new_launch_velocity: float = 0.0,
	new_juggle_resistance: float = 0.0,
	new_ground_pursuit_consumed: bool = false
) -> void:
	_accepted = new_accepted
	_rejection_code = new_rejection_code
	_raw_damage = new_raw_damage
	_defense_multiplier = new_defense_multiplier
	_damage_modifier = new_damage_modifier
	_effective_crit_chance = new_effective_crit_chance
	_final_damage = new_final_damage
	_critical = new_critical
	_poise_damage = new_poise_damage
	_broke_poise = new_broke_poise
	_reaction_type = new_reaction_type
	_knockback = new_knockback
	_hit_stop_ticks = new_hit_stop_ticks
	_feedback_strength = new_feedback_strength
	_launch_velocity = new_launch_velocity
	_juggle_resistance = new_juggle_resistance
	_ground_pursuit_consumed = new_ground_pursuit_consumed


static func rejected(reason_code: StringName) -> HitResult:
	return HitResult.new(
		false,
		reason_code,
		0.0,
		0.0,
		0.0,
		0.0,
		0,
		false,
		0.0,
		false,
		&"none",
		Vector2.ZERO,
		0,
		&"light"
	)


func with_application_outcome(
	new_poise_damage: float,
	new_broke_poise: bool,
	new_reaction_type: StringName,
	new_knockback: Vector2,
	new_launch_velocity: float = 0.0,
	new_juggle_resistance: float = 0.0,
	new_ground_pursuit_consumed: bool = false
) -> HitResult:
	if not accepted:
		return HitResult.rejected(rejection_code)
	return HitResult.new(
		true,
		&"",
		raw_damage,
		defense_multiplier,
		damage_modifier,
		effective_crit_chance,
		final_damage,
		critical,
		new_poise_damage,
		new_broke_poise,
		new_reaction_type,
		new_knockback,
		hit_stop_ticks,
		feedback_strength,
		new_launch_velocity,
		new_juggle_resistance,
		new_ground_pursuit_consumed
	)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if accepted:
		if rejection_code != &"":
			errors.append("accepted result must not contain a rejection_code")
		if final_damage < 1:
			errors.append("accepted result final_damage must be at least 1")
		if defense_multiplier < 0.0 or defense_multiplier > 1.0:
			errors.append("defense_multiplier must be in [0, 1]")
		if damage_modifier < 0.0:
			errors.append("damage_modifier must be at least 0")
		if effective_crit_chance < 0.0 or effective_crit_chance > 0.6:
			errors.append("effective_crit_chance must be in [0, 0.6]")
		if is_nan(poise_damage) or is_inf(poise_damage) or poise_damage < 0.0:
			errors.append("poise_damage must be finite and at least 0")
		if reaction_type == &"":
			errors.append("reaction_type must not be empty")
		if broke_poise and reaction_type != &"poise_break":
			errors.append("broke_poise requires the poise_break reaction")
		if (
			is_nan(knockback.x)
			or is_inf(knockback.x)
			or is_nan(knockback.y)
			or is_inf(knockback.y)
		):
			errors.append("knockback components must be finite")
		if is_nan(launch_velocity) or is_inf(launch_velocity) or launch_velocity < 0.0:
			errors.append("launch_velocity must be finite and at least 0")
		if (
			is_nan(juggle_resistance)
			or is_inf(juggle_resistance)
			or juggle_resistance < 0.0
		):
			errors.append("juggle_resistance must be finite and at least 0")
		if launch_velocity > 0.0 and reaction_type != &"airborne":
			errors.append("positive launch_velocity requires the airborne reaction")
		if ground_pursuit_consumed and reaction_type != &"knockdown":
			errors.append("ground pursuit consumption requires the knockdown reaction")
		if hit_stop_ticks < 0:
			errors.append("hit_stop_ticks must be at least 0")
	elif rejection_code == &"":
		errors.append("rejected result must contain a rejection_code")
	elif (
		final_damage != 0
		or critical
		or broke_poise
		or launch_velocity != 0.0
		or juggle_resistance != 0.0
		or ground_pursuit_consumed
	):
		errors.append("rejected result must not contain applied combat outcomes")
	return errors
