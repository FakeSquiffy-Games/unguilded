class_name ProgressionComponent
extends Node

var owned_characters: Array[CharacterData] =[]
var unlocked_slots: Dictionary = {}

func add_character(character: CharacterData) -> void:
	if character not in owned_characters:
		owned_characters.append(character)
		if not unlocked_slots.has(character.character_name):
			# Starting out, characters only have their left_tap unlocked
			unlocked_slots[character.character_name] = ["left_tap"]
		Events.character_acquired.emit(character)

func unlock_slot(character_name: StringName, slot_name: String) -> void:
	if not unlocked_slots.has(character_name):
		unlocked_slots[character_name] = []
	if slot_name not in unlocked_slots[character_name]:
		unlocked_slots[character_name].append(slot_name)
		print("Unlocked slot: ", slot_name, " for ", character_name)

func has_slot_unlocked(character: CharacterData, slot_name: String) -> bool:
	if not character: return false
	if not unlocked_slots.has(character.character_name): return false
	return slot_name in unlocked_slots[character.character_name]
