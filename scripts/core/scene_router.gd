extends Node

const FALLBACK_SCENE := "res://scenes/boot/boot.tscn"


func go_to(scene_path: String) -> bool:
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		App.report_error(&"SceneRouter", "Scene does not exist: %s" % scene_path)
		return false
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		App.report_error(
			&"SceneRouter",
			"Failed to change scene to %s (error %d)" % [scene_path, result]
		)
		return false
	return true


func return_to_safe_scene() -> bool:
	return go_to(FALLBACK_SCENE)

