class_name JuggleModel
extends RefCounted

const ElevationModelScript := preload("res://scripts/actors/elevation_model.gd")

const TICKS_PER_SECOND := 60
const MAX_AIRBORNE_CONTROL_TICKS := 210
const KNOCKDOWN_DURATION_TICKS := 30
const MAX_GROUND_PURSUIT_HITS := 1
const FIXED_DELTA := 1.0 / float(TICKS_PER_SECOND)

const STATE_GROUNDED := &"grounded"
const STATE_AIRBORNE := &"airborne"
const STATE_KNOCKDOWN := &"knockdown"

const TRANSITION_NONE := &"none"
const TRANSITION_LANDED := &"landed"
const TRANSITION_FORCED_LANDED := &"forced_landed"
const TRANSITION_RECOVERED := &"recovered"

var state: StringName:
	get:
		return _state
var elevation: float:
	get:
		return _elevation_model.elevation if _elevation_model != null else 0.0
var vertical_velocity: float:
	get:
		return _elevation_model.vertical_velocity if _elevation_model != null else 0.0
var juggle_resistance: float:
	get:
		return _juggle_resistance
var airborne_control_ticks: int:
	get:
		return _airborne_control_ticks
var knockdown_ticks_remaining: int:
	get:
		return _knockdown_ticks_remaining
var ground_pursuit_hits_used: int:
	get:
		return _ground_pursuit_hits_used
var can_be_launched: bool:
	get:
		return _can_be_launched
var is_airborne: bool:
	get:
		return _state == STATE_AIRBORNE
var is_knocked_down: bool:
	get:
		return _state == STATE_KNOCKDOWN

var _elevation_model: ElevationModel
var _state: StringName = STATE_GROUNDED
var _can_be_launched := false
var _resistance_per_air_hit := 1.0
var _gravity_multiplier_per_resistance := 0.25
var _maximum_gravity_multiplier := 2.5
var _launch_reduction_per_resistance := 0.15
var _minimum_launch_multiplier := 0.35
var _juggle_resistance := 0.0
var _airborne_control_ticks := 0
var _knockdown_ticks_remaining := 0
var _ground_pursuit_hits_used := 0
var _configured := false


func configure(profile: CombatReactionProfile) -> PackedStringArray:
	var errors := PackedStringArray()
	if profile == null:
		errors.append("reaction profile is required")
	else:
		for message: String in profile.validation_errors():
			errors.append("reaction profile: %s" % message)
	if not errors.is_empty():
		return errors

	var candidate: ElevationModel = ElevationModelScript.new()
	var elevation_errors := candidate.configure(
		1.0,
		profile.juggle_gravity,
		0.0,
		56.0
	)
	for message: String in elevation_errors:
		errors.append("elevation: %s" % message)
	if not errors.is_empty():
		return errors

	_elevation_model = candidate
	_can_be_launched = profile.can_be_launched
	_resistance_per_air_hit = profile.juggle_resistance_per_air_hit
	_gravity_multiplier_per_resistance = profile.juggle_gravity_multiplier_per_resistance
	_maximum_gravity_multiplier = profile.juggle_maximum_gravity_multiplier
	_launch_reduction_per_resistance = profile.juggle_launch_reduction_per_resistance
	_minimum_launch_multiplier = profile.juggle_minimum_launch_multiplier
	_configured = true
	_reset_runtime()
	return errors


func register_airborne_hit() -> bool:
	if not _configured or not is_airborne:
		return false
	_juggle_resistance += _resistance_per_air_hit
	return true


func launch(base_upward_velocity: float) -> float:
	if (
		not _configured
		or not _can_be_launched
		or is_knocked_down
		or not _is_finite(base_upward_velocity)
		or base_upward_velocity <= 0.0
	):
		return 0.0
	var effective_velocity := base_upward_velocity * effective_launch_multiplier()
	if not _elevation_model.launch(effective_velocity):
		return 0.0
	if not is_airborne:
		_state = STATE_AIRBORNE
		_airborne_control_ticks = 0
		_knockdown_ticks_remaining = 0
		_ground_pursuit_hits_used = 0
	return effective_velocity


func effective_launch_multiplier() -> float:
	return maxf(
		_minimum_launch_multiplier,
		1.0 - _juggle_resistance * _launch_reduction_per_resistance
	)


func effective_gravity_multiplier() -> float:
	return minf(
		_maximum_gravity_multiplier,
		1.0 + _juggle_resistance * _gravity_multiplier_per_resistance
	)


func can_consume_ground_pursuit() -> bool:
	return (
		_configured
		and is_knocked_down
		and _ground_pursuit_hits_used < MAX_GROUND_PURSUIT_HITS
	)


func consume_ground_pursuit() -> bool:
	if not can_consume_ground_pursuit():
		return false
	_ground_pursuit_hits_used += 1
	return true


func advance_tick() -> StringName:
	if not _configured:
		return TRANSITION_NONE
	if is_airborne:
		_airborne_control_ticks += 1
		if _airborne_control_ticks >= MAX_AIRBORNE_CONTROL_TICKS:
			_enter_knockdown()
			return TRANSITION_FORCED_LANDED
		if _elevation_model.advance(FIXED_DELTA, effective_gravity_multiplier()):
			_enter_knockdown()
			return TRANSITION_LANDED
		return TRANSITION_NONE
	if is_knocked_down:
		_knockdown_ticks_remaining = maxi(0, _knockdown_ticks_remaining - 1)
		if _knockdown_ticks_remaining == 0:
			_reset_runtime()
			return TRANSITION_RECOVERED
	return TRANSITION_NONE


func interrupt_to_ground() -> void:
	if not _configured:
		return
	_reset_runtime()


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not _configured or _elevation_model == null:
		errors.append("juggle model is not configured")
		return errors
	if not _is_finite(_juggle_resistance) or _juggle_resistance < 0.0:
		errors.append("juggle resistance invariant is invalid")
	if _ground_pursuit_hits_used < 0 or _ground_pursuit_hits_used > MAX_GROUND_PURSUIT_HITS:
		errors.append("ground pursuit hit invariant is invalid")
	match _state:
		STATE_GROUNDED:
			if not _elevation_model.grounded or _knockdown_ticks_remaining != 0:
				errors.append("grounded juggle state is inconsistent")
		STATE_AIRBORNE:
			if (
				_elevation_model.grounded
				or _airborne_control_ticks < 0
				or _airborne_control_ticks >= MAX_AIRBORNE_CONTROL_TICKS
				or _knockdown_ticks_remaining != 0
			):
				errors.append("airborne juggle state is inconsistent")
		STATE_KNOCKDOWN:
			if (
				not _elevation_model.grounded
				or _knockdown_ticks_remaining < 1
				or _knockdown_ticks_remaining > KNOCKDOWN_DURATION_TICKS
			):
				errors.append("knockdown juggle state is inconsistent")
		_:
			errors.append("juggle state is unsupported")
	return errors


func _enter_knockdown() -> void:
	_elevation_model.force_land()
	_state = STATE_KNOCKDOWN
	_knockdown_ticks_remaining = KNOCKDOWN_DURATION_TICKS
	_ground_pursuit_hits_used = 0


func _reset_runtime() -> void:
	_elevation_model.force_land()
	_state = STATE_GROUNDED
	_juggle_resistance = 0.0
	_airborne_control_ticks = 0
	_knockdown_ticks_remaining = 0
	_ground_pursuit_hits_used = 0


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
