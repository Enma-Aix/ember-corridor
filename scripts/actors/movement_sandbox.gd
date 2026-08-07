extends Node2D

@onready var player: PlayerGroundMovementController = %PlayerRoot
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var movement_label: Label = %MovementLabel

var elevation_component: ElevationComponent


func _ready() -> void:
	elevation_component = player.get_node("Elevation") as ElevationComponent
	debug_panel.visible = OS.is_debug_build()
	GameLog.info(&"MovementSandbox", "MOV-001 sandbox ready")
	GameLog.info(&"ElevationSandbox", "MOV-002 sandbox ready")
	GameLog.info(&"DodgeSandbox", "MOV-003 sandbox ready")


func _process(_delta: float) -> void:
	if not debug_panel.visible:
		return
	var facing_label := "right" if player.facing_sign() > 0 else "left"
	var hit_range := elevation_component.hit_height_range()
	var low_probe_overlap := elevation_component.overlaps_height_range(0.0, 24.0)
	var debug_text := (
		"Ground: (%.1f, %.1f)\n"
		+ "Move velocity: (%.1f, %.1f)\n"
		+ "Facing: %s\n"
		+ "Elevation: %.1f\n"
		+ "Vertical velocity: %.1f\n"
		+ "Grounded: %s\n"
		+ "Hit height: %.1f - %.1f\n"
		+ "Low probe 0-24: %s\n"
		+ "Dodge: %s · tick %d\n"
		+ "Invulnerable: %s\n"
		+ "Dodge cooldown: %d\n"
		+ "Dodge direction: (%.2f, %.2f)"
	)
	movement_label.text = debug_text % [
		player.global_position.x,
		player.global_position.y,
		player.velocity.x,
		player.velocity.y,
		facing_label,
		elevation_component.elevation(),
		elevation_component.vertical_velocity(),
		str(elevation_component.is_grounded()),
		hit_range.x,
		hit_range.y,
		"overlap" if low_probe_overlap else "clear",
		"active" if player.is_dodging() else "idle",
		player.dodge_tick(),
		str(player.is_dodge_invulnerable()),
		player.dodge_cooldown_ticks(),
		player.dodge_direction().x,
		player.dodge_direction().y,
	]
