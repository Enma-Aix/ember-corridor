class_name HitResolverModel
extends RefCounted

signal hit_accepted(contact: HitContact)
signal hit_rejected(contact: HitContact, reason_code: StringName)

const REJECTION_INVALID_CONTACT := &"invalid_contact"
const REJECTION_FRIENDLY_FACTION := &"friendly_faction"
const REJECTION_INVULNERABLE := &"target_invulnerable"
const REJECTION_HEIGHT_MISS := &"height_miss"
const REJECTION_DUPLICATE_HIT := &"duplicate_hit"

var accepted_count: int:
	get:
		return _accepted_count
var rejected_count: int:
	get:
		return _rejected_count
var last_rejection_code: StringName:
	get:
		return _last_rejection_code

var _last_accepted_tick: Dictionary[String, int] = {}
var _accepted_count := 0
var _rejected_count := 0
var _last_rejection_code: StringName = &""


func try_accept(contact: HitContact) -> bool:
	var rejection_code := _rejection_code_for(contact)
	if rejection_code != &"":
		_rejected_count += 1
		_last_rejection_code = rejection_code
		hit_rejected.emit(contact, rejection_code)
		return false

	_last_accepted_tick[contact.dedupe_key()] = contact.action_tick
	_accepted_count += 1
	_last_rejection_code = &""
	hit_accepted.emit(contact)
	return true


func accept_batch(contacts: Array[HitContact]) -> Array[HitContact]:
	var ordered_contacts: Array[HitContact] = contacts.duplicate()
	ordered_contacts.sort_custom(_contact_precedes)
	var accepted_contacts: Array[HitContact] = []
	for contact: HitContact in ordered_contacts:
		if try_accept(contact):
			accepted_contacts.append(contact)
	return accepted_contacts


func clear() -> void:
	_last_accepted_tick.clear()
	_accepted_count = 0
	_rejected_count = 0
	_last_rejection_code = &""


func tracked_contact_count() -> int:
	return _last_accepted_tick.size()


func _rejection_code_for(contact: HitContact) -> StringName:
	if contact == null or not contact.validation_errors().is_empty():
		return REJECTION_INVALID_CONTACT
	if contact.source_faction == contact.target_faction:
		return REJECTION_FRIENDLY_FACTION
	if contact.target_invulnerable:
		return REJECTION_INVULNERABLE
	if not contact.height_ranges_overlap():
		return REJECTION_HEIGHT_MISS

	var key := contact.dedupe_key()
	if not _last_accepted_tick.has(key):
		return &""
	var last_tick: int = _last_accepted_tick[key]
	if contact.rehit_interval_ticks == 0:
		return REJECTION_DUPLICATE_HIT
	if contact.action_tick - last_tick < contact.rehit_interval_ticks:
		return REJECTION_DUPLICATE_HIT
	return &""


func _contact_precedes(left: HitContact, right: HitContact) -> bool:
	if left == null:
		return false
	if right == null:
		return true
	if left.target_instance_id != right.target_instance_id:
		return left.target_instance_id < right.target_instance_id
	if left.source_instance_id != right.source_instance_id:
		return left.source_instance_id < right.source_instance_id
	return String(left.hit_id) < String(right.hit_id)
