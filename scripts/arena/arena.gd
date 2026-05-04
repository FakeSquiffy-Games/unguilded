class_name Arena
extends Node2D

var player_scene: PackedScene = preload("res://scenes/entities/player/player.tscn")
var player_instance

func _ready() -> void:
	_spawn_player()
	AudioManager.play_ui_sound("battle_music")

func _spawn_player() -> void:
	player_instance = player_scene.instantiate() as Actor
	player_instance.global_position = Vector2.ZERO 
	player_instance.add_to_group("player") # Ensure group is set for EnemyBrain
	add_child(player_instance)
