class_name PartyManager
extends Node

signal character_switched(active_node: CharacterNode)

var roster: Array[CharacterNode] =[]
var active_index: int = 0

@onready var player: Node2D = owner

func _process(delta: float) -> void:
	# Process all characters in the background (cooldowns & energy)
	for cnode in roster:
		cnode.process_background(delta)

func add_character(data: CharacterData) -> void:
	if roster.size() >= 3: return
	
	var cnode = CharacterNode.new()
	cnode.name = "Character_" + String(data.character_name)
	add_child(cnode)
	cnode.setup(data, player)
	roster.append(cnode)
	
	if roster.size() == 1:
		switch_character(0)

func switch_character(index: int) -> void:
	if index < 0 or index >= roster.size(): return
	active_index = index
	character_switched.emit(roster[active_index])

func get_active() -> CharacterNode:
	if roster.is_empty(): return null
	return roster[active_index]
