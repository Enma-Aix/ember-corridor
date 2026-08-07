class_name BaseDefinition
extends Resource

const ID_PATTERN := "^[a-z][a-z0-9]*(\\.[a-z0-9_]+)+$"

@export_category("Identity")
@export var definition_id: StringName = &""
@export var display_name_key: StringName = &""
@export var tags: Array[StringName] = []


func definition_kind() -> StringName:
	return &"base"


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id_text := String(definition_id)
	if id_text.is_empty():
		errors.append("definition_id is required")
	else:
		var regex := RegEx.new()
		if regex.compile(ID_PATTERN) != OK or regex.search(id_text) == null:
			errors.append(
				"definition_id must use dotted lowercase form, for example character.dev_placeholder"
			)
	if String(display_name_key).is_empty():
		errors.append("display_name_key is required")
	var seen_tags: Dictionary[StringName, bool] = {}
	for tag: StringName in tags:
		if String(tag).is_empty():
			errors.append("tags cannot contain an empty value")
		elif seen_tags.has(tag):
			errors.append("duplicate tag: %s" % String(tag))
		else:
			seen_tags[tag] = true
	return errors

