class_name HurtboxComponent
extends Area2D

signal contact_forwarded(contact: HitContact)

@export var initial_faction_id: StringName = &"enemy"
@export_range(0.0, 1000.0, 1.0, "or_greater") var initial_min_hit_height := 0.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var initial_max_hit_height := 56.0

var combatant_instance_id: int:
	get:
		return _combatant_instance_id
var faction_id: StringName:
	get:
		return _faction_id
var is_invulnerable: bool:
	get:
		return _is_invulnerable
var is_accepting_hits: bool:
	get:
		return _is_accepting_hits
var min_hit_height: float:
	get:
		return _min_hit_height
var max_hit_height: float:
	get:
		return _max_hit_height

var _resolver: HitResolverModel
var _combatant_instance_id := 0
var _faction_id: StringName = &""
var _is_invulnerable := false
var _is_accepting_hits := true
var _min_hit_height := 0.0
var _max_hit_height := 56.0
var _configured := false


func _ready() -> void:
	if not _configured:
		var default_instance_id := get_parent().get_instance_id()
		var errors := configure(
			default_instance_id,
			initial_faction_id,
			initial_min_hit_height,
			initial_max_hit_height
		)
		for message: String in errors:
			push_error("[CMB-003] %s" % message)
		if not errors.is_empty():
			_is_accepting_hits = false
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_set_detection_enabled(_is_accepting_hits)


func configure(
	new_combatant_instance_id: int,
	new_faction_id: StringName,
	new_min_hit_height: float,
	new_max_hit_height: float
) -> PackedStringArray:
	var errors := PackedStringArray()
	if new_combatant_instance_id <= 0:
		errors.append("combatant instance ID must be greater than 0")
	if not _is_supported_faction(new_faction_id):
		errors.append("hurtbox faction must be player or enemy")
	if new_min_hit_height < 0.0:
		errors.append("minimum hit height must be at least 0")
	if new_max_hit_height < new_min_hit_height:
		errors.append("maximum hit height must not be below minimum")
	if get_node_or_null("CollisionShape2D") == null:
		errors.append("HurtboxComponent requires a CollisionShape2D child")
	if not errors.is_empty():
		return errors

	_combatant_instance_id = new_combatant_instance_id
	_faction_id = new_faction_id
	_min_hit_height = new_min_hit_height
	_max_hit_height = new_max_hit_height
	_configured = true
	_apply_collision_profile()
	return errors


func bind_resolver(resolver: HitResolverModel) -> void:
	_resolver = resolver


func set_invulnerable(invulnerable: bool) -> void:
	_is_invulnerable = invulnerable


func set_accepting_hits(accepting_hits: bool) -> void:
	_is_accepting_hits = accepting_hits
	_set_detection_enabled(accepting_hits)


func set_hit_height_range(new_minimum: float, new_maximum: float) -> bool:
	if new_minimum < 0.0 or new_maximum < new_minimum:
		return false
	_min_hit_height = new_minimum
	_max_hit_height = new_maximum
	return true


func forward_contact(hitbox: HitboxComponent) -> bool:
	if (
		not _is_accepting_hits
		or _resolver == null
		or hitbox == null
		or not hitbox.contact_enabled
	):
		return false
	var contact := hitbox.build_contact(
		_combatant_instance_id,
		_faction_id,
		_is_invulnerable,
		_min_hit_height,
		_max_hit_height
	)
	if contact == null:
		return false
	contact_forwarded.emit(contact)
	return _resolver.try_accept(contact)


func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as HitboxComponent
	if hitbox != null:
		forward_contact(hitbox)


func _apply_collision_profile() -> void:
	if _faction_id == &"player":
		collision_layer = 1 << 5
		collision_mask = 1 << 4
	else:
		collision_layer = 1 << 6
		collision_mask = 1 << 3


func _set_detection_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not enabled)
	var debug_shape := get_node_or_null("DebugShape") as Polygon2D
	if debug_shape != null:
		debug_shape.visible = enabled and OS.is_debug_build()


func _is_supported_faction(faction: StringName) -> bool:
	return faction == &"player" or faction == &"enemy"
