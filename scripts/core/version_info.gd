class_name VersionInfo
extends RefCounted

const GAME_VERSION := "0.0.1-m0"
const SAVE_SCHEMA_VERSION := 1
const REQUIRED_GODOT_VERSION := "4.7.1"
const BUILD_CHANNEL := "foundation"


static func display_string() -> String:
	return "v%s · Godot %s · %s" % [
		GAME_VERSION,
		REQUIRED_GODOT_VERSION,
		BUILD_CHANNEL,
	]


static func is_expected_engine() -> bool:
	var version := Engine.get_version_info()
	return (
		int(version.get("major", -1)) == 4
		and int(version.get("minor", -1)) == 7
		and int(version.get("patch", -1)) == 1
	)

