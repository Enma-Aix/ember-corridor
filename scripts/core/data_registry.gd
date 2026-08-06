class_name DataRegistryService
extends Node

var _definitions: Dictionary[StringName, BaseDefinition] = {}


func reload_definitions(root_path := "res://data") -> PackedStringArray:
	var discovered: Array[BaseDefinition] = []
	var errors := PackedStringArray()
	_collect_definitions(root_path, discovered, errors)
	if not errors.is_empty():
		_definitions.clear()
		return errors
	errors.append_array(index_definitions(discovered))
	if errors.is_empty():
		GameLog.info(
			&"DataRegistry",
			"Loaded %d definition(s) from %s" % [_definitions.size(), root_path]
		)
	return errors


func index_definitions(definitions: Array[BaseDefinition]) -> PackedStringArray:
	var errors := validate_definitions(definitions)
	if not errors.is_empty():
		_definitions.clear()
		return errors
	_definitions.clear()
	for definition: BaseDefinition in definitions:
		_definitions[definition.definition_id] = definition
	return errors


func validate_definitions(definitions: Array[BaseDefinition]) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_paths: Dictionary[StringName, String] = {}
	for index: int in definitions.size():
		var definition: BaseDefinition = definitions[index]
		if definition == null:
			errors.append("definition at index %d is null" % index)
			continue
		var source := definition.resource_path
		if source.is_empty():
			source = "<memory:%d>" % index
		for message: String in definition.validation_errors():
			errors.append("%s: %s" % [source, message])
		if String(definition.definition_id).is_empty():
			continue
		if seen_paths.has(definition.definition_id):
			errors.append(
				"duplicate definition_id '%s': %s and %s"
				% [
					String(definition.definition_id),
					seen_paths[definition.definition_id],
					source,
				]
			)
		else:
			seen_paths[definition.definition_id] = source
	return errors


func has_definition(definition_id: StringName) -> bool:
	return _definitions.has(definition_id)


func get_definition(definition_id: StringName) -> BaseDefinition:
	return _definitions.get(definition_id)


func definition_count() -> int:
	return _definitions.size()


func all_definitions() -> Array[BaseDefinition]:
	var result: Array[BaseDefinition] = []
	for definition: BaseDefinition in _definitions.values():
		result.append(definition)
	return result


func _collect_definitions(
	directory_path: String,
	output: Array[BaseDefinition],
	errors: PackedStringArray
) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		errors.append("cannot open data directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if not entry_name.begins_with("."):
			var entry_path := directory_path.path_join(entry_name)
			if directory.current_is_dir():
				_collect_definitions(entry_path, output, errors)
			elif entry_name.get_extension().to_lower() == "tres":
				var resource := ResourceLoader.load(entry_path)
				if resource == null:
					errors.append("failed to load Resource: %s" % entry_path)
				elif resource is BaseDefinition:
					output.append(resource as BaseDefinition)
				else:
					errors.append("Resource does not extend BaseDefinition: %s" % entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()

