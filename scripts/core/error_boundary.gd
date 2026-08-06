class_name ErrorBoundary
extends RefCounted


static func require_true(
	condition: bool,
	module: StringName,
	message: String
) -> bool:
	if condition:
		return true
	report(module, message)
	return false


static func report(module: StringName, message: String) -> void:
	GameLog.error(module, message)

