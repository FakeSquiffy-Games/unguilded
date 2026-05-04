class_name UpgradeCard
extends PanelContainer

var upgrade_data: UpgradeData

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel

func setup(data: UpgradeData) -> void:
	upgrade_data = data
	title_label.text = data.display_name
	desc_label.text = data.description

# --- GODOT NATIVE DRAG & DROP API ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	# 1. Create a visual preview that follows the mouse
	var preview = Control.new()
	var preview_panel = PanelContainer.new()
	var preview_label = Label.new()
	
	preview_label.text = upgrade_data.display_name
	preview_panel.add_child(preview_label)
	preview_panel.modulate.a = 0.7 # Make it slightly transparent
	
	# Offset the preview so the mouse is centered on it
	preview_panel.position = Vector2(-50, -20) 
	preview.add_child(preview_panel)
	
	set_drag_preview(preview)
	
	# 2. Return the actual data package
	return { "type": "upgrade", "upgrade": upgrade_data }
