class_name CharacterPortrait
extends PanelContainer

var character_node: CharacterNode

@onready var name_label: Label = %NameLabel
@onready var portrait_rect: TextureRect = %PortraitRect

func setup(node: CharacterNode) -> void:
	character_node = node
	name_label.text = node.data.character_name
	
	# Extract the first frame of the idle animation to use as a portrait
	if node.data.sprite_frames and node.data.sprite_frames.has_animation("idle"):
		portrait_rect.texture = node.data.sprite_frames.get_frame_texture("idle", 0)

# --- GODOT NATIVE DRAG & DROP API ---

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only accept drops if the data is a dictionary marked as an "upgrade"
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "upgrade"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var upgrade: UpgradeData = data["upgrade"]
	_apply_upgrade(upgrade)
	
	# Visual feedback: Bounce the portrait
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Tell the system we are done!
	Events.upgrade_applied.emit()

func _apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.upgrade_type == UpgradeData.UpgradeType.CHAR_STAT:
		character_node.stat_manager.add_modifier(upgrade.stat_modifier)
	
	print("[Progression] Applied ", upgrade.display_name, " to ", character_node.data.character_name)
