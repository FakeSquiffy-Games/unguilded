class_name LootScreen
extends CanvasLayer

@export var loot_table: LootTable # Assign this in the Editor!

@onready var cards_container: HBoxContainer = %CardsContainer
@onready var roster_container: HBoxContainer = %RosterContainer

var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
var portrait_scene: PackedScene = preload("res://scenes/ui/character_portrait.tscn")

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Crucial: This UI must run while the game is paused
	
	Events.wave_cleared.connect(_on_wave_cleared)
	Events.upgrade_applied.connect(_on_upgrade_applied)

func _on_wave_cleared(_wave: int) -> void:
	if not loot_table:
		push_error("LootScreen: LootTable resource not assigned in inspector!")
		Events.resume_wave_sequence.emit()
		return
		
	get_tree().paused = true 
	
	var player = get_tree().get_first_node_in_group("player")
	var party: PartyManager = player.get_node("PartyManager") if player else null
	if not party: return
	
	_populate_roster(party)
	_generate_cards(party)
	show()

func _on_upgrade_applied() -> void:
	hide()
	get_tree().paused = false
	Events.resume_wave_sequence.emit()

func _generate_cards(party: PartyManager) -> void:
	for child in cards_container.get_children():
		child.queue_free()
		
	var drops = loot_table.generate_upgrades(party)
	for u_data in drops:
		var card = card_scene.instantiate() as UpgradeCard
		cards_container.add_child(card)
		card.setup(u_data)

func _populate_roster(party: PartyManager) -> void:
	for child in roster_container.get_children():
		child.queue_free()
		
	# The HUD always shows exactly 3 slots, regardless of party size
	for i in 3:
		var portrait = portrait_scene.instantiate() as CharacterPortrait
		roster_container.add_child(portrait)
		
		var cnode: CharacterNode = null
		if i < party.roster.size():
			cnode = party.roster[i]
			
		portrait.setup(cnode, party)
