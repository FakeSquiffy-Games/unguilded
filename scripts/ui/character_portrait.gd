class_name CharacterPortrait
extends PanelContainer

var character_node: CharacterNode
var party_manager: PartyManager

@onready var name_label: Label = %NameLabel
@onready var portrait_rect: TextureRect = %PortraitRect

func setup(cnode: CharacterNode, p_manager: PartyManager) -> void:
	character_node = cnode
	party_manager = p_manager
	
	# Adjust pivot for the scale tween bounce
	pivot_offset = size / 2.0 
	
	if character_node:
		name_label.text = character_node.data.character_name
		if character_node.data.sprite_frames and character_node.data.sprite_frames.has_animation("idle"):
			portrait_rect.texture = character_node.data.sprite_frames.get_frame_texture("idle", 0)
	else:
		name_label.text = "Empty Slot"
		portrait_rect.texture = null # You can set a placeholder silhouette texture here in the editor

# --- GODOT NATIVE DRAG & DROP API ---

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is UpgradeData: return false
	var u: UpgradeData = data
	
	match u.upgrade_type:
		UpgradeData.UpgradeType.CHAR_UNLOCK:
			return character_node == null # Only empty slots!
			
		UpgradeData.UpgradeType.CHAR_STAT:
			return character_node != null # Any active character
			
		UpgradeData.UpgradeType.SLOT_UPGRADE:
			if character_node == null: return false
			# Verify they haven't maxed this specific skill out yet
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
	
	# Visual feedback: Juice bounce
	var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	Events.upgrade_applied.emit()
