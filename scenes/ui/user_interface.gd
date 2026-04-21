extends CanvasLayer

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var mana_bar: ProgressBar = $VBoxContainer/ManaBar
@onready var wand_label: Label = $VBoxContainer/WandLabel
@onready var chain_label: Label = $VBoxContainer/ChainLabel
@onready var key_strip: HBoxContainer = $VBoxContainer/KeyStrip
@onready var level_up_btn: Button = $VBoxContainer/LevelUpButton

func _ready() -> void:
	SignalBus.hp_changed.connect(_on_hp_changed)
	SignalBus.mana_changed.connect(_on_mana_changed)
	SignalBus.wand_spell_changed.connect(_on_wand_changed)
	SignalBus.chain_buffer_changed.connect(_on_chain_changed)
	SignalBus.key_registered.connect(_on_key_registered)
	SignalBus.key_locked.connect(_on_key_locked)
	SignalBus.key_press_count_changed.connect(_on_key_press_count_changed)
	level_up_btn.pressed.connect(_on_level_up_pressed)
	wand_label.text = "Wand: Default"
	chain_label.text = ""

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.value = (current / maximum) * 100.0

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.value = (current / maximum) * 100.0

func _on_wand_changed(spell: SpellData) -> void:
	wand_label.text = "Wand: " + ("Default" if spell == null else spell.display_name)

func _on_chain_changed(buffer: Array) -> void:
	if buffer.is_empty():
		chain_label.text = ""
		return
	var parts: Array = buffer.map(
		func(k): return OS.get_keycode_string(k))
	chain_label.text = " → ".join(parts) + " → ?"

func _on_key_registered(entity: KeyEntity) -> void:
	var badge := _make_badge(entity)
	key_strip.add_child(badge)

func _on_key_locked(entity: KeyEntity) -> void:
	var badge := _find_badge(entity.key)
	if badge:
		badge.modulate = Color(0.4, 0.4, 0.4)

func _on_key_press_count_changed(entity: KeyEntity) -> void:
	var badge := _find_badge(entity.key)
	if badge:
		badge.get_node("CountLabel").text = str(entity.press_count)

func _on_level_up_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.level_up()

func _make_badge(entity: KeyEntity) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_meta("key", entity.key)
	var vbox := VBoxContainer.new()
	var key_lbl := Label.new()
	key_lbl.text = OS.get_keycode_string(entity.key)
	var spell_lbl := Label.new()
	spell_lbl.text = entity.spell.display_name
	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = "0"
	vbox.add_child(key_lbl)
	vbox.add_child(spell_lbl)
	vbox.add_child(count_lbl)
	panel.add_child(vbox)
	return panel

func _find_badge(key: Key) -> PanelContainer:
	for child in key_strip.get_children():
		if child.get_meta("key", KEY_NONE) == key:
			return child
	return null
