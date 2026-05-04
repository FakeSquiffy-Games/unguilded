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
	# 1. Create a transparent preview that follows the mouse cursor
	var preview = Control.new()
	var preview_panel = PanelContainer.new()
	var preview_label = Label.new()
	
	preview_label.text = upgrade_data.display_name
	preview_panel.add_child(preview_label)
	preview_panel.modulate.a = 0.8
	
	# Offset so the cursor isn't blocking the top-left corner
	preview_panel.position = Vector2(-50, -20) 
	preview.add_child(preview_panel)
	
	set_drag_preview(preview)
	
	# 2. Return the actual Resource data
	return upgrade_data
