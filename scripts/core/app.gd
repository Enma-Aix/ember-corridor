extends Node

signal startup_completed()
signal error_reported(module: StringName, message: String, fatal: bool)

var startup_errors: PackedStringArray = []
var is_ready_for_gameplay := false


func _ready() -> void:
	GameLog.info(&"App", "Starting %s" % VersionInfo.display_string())
	if not VersionInfo.is_expected_engine():
		GameLog.warning(
			&"App",
			"Expected Godot %s; running %s"
			% [VersionInfo.REQUIRED_GODOT_VERSION, Engine.get_version_info().get("string", "unknown")]
		)
	call_deferred("_finish_startup")


func _finish_startup() -> void:
	startup_errors = DataRegistry.reload_definitions()
	if startup_errors.is_empty():
		is_ready_for_gameplay = true
		GameLog.info(&"App", "Foundation services initialized")
	else:
		for message: String in startup_errors:
			report_error(&"DataRegistry", message, true)
	startup_completed.emit()


func report_error(module: StringName, message: String, fatal := false) -> void:
	ErrorBoundary.report(module, message)
	error_reported.emit(module, message, fatal)
	EventBus.game_error.emit(module, message, fatal)


func version_label() -> String:
	return VersionInfo.display_string()

