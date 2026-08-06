extends Node


func set_bus_volume_linear(bus_name: StringName, value: float) -> bool:
	var bus_index := AudioServer.get_bus_index(String(bus_name))
	if bus_index < 0:
		GameLog.warning(&"AudioService", "Unknown audio bus: %s" % String(bus_name))
		return false
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(value, 0.0, 1.0)))
	return true


func set_bus_muted(bus_name: StringName, muted: bool) -> bool:
	var bus_index := AudioServer.get_bus_index(String(bus_name))
	if bus_index < 0:
		GameLog.warning(&"AudioService", "Unknown audio bus: %s" % String(bus_name))
		return false
	AudioServer.set_bus_mute(bus_index, muted)
	return true

