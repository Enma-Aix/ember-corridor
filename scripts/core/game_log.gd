class_name GameLog
extends RefCounted

enum Level {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
}

const LEVEL_LABELS := {
	Level.DEBUG: "DEBUG",
	Level.INFO: "INFO",
	Level.WARNING: "WARN",
	Level.ERROR: "ERROR",
}


static func debug(module: StringName, message: String) -> void:
	if not OS.is_debug_build():
		return
	_write(Level.DEBUG, module, message)


static func info(module: StringName, message: String) -> void:
	_write(Level.INFO, module, message)


static func warning(module: StringName, message: String) -> void:
	_write(Level.WARNING, module, message)


static func error(module: StringName, message: String) -> void:
	_write(Level.ERROR, module, message)


static func _write(level: int, module: StringName, message: String) -> void:
	var timestamp := Time.get_datetime_string_from_system(false, true)
	var level_label: String = LEVEL_LABELS.get(level, "UNKNOWN")
	var formatted := "[%s] [%s] [%s] %s" % [
		timestamp,
		level_label,
		String(module),
		message,
	]
	print(formatted)
	if level == Level.WARNING:
		push_warning(formatted)
	elif level == Level.ERROR:
		push_error(formatted)

