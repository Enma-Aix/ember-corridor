class_name InputBufferModel
extends RefCounted

const DEFAULT_BUFFER_TICKS := 8
const MAX_BUFFER_TICKS := 60

var current_tick: int:
	get:
		return _current_tick
var buffer_ticks: int:
	get:
		return _buffer_ticks

var _current_tick := 0
var _buffer_ticks := DEFAULT_BUFFER_TICKS
var _entries: Dictionary[StringName, Dictionary] = {}
var _last_events: Dictionary[StringName, Dictionary] = {}


func configure(new_buffer_ticks: int = DEFAULT_BUFFER_TICKS) -> PackedStringArray:
	var errors := PackedStringArray()
	if new_buffer_ticks < 1 or new_buffer_ticks > MAX_BUFFER_TICKS:
		errors.append(
			"buffer_ticks must be between 1 and %d" % MAX_BUFFER_TICKS
		)
		return errors
	_buffer_ticks = new_buffer_ticks
	reset()
	return errors


func advance_tick() -> void:
	_current_tick += 1
	_prune_expired()


func record_pressed(action: StringName) -> bool:
	if action == &"":
		return false
	_entries[action] = {
		"action": action,
		"pressed_tick": _current_tick,
		"released_tick": -1,
	}
	_last_events.erase(action)
	return true


func record_released(action: StringName) -> bool:
	if action == &"":
		return false
	var entry: Dictionary
	if _entries.has(action):
		entry = _entries[action]
	elif _last_events.has(action):
		entry = _last_events[action]
	else:
		return false
	entry["released_tick"] = _current_tick
	if _entries.has(action):
		_entries[action] = entry
	else:
		_last_events[action] = entry
	return true


func has_buffered_press(action: StringName) -> bool:
	if action == &"" or not _entries.has(action):
		return false
	return input_age_ticks(action) < _buffer_ticks


func input_age_ticks(action: StringName) -> int:
	if action == &"" or not _entries.has(action):
		return -1
	var entry: Dictionary = _entries[action]
	return _current_tick - int(entry["pressed_tick"])


func buffered_entry(action: StringName) -> Dictionary:
	if not has_buffered_press(action):
		return {}
	return (_entries[action] as Dictionary).duplicate(true)


func last_event(action: StringName) -> Dictionary:
	if action == &"" or not _last_events.has(action):
		return {}
	return (_last_events[action] as Dictionary).duplicate(true)


func consume(action: StringName) -> Dictionary:
	if not has_buffered_press(action):
		return {}
	var entry := buffered_entry(action)
	entry["consumed_tick"] = _current_tick
	_last_events[action] = entry.duplicate(true)
	_entries.erase(action)
	return entry


func pending_actions() -> PackedStringArray:
	_prune_expired()
	var actions := PackedStringArray()
	for action: StringName in _entries:
		actions.append(String(action))
	actions.sort()
	return actions


func clear() -> void:
	_entries.clear()


func reset() -> void:
	_current_tick = 0
	clear()
	_last_events.clear()


func _prune_expired() -> void:
	var expired_actions: Array[StringName] = []
	for action: StringName in _entries:
		if input_age_ticks(action) >= _buffer_ticks:
			expired_actions.append(action)
	for action: StringName in expired_actions:
		_entries.erase(action)
