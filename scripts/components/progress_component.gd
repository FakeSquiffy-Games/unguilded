class_name ProgressionComponent
extends Node

var owned_weapons: Array[WeaponResource] =[]
var unlocked_slots: Dictionary = {} # Format: { "weapon_id": ["left_tap", "left_hold"] }

func add_weapon(weapon: WeaponResource) -> void:
	if weapon not in owned_weapons:
		owned_weapons.append(weapon)
		if not unlocked_slots.has(weapon.weapon_id):
			# Starting out, weapons only have their left_tap unlocked
			unlocked_slots[weapon.weapon_id] = ["left_tap"]
		Events.weapon_acquired.emit(weapon)

func unlock_slot(weapon_id: StringName, slot_name: String) -> void:
	if not unlocked_slots.has(weapon_id):
		unlocked_slots[weapon_id] = []
	if slot_name not in unlocked_slots[weapon_id]:
		unlocked_slots[weapon_id].append(slot_name)
		print("Unlocked slot: ", slot_name, " for ", weapon_id)

func has_slot_unlocked(weapon: WeaponResource, slot_name: String) -> bool:
	if not weapon: return false
	if not unlocked_slots.has(weapon.weapon_id): return false
	return slot_name in unlocked_slots[weapon.weapon_id]
