class_name DamageResolverModel
extends RefCounted

const HitResultScript := preload("res://scripts/combat/hit_result.gd")

const DEFAULT_CRIT_CHANCE := 0.05
const MAX_CRIT_CHANCE := 0.60
const DEFAULT_CRIT_DAMAGE_MULTIPLIER := 1.5

const REJECTION_INVALID_PACKET := &"invalid_packet"
const REJECTION_INVALID_DEFENSE := &"invalid_defense"
const REJECTION_INVALID_MODIFIER := &"invalid_damage_modifier"
const REJECTION_NON_FINITE_RESULT := &"non_finite_result"


func resolve(
	packet: DamagePacket,
	target_defense: float,
	damage_modifiers: PackedFloat64Array = PackedFloat64Array([1.0])
) -> HitResult:
	if packet == null or not packet.validation_errors().is_empty():
		return HitResultScript.rejected(REJECTION_INVALID_PACKET)
	if not _is_finite(target_defense):
		return HitResultScript.rejected(REJECTION_INVALID_DEFENSE)

	var combined_modifier := 1.0
	for modifier: float in damage_modifiers:
		if not _is_finite(modifier) or modifier < 0.0:
			return HitResultScript.rejected(REJECTION_INVALID_MODIFIER)
		combined_modifier *= modifier
		if not _is_finite(combined_modifier):
			return HitResultScript.rejected(REJECTION_NON_FINITE_RESULT)

	var raw_damage := packet.base_attack * packet.coefficient + packet.flat_damage
	var defense_multiplier := 100.0 / (100.0 + maxf(0.0, target_defense))
	var effective_crit_chance := minf(packet.crit_chance, MAX_CRIT_CHANCE)
	var is_critical := packet.critical_roll < effective_crit_chance
	var critical_multiplier := packet.crit_damage_multiplier if is_critical else 1.0
	var resolved_damage := (
		raw_damage
		* defense_multiplier
		* combined_modifier
		* critical_multiplier
	)
	if not _is_finite(raw_damage) or not _is_finite(resolved_damage):
		return HitResultScript.rejected(REJECTION_NON_FINITE_RESULT)

	return HitResultScript.new(
		true,
		&"",
		raw_damage,
		defense_multiplier,
		combined_modifier,
		effective_crit_chance,
		roundi(maxf(1.0, resolved_damage)),
		is_critical,
		packet.poise_damage,
		false,
		&"none",
		Vector2.ZERO,
		packet.hit_stop_ticks,
		packet.feedback_strength
	)


func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
