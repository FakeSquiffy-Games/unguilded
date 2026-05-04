class_name Arena
extends Node2D

var player_scene: PackedScene = preload("res://scenes/entities/player/player.tscn")
var player_instance

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	player_instance = player_scene.instantiate() as Actor
	# Spawn in the exact center of the arena
	player_instance.global_position = Vector2.ZERO 
	add_child(player_instance)
	
	# The PhantomCamera2D on the player will automatically detect the MainCamera's 
	# PhantomCameraHost and take control of it smoothly.
