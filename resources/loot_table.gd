class_name LootTable
extends Resource

@export_group("Base Weights")
@export var base_slot_weight: float = 0.60
@export var base_stat_weight: float = 0.30
@export var base_char_weight: float = 0.10

@export_group("Pools")
@export var available_characters: Array[CharacterData] = []
@export var stat_pool: Array[StatBlock] = []

func generate_upgrades(party: PartyManager) -> Array[UpgradeData]:
	# 1. Identify "Legal Slots" (Slots that are not yet maxed out on at least one character)
	var legal_slots: Array[String] = _get_legal_slots(party)
	
	# 2. Identify "Available Characters"
	var unowned_chars = _get_unowned_characters(party)
	
	# 3. Adjust Weights based on availability
	var current_slot_weight = base_slot_weight if not legal_slots.is_empty() else 0.0
	var current_char_weight = base_char_weight if (party.roster.size() < 3 and not unowned_chars.is_empty()) else 0.0
	var current_stat_weight = base_stat_weight # Stats are usually always legal
	
	# 4. Normalize Weights
	var total_weight = current_slot_weight + current_stat_weight + current_char_weight
	if total_weight <= 0.0:
		current_stat_weight = 1.0
		total_weight = 1.0
		
	var w_slot = current_slot_weight / total_weight
	var w_stat = current_stat_weight / total_weight
	var w_char = current_char_weight / total_weight
	
	# 5. Generate 3 Guaranteed-Applicable Cards
	var drops: Array[UpgradeData] = []
	for i in 3:
		drops.append(_roll_single_card(w_slot, w_stat, w_char, legal_slots, unowned_chars))
		
	return drops

func _roll_single_card(w_slot: float, w_stat: float, w_char: float, legal_slots: Array[String], unowned: Array[CharacterData]) -> UpgradeData:
	var roll = randf()
	var card = UpgradeData.new()
	
	# Check Slot Upgrade (Only if legal slots exist)
	if roll < w_slot:
		card.upgrade_type = UpgradeData.UpgradeType.SLOT_UPGRADE
		# GUARANTEE: Only pick from slots that at least one character can actually use
		card.target_slot = legal_slots.pick_random()
		card.display_name = "Upgrade: " + card.target_slot.replace("_", " ").capitalize()
		card.description = "Unlocks or enhances the " + card.target_slot.replace("_", " ") + " ability for a character."
		
	# Check Stat Upgrade
	elif roll < w_slot + w_stat:
		card.upgrade_type = UpgradeData.UpgradeType.CHAR_STAT
		if not stat_pool.is_empty():
			card.stat_modifier = stat_pool.pick_random()
			card.display_name = "Stat Enhancement"
			card.description = "Permanently boosts a character's efficiency."
		else:
			card.stat_modifier = StatBlock.new() # Default fallback
			card.display_name = "Minor Buff"
			
	# Check Character Unlock
	else:
		card.upgrade_type = UpgradeData.UpgradeType.CHAR_UNLOCK
		card.character_data = unowned.pick_random()
		card.display_name = "Unlock: " + card.character_data.character_name
		card.description = "Recruit this hero to your party!"
		
	return card

# --- SCANNING HELPERS ---

func _get_legal_slots(party: PartyManager) -> Array[String]:
	var legal: Array[String] = []
	var all_possible_slots = ["left_tap", "left_hold", "right_tap", "right_hold"]
	
	for slot_name in all_possible_slots:
		for cnode in party.roster:
			var tiers: Array = cnode.data.get(slot_name + "_tiers")
			var current_lvl: int = cnode.slot_levels.get(slot_name, 0)
			
			# If even ONE character can upgrade this slot, it's a legal card to roll
			if current_lvl < tiers.size():
				if slot_name not in legal:
					legal.append(slot_name)
				break # Move to next slot type
	return legal

func _get_unowned_characters(party: PartyManager) -> Array[CharacterData]:
	var unowned: Array[CharacterData] = []
	for c in available_characters:
		var owned = false
		for p_node in party.roster:
			if p_node.data.character_name == c.character_name:
				owned = true
				break
		if not owned:
			unowned.append(c)
	return unowned
