class_name LootTable
extends Resource

@export_group("Base Weights")
@export var base_slot_weight: float = 0.60
@export var base_stat_weight: float = 0.30
@export var base_char_weight: float = 0.10

@export_group("Pools")
@export var available_characters: Array[CharacterData] =[]
@export var stat_pool: Array[StatBlock] = []

func generate_upgrades(party: PartyManager) -> Array[UpgradeData]:
	var current_slot_weight = base_slot_weight
	var current_stat_weight = base_stat_weight
	var current_char_weight = base_char_weight
	
	# Rule 1: Character Cap Check
	var unowned_chars = _get_unowned_characters(party)
	if party.roster.size() >= 3 or unowned_chars.is_empty():
		current_char_weight = 0.0
		
	# Rule 2: Skill Cap Check
	if _are_all_skills_maxed(party):
		current_slot_weight = 0.0
		
	# Normalize Weights
	var total_weight = current_slot_weight + current_stat_weight + current_char_weight
	if total_weight <= 0.0:
		current_stat_weight = 1.0 # Absolute fallback
		total_weight = 1.0
		
	var w_slot = current_slot_weight / total_weight
	var w_stat = current_stat_weight / total_weight
	var w_char = current_char_weight / total_weight
	
	var drops: Array[UpgradeData] =[]
	for i in 3:
		drops.append(_roll_single_card(w_slot, w_stat, w_char, unowned_chars))
		
	return drops

func _roll_single_card(w_slot: float, w_stat: float, w_char: float, unowned: Array[CharacterData]) -> UpgradeData:
	var roll = randf()
	var card = UpgradeData.new()
	
	if roll < w_slot:
		# SLOT UPGRADE
		var slots =["left_tap", "left_hold", "right_tap", "right_hold"]
		card.upgrade_type = UpgradeData.UpgradeType.SLOT_UPGRADE
		card.target_slot = slots.pick_random()
		card.display_name = "Skill Upgrade"
		card.description = "Unlocks or Upgrades: " + card.target_slot.capitalize()
		
	elif roll < w_slot + w_stat:
		# STAT UPGRADE
		card.upgrade_type = UpgradeData.UpgradeType.CHAR_STAT
		if not stat_pool.is_empty():
			card.stat_modifier = stat_pool.pick_random()
			card.display_name = "Stat Buff"
			card.description = "Enhances character statistics."
		else:
			# Procedural fallback
			card.stat_modifier = StatBlock.new()
			card.stat_modifier.max_health = 10
			card.display_name = "Minor Health Potion"
			card.description = "+10 Max Health"
			
	else:
		# CHARACTER UNLOCK
		card.upgrade_type = UpgradeData.UpgradeType.CHAR_UNLOCK
		card.character_data = unowned.pick_random()
		card.display_name = "New Hero: " + card.character_data.character_name
		card.description = "Drag to an empty slot to recruit!"
		
	return card

# --- HELPERS ---

func _get_unowned_characters(party: PartyManager) -> Array[CharacterData]:
	var unowned: Array[CharacterData] =[]
	for c in available_characters:
		var owns = false
		for p_node in party.roster:
			if p_node.data.character_name == c.character_name: owns = true
		if not owns: unowned.append(c)
	return unowned

func _are_all_skills_maxed(party: PartyManager) -> bool:
	for cnode in party.roster:
		for slot in["left_tap", "left_hold", "right_tap", "right_hold"]:
			var tiers: Array = cnode.data.get(slot + "_tiers")
			if cnode.slot_levels[slot] < tiers.size():
				return false # Found at least one upgradable slot
	return true
