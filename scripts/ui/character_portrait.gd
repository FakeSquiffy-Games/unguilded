class_name CharacterPortrait
extends PanelContainer

var character_node: CharacterNode
var party_manager: PartyManager

@onready var name_label: Label = %NameLabel
@onready var portrait_rect: TextureRect = %PortraitRect

# add these two nodes to your character_portrait.tscn
# Label with unique name "StatsLabel" under VBoxContainer
# Label with unique name "ActiveLabel" under VBoxContainer
@onready var stats_label: Label = %StatsLabel
@onready var active_label: Label = %ActiveLabel

func setup(cnode: CharacterNode, p_manager: PartyManager) -> void:
	character_node = cnode
	party_manager = p_manager
	pivot_offset = size / 2.0

	if not character_node:
		name_label.text = "Empty Slot"
		portrait_rect.texture = null
		if stats_label: stats_label.text = ""
		if active_label: active_label.text = ""
		return

	name_label.text = character_node.data.character_name

	if character_node.data.portrait:
		portrait_rect.texture = character_node.data.portrait

	_refresh_stats()
	_refresh_active()

func _process(_delta: float) -> void:
	if not character_node or not is_instance_valid(character_node): return
	_refresh_stats()
	_refresh_active()

func _refresh_stats() -> void:
	if not stats_label: return
	if not character_node or not character_node.stat_manager: return

	var sm: StatManager = character_node.stat_manager
	var spd: float = sm.final_speed
	var dmg: float = sm.final_damage_multiplier
	var cast: float = sm.final_casting_multiplier

	stats_label.text = "Dmg: %d | Spd: %.1f | Cast: %.2fx" % [dmg, spd, cast]

func _refresh_active() -> void:
	if not active_label: return
	if not party_manager: return

	var my_index: int = -1
	for i in party_manager.roster.size():
		if party_manager.roster[i] == character_node:
			my_index = i
			break

	if my_index == party_manager.active_index:
		active_label.text = "[ Active ]"
		modulate = Color.WHITE
	else:
		active_label.text = ""
		modulate = Color(0.75, 0.75, 0.75, 1.0)

# ── Drag and drop unchanged ────────────────────────────────────────────────────

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is UpgradeData: return false
	var u: UpgradeData = data

	match u.upgrade_type:
		UpgradeData.UpgradeType.CHAR_UNLOCK:
			return character_node == null
		UpgradeData.UpgradeType.CHAR_STAT:
			return character_node != null
		UpgradeData.UpgradeType.SLOT_UPGRADE:
			if character_node == null: return false
			var tiers: Array = character_node.data.get(u.target_slot + "_tiers")
			var current_lvl: int = character_node.slot_levels.get(u.target_slot, 0)
			return current_lvl < tiers.size()

	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var u: UpgradeData = data

	match u.upgrade_type:
		UpgradeData.UpgradeType.CHAR_UNLOCK:
			party_manager.add_character(u.character_data)
			print("[Progression] Unlocked Character: ", u.character_data.character_name)
		UpgradeData.UpgradeType.CHAR_STAT:
			character_node.stat_manager.add_modifier(u.stat_modifier)
			print("[Progression] Applied Stat to: ", character_node.data.character_name)
		UpgradeData.UpgradeType.SLOT_UPGRADE:
			character_node.upgrade_slot(u.target_slot)
			print("[Progression] Upgraded ", u.target_slot, " for ", character_node.data.character_name)

	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)

	Events.upgrade_applied.emit()
