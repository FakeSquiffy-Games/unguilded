class_name LootScreen
extends CanvasLayer

@export var loot_table: LootTable # Assign this in the Editor!

@onready var cards_container: VBoxContainer = %CardsContainer
@onready var roster_container: VBoxContainer = %RosterContainer
@onready var book_contents: HBoxContainer = $ContentContainer

@onready var open_book_anim: AnimationPlayer = $AnimationPlayer
@onready var ink_mask: ColorRect = $InkMask

var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
var portrait_scene: PackedScene = preload("res://scenes/ui/character_portrait.tscn")

func _ready() -> void:
	hide()
	ink_mask.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Crucial: This UI must run while the game is paused
	Events.wave_cleared.connect(_on_wave_cleared)
	Events.upgrade_applied.connect(_on_upgrade_applied)

func _on_wave_cleared(_wave: int) -> void:
	if not loot_table:
		push_error("LootScreen: LootTable not assigned!")
		Events.resume_wave_sequence.emit()
		return

	get_tree().paused = true

	var player = get_tree().get_first_node_in_group("player")
	var party: PartyManager = player.get_node("PartyManager") if player else null
	if not party: return

	_populate_roster(party)
	_generate_cards(party)
	
	book_contents.modulate.a = 0.0

	show()
	open_book_anim.play("open_book")
	await open_book_anim.animation_finished
	_play_ink_reveal()

func _on_upgrade_applied() -> void:
	ink_mask.hide()
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

func _play_ink_reveal() -> void:
	book_contents.modulate.a = 0.0

	await get_tree().process_frame

	var tween = create_tween()
	tween.tween_property(book_contents, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
