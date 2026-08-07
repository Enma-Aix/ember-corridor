class_name AttackTimelineModel
extends RefCounted

signal timeline_started(attack_id: StringName, total_ticks: int)
signal tick_advanced(action_tick: int, phase: AttackDefinition.TimelinePhase)
signal phase_changed(
	previous_phase: AttackDefinition.TimelinePhase,
	current_phase: AttackDefinition.TimelinePhase,
	action_tick: int
)
signal timeline_completed(attack_id: StringName, total_ticks: int)

var action_tick: int:
	get:
		return _action_tick
var current_phase: AttackDefinition.TimelinePhase:
	get:
		return _current_phase
var is_running: bool:
	get:
		return _is_running
var attack_id: StringName:
	get:
		return _definition.definition_id if _definition != null else &""

var _definition: AttackDefinition
var _action_tick := 0
var _current_phase := AttackDefinition.TimelinePhase.BEFORE_START
var _is_running := false


func start(source_definition: AttackDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if _is_running:
		errors.append("cannot start an attack while a timeline is already running")
		return errors
	if source_definition == null:
		errors.append("attack definition must not be null")
		return errors
	errors.append_array(source_definition.validation_errors())
	if not errors.is_empty():
		return errors

	_definition = source_definition.duplicate(true) as AttackDefinition
	if _definition == null:
		errors.append("attack definition could not be snapshotted")
		return errors
	_action_tick = 0
	_current_phase = AttackDefinition.TimelinePhase.BEFORE_START
	_is_running = true
	timeline_started.emit(_definition.definition_id, _definition.total_ticks())
	return errors


func advance_tick() -> bool:
	if not _is_running or _definition == null:
		return false
	_action_tick += 1
	var next_phase := _definition.phase_at_tick(_action_tick)
	if next_phase != _current_phase:
		var previous_phase := _current_phase
		_current_phase = next_phase
		phase_changed.emit(previous_phase, _current_phase, _action_tick)
	tick_advanced.emit(_action_tick, _current_phase)
	if _action_tick >= _definition.total_ticks():
		_is_running = false
		timeline_completed.emit(_definition.definition_id, _definition.total_ticks())
	return true


func total_ticks() -> int:
	return _definition.total_ticks() if _definition != null else 0


func current_phase_name() -> StringName:
	if _definition == null:
		return &"not_loaded"
	return _definition.phase_name_at_tick(_action_tick)


func is_hitbox_active() -> bool:
	return _definition != null and _definition.is_active_tick(_action_tick)


func available_cancel_targets() -> PackedStringArray:
	if _definition == null:
		return PackedStringArray()
	return _definition.cancel_targets_at_tick(_action_tick)


func reset() -> void:
	_definition = null
	_action_tick = 0
	_current_phase = AttackDefinition.TimelinePhase.BEFORE_START
	_is_running = false
