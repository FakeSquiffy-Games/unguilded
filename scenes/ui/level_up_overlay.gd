extends CanvasLayer

@onready var offer_container: VBoxContainer = $Panel/VBoxContainer/OfferContainer
@export var offers_per_level: int = 3

var _player: Player

func _ready() -> void:
	hide()
	SignalBus.level_up.connect(_on_level_up)

func _on_level_up(_level: int) -> void:
	_player = get_tree().get_first_node_in_group("player")
	get_tree().paused = true
	_populate_offers()
	show()

func _populate_offers() -> void:
	for child in offer_container.get_children():
		child.queue_free()
	var pool := SpellRegistry.get_random_offers(offers_per_level)
	for offer: KeyEntity in pool:
		var btn := Button.new()
		btn.text = "[%s]  %s  (%d mana)" % [
			OS.get_keycode_string(offer.key),
			offer.spell.display_name,
			offer.spell.mana_cost
		]
		btn.pressed.connect(_on_offer_chosen.bind(offer))
		offer_container.add_child(btn)

func _on_offer_chosen(entity: KeyEntity) -> void:
	KeyManager.register(entity)
	hide()
	get_tree().paused = false
