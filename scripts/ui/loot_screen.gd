class_name LootScreen
extends CanvasLayer

@onready var cards_container: HBoxContainer = %CardsContainer
@onready var roster_container: HBoxContainer = %RosterContainer

var upgrade_card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
var portrait_scene: PackedScene = preload("res://scenes/ui/character_portrait.tscn")

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when tree is paused
	
	Events.wave_cleared.connect(_on_wave_cleared)
	Events.upgrade_applied.connect(_on_upgrade_applied)

func _on_wave_cleared(_wave: int) -> void:
	get_tree().paused = true # Freeze the background gameplay
	_generate_mock_upgrades()
	_populate_roster()
	show()

func _on_upgrade_applied() -> void:
	hide()
	get_tree().paused = false
	Events.resume_wave_sequence.emit()

func _generate_mock_upgrades() -> void:
	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()
		
	# Procedurally generate 3 random Stat Buffs for now
	for i in 3:
		var u_data = UpgradeData.new()
		u_data.upgrade_type = UpgradeData.UpgradeType.CHAR_STAT
		u_data.stat_modifier = StatBlock.new()
		
		# Randomize the buff
		var roll = randi() % 3
		if roll == 0:
			u_data.display_name = "Health Potion"
			u_data.description = "+20 Max Health"
			u_data.stat_modifier.max_health = 20
		elif roll == 1:
			u_data.display_name = "Swift Boots"
			u_data.description = "+50 Move Speed"
			u_data.stat_modifier.move_speed = 50.0
		else:
			u_data.display_name = "Arcane Focus"
			u_data.description = "+20% Cast Speed"
			u_data.stat_modifier.casting_multiplier = 0.2
			
		var card = upgrade_card_scene.instantiate() as UpgradeCard
		cards_container.add_child(card)
		card.setup(u_data)

func _populate_roster() -> void:
	# Clear old portraits
	for child in roster_container.get_children():
		child.queue_free()
		
	# Grab the active PartyManager from the Player
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_node("PartyManager"): return
	
	var party: PartyManager = player.get_node("PartyManager")
	for cnode in party.roster:
		var portrait = portrait_scene.instantiate() as CharacterPortrait
		roster_container.add_child(portrait)
		portrait.setup(cnode)
