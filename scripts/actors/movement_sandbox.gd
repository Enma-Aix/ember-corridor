extends Node2D

@onready var player: PlayerGroundMovementController = %PlayerRoot
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var movement_label: Label = %MovementLabel


func _ready() -> void:
	debug_panel.visible = OS.is_debug_build()
	GameLog.info(&"MovementSandbox", "MOV-001 sandbox ready")


func _process(_delta: float) -> void:
	if not debug_panel.visible:
		return
	var facing_label := "right" if player.facing_sign() > 0 else "left"
	movement_label.text = (
		"Position: (%.1f, %.1f)\nVelocity: (%.1f, %.1f)\nFacing: %s"
		% [
			player.global_position.x,
			player.global_position.y,
			player.velocity.x,
			player.velocity.y,
			facing_label,
		]
	)
