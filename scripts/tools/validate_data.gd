extends SceneTree

const DataRegistryScript := preload("res://scripts/core/data_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry: DataRegistryService = DataRegistryScript.new()
	var errors := registry.reload_definitions()
	var report_lines := PackedStringArray()
	if errors.is_empty():
		report_lines.append(
			"PASS: loaded and validated %d definition(s)" % registry.definition_count()
		)
	else:
		report_lines.append("FAIL: data validation found %d error(s)" % errors.size())
		for message: String in errors:
			report_lines.append("  - %s" % message)
	for line: String in report_lines:
		print(line)
	_write_report(report_lines)
	registry.free()
	quit(0 if errors.is_empty() else 1)


func _write_report(lines: PackedStringArray) -> void:
	var output_directory := ProjectSettings.globalize_path("res://build/test-results")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var report := FileAccess.open(
		"res://build/test-results/data-validation.txt",
		FileAccess.WRITE
	)
	if report == null:
		push_warning("Could not write data validation report")
		return
	report.store_string("\n".join(lines) + "\n")
