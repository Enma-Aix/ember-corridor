class_name NormalAttackComboModel
extends RefCounted

signal attack_started(attack: AttackDefinition, combo_index: int)
signal attack_finished(
	attack_id: StringName,
	combo_index: int,
	reason: StringName
)
signal attack_start_rejected(errors: PackedStringArray)

const ATTACK_INPUT_ACTION := &"attack"
const ATTACK_CANCEL_TAG := &"action.attack"
const FINISH_COMPLETE := &"complete"
const FINISH_CHAINED := &"chained"
const FINISH_CANCELED := &"canceled"

var combo_index: int:
	get:
		return _combo_index
var timeline: AttackTimelineModel:
	get:
		return _timeline
var current_attack: AttackDefinition:
	get:
		return _current_attack()
var last_finish_reason: StringName:
	get:
		return _last_finish_reason

var _timeline := AttackTimelineModel.new()
var _sequence: Array[AttackDefinition] = []
var _combo_index := -1
var _cancel_tag := ATTACK_CANCEL_TAG
var _configured := false
var _last_finish_reason: StringName = &""


func configure(
	source_sequence: Array[AttackDefinition],
	new_cancel_tag: StringName = ATTACK_CANCEL_TAG
) -> PackedStringArray:
	var errors := PackedStringArray()
	if source_sequence.is_empty():
		errors.append("normal attack sequence must contain at least one attack")
	if new_cancel_tag == &"":
		errors.append("normal attack cancel tag must not be empty")

	var snapshots: Array[AttackDefinition] = []
	var seen_ids: Dictionary[StringName, bool] = {}
	for index: int in source_sequence.size():
		var source_attack: AttackDefinition = source_sequence[index]
		if source_attack == null:
			errors.append("normal attack sequence[%d] must not be null" % index)
			continue
		for message: String in source_attack.validation_errors():
			errors.append("normal attack sequence[%d]: %s" % [index, message])
		if seen_ids.has(source_attack.definition_id):
			errors.append(
				"normal attack sequence has duplicate ID: %s"
				% String(source_attack.definition_id)
			)
		else:
			seen_ids[source_attack.definition_id] = true
		var snapshot := source_attack.duplicate(true) as AttackDefinition
		if snapshot == null:
			errors.append("normal attack sequence[%d] could not be snapshotted" % index)
		else:
			snapshots.append(snapshot)

	if errors.is_empty():
		for index: int in range(snapshots.size() - 1):
			if not _definition_declares_cancel_tag(snapshots[index], new_cancel_tag):
				errors.append(
					"normal attack sequence[%d] does not declare cancel target %s"
					% [index, String(new_cancel_tag)]
				)
	if not errors.is_empty():
		return errors

	_sequence = snapshots
	_cancel_tag = new_cancel_tag
	_configured = true
	reset()
	return errors


func is_configured() -> bool:
	return _configured


func sequence_size() -> int:
	return _sequence.size()


func sequence_attack(index: int) -> AttackDefinition:
	if index < 0 or index >= _sequence.size():
		return null
	return _sequence[index]


func start_first_attack_immediately() -> bool:
	if not _configured or _timeline.is_running:
		return false
	return _start_attack(0)


func can_cancel_to(target_tag: StringName) -> bool:
	return (
		target_tag != &""
		and _combo_index >= 0
		and _timeline.available_cancel_targets().has(String(target_tag))
	)


func cancel_to(target_tag: StringName) -> bool:
	if not can_cancel_to(target_tag):
		return false
	_finish_current(FINISH_CANCELED)
	return true


func advance_tick(input_buffer: InputBufferModel, allow_idle_start := true) -> bool:
	if not _configured or input_buffer == null:
		return false
	var changed := false

	if _timeline.is_running:
		_timeline.advance_tick()
		changed = true
		if (
			_combo_index + 1 < _sequence.size()
			and _timeline.available_cancel_targets().has(String(_cancel_tag))
			and input_buffer.has_buffered_press(ATTACK_INPUT_ACTION)
		):
			input_buffer.consume(ATTACK_INPUT_ACTION)
			var next_index := _combo_index + 1
			_finish_current(FINISH_CHAINED)
			if _start_attack(next_index):
				_timeline.advance_tick()
		elif not _timeline.is_running:
			_finish_current(FINISH_COMPLETE)

	if (
		allow_idle_start
		and not _timeline.is_running
		and input_buffer.has_buffered_press(ATTACK_INPUT_ACTION)
	):
		input_buffer.consume(ATTACK_INPUT_ACTION)
		if _start_attack(0):
			_timeline.advance_tick()
		changed = true
	return changed


func reset() -> void:
	_timeline.reset()
	_combo_index = -1
	_last_finish_reason = &""


func _start_attack(index: int) -> bool:
	_combo_index = index
	var attack := _sequence[_combo_index]
	var start_errors := _timeline.start(attack)
	if not start_errors.is_empty():
		_combo_index = -1
		attack_start_rejected.emit(start_errors)
		return false
	attack_started.emit(attack, _combo_index)
	return true


func _finish_current(reason: StringName) -> void:
	var finished_attack := _current_attack()
	var finished_index := _combo_index
	_last_finish_reason = reason
	_timeline.reset()
	_combo_index = -1
	if finished_attack != null:
		attack_finished.emit(
			finished_attack.definition_id,
			finished_index,
			reason
		)


func _current_attack() -> AttackDefinition:
	if _combo_index < 0 or _combo_index >= _sequence.size():
		return null
	return _sequence[_combo_index]


func _definition_declares_cancel_tag(
	definition: AttackDefinition,
	target_tag: StringName
) -> bool:
	for cancel_window: AttackCancelWindow in definition.cancel_windows:
		if cancel_window != null and cancel_window.target_tags.has(target_tag):
			return true
	return false
