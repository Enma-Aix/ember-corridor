class_name StateMachineModel
extends RefCounted

signal state_changed(
	previous_state: StringName,
	current_state: StringName,
	transition_index: int
)
signal transition_rejected(
	current_state: StringName,
	target_state: StringName,
	reason_code: StringName,
	message: String
)

const REJECTION_NOT_CONFIGURED := &"not_configured"
const REJECTION_EMPTY_TARGET := &"empty_target"
const REJECTION_UNKNOWN_TARGET := &"unknown_target"
const REJECTION_NOT_ALLOWED := &"transition_not_allowed"

var current_state: StringName:
	get:
		return _current_state
var previous_state: StringName:
	get:
		return _previous_state
var transition_count: int:
	get:
		return _transition_count
var last_rejection_code: StringName:
	get:
		return _last_rejection_code
var last_rejection_message: String:
	get:
		return _last_rejection_message

var _initial_state: StringName = &""
var _transition_table: Dictionary[StringName, PackedStringArray] = {}
var _configured := false
var _current_state: StringName = &""
var _previous_state: StringName = &""
var _transition_count := 0
var _last_rejection_code: StringName = &""
var _last_rejection_message := ""


func configure(
	new_initial_state: StringName,
	transition_table: Dictionary
) -> PackedStringArray:
	var errors := PackedStringArray()
	var normalized_table: Dictionary[StringName, PackedStringArray] = {}
	if new_initial_state == &"":
		errors.append("initial state must not be empty")
	if transition_table.is_empty():
		errors.append("transition table must declare at least one state")

	for raw_state: Variant in transition_table.keys():
		if not _is_state_token(raw_state):
			errors.append("state IDs must be String or StringName values")
			continue
		var state_text := String(raw_state)
		var state_id := StringName(state_text)
		if state_text.is_empty() or state_text != state_text.strip_edges():
			errors.append("state IDs must be non-empty and have no outer whitespace")
			continue
		if normalized_table.has(state_id):
			errors.append("duplicate state ID after normalization: %s" % state_text)
			continue

		var raw_targets: Variant = transition_table[raw_state]
		if not _is_target_collection(raw_targets):
			errors.append("state %s must map to an Array of state IDs" % state_text)
			continue
		var targets := PackedStringArray()
		for raw_target: Variant in raw_targets:
			if not _is_state_token(raw_target):
				errors.append("state %s has a non-string target" % state_text)
				continue
			var target_text := String(raw_target)
			if target_text.is_empty() or target_text != target_text.strip_edges():
				errors.append(
					"state %s has an empty or whitespace-padded target" % state_text
				)
				continue
			if targets.has(target_text):
				errors.append(
					"state %s declares duplicate target %s" % [state_text, target_text]
				)
				continue
			targets.append(target_text)
		normalized_table[state_id] = targets

	if errors.is_empty() and not normalized_table.has(new_initial_state):
		errors.append("initial state is not declared: %s" % String(new_initial_state))
	for state_id: StringName in normalized_table:
		for target_text: String in normalized_table[state_id]:
			if not normalized_table.has(StringName(target_text)):
				errors.append(
					"state %s targets undeclared state %s"
					% [String(state_id), target_text]
				)

	if not errors.is_empty():
		return errors

	_initial_state = new_initial_state
	_transition_table = normalized_table
	_configured = true
	_reset_runtime_state()
	return errors


func is_configured() -> bool:
	return _configured


func known_states() -> PackedStringArray:
	var result := PackedStringArray()
	for state_id: StringName in _transition_table:
		result.append(String(state_id))
	result.sort()
	return result


func allowed_targets_from(state_id: StringName) -> PackedStringArray:
	if not _transition_table.has(state_id):
		return PackedStringArray()
	return _transition_table[state_id].duplicate()


func can_transition_to(target_state: StringName) -> bool:
	return _rejection_code_for(target_state) == &""


func request_transition(target_state: StringName) -> bool:
	var rejection_code := _rejection_code_for(target_state)
	if rejection_code != &"":
		_reject_transition(target_state, rejection_code)
		return false

	_previous_state = _current_state
	_current_state = target_state
	_transition_count += 1
	_last_rejection_code = &""
	_last_rejection_message = ""
	state_changed.emit(_previous_state, _current_state, _transition_count)
	return true


func reset() -> bool:
	if not _configured:
		_reject_transition(&"", REJECTION_NOT_CONFIGURED)
		return false
	_reset_runtime_state()
	return true


func _reset_runtime_state() -> void:
	_current_state = _initial_state
	_previous_state = &""
	_transition_count = 0
	_last_rejection_code = &""
	_last_rejection_message = ""


func _rejection_code_for(target_state: StringName) -> StringName:
	if not _configured:
		return REJECTION_NOT_CONFIGURED
	if target_state == &"":
		return REJECTION_EMPTY_TARGET
	if not _transition_table.has(target_state):
		return REJECTION_UNKNOWN_TARGET
	if not _transition_table[_current_state].has(String(target_state)):
		return REJECTION_NOT_ALLOWED
	return &""


func _reject_transition(target_state: StringName, reason_code: StringName) -> void:
	_last_rejection_code = reason_code
	_last_rejection_message = _rejection_message(target_state, reason_code)
	transition_rejected.emit(
		_current_state,
		target_state,
		reason_code,
		_last_rejection_message
	)


func _rejection_message(target_state: StringName, reason_code: StringName) -> String:
	match reason_code:
		REJECTION_NOT_CONFIGURED:
			return "state machine is not configured"
		REJECTION_EMPTY_TARGET:
			return "target state must not be empty"
		REJECTION_UNKNOWN_TARGET:
			return "target state is not declared: %s" % String(target_state)
		REJECTION_NOT_ALLOWED:
			return (
				"transition %s -> %s is not allowed"
				% [String(_current_state), String(target_state)]
			)
	return "state transition was rejected"


func _is_state_token(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _is_target_collection(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_PACKED_STRING_ARRAY
