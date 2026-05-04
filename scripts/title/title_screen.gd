# TitleScreen.gd
extends Node2D

@onready var top_image    		= $TopImage
@onready var bottom_image 		= $BottomImage
@onready var transition_anim    = $TransitionLayer/AnimationPlayer
@onready var intro_anim    		= $BackgroundLayers/AnimationPlayer
@onready var white_flash  		= $TransitionLayer/ImpactFrames/WhiteFlash
@onready var black_flash  		= $TransitionLayer/ImpactFrames/BlackFlash

# Preload so there's zero stall when we swap
var game_scene = preload("res://scenes/arena/arena.tscn")

var transitioning = false

func _ready():
	top_image.visible    = false
	bottom_image.visible = false
	white_flash.visible  = false
	black_flash.visible  = false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and not transitioning:
		transitioning = true
		_start_transition()

# TitleScreen.gd
func _start_transition():
	# 1. Impact frames
	transition_anim.play("impact")
	await transition_anim.animation_finished

	# 2. Show halves and move them to the autoload
	top_image.visible = true
	bottom_image.visible = true
	TransitionHolder.hold(top_image, bottom_image)

	# 3. Tell the autoload to handle everything from here
	#    then immediately change scene — this script dies here, that's fine
	TransitionHolder.finish_transition(game_scene)

	# 4. Fly apart (now running from TransitionHolder's context)
	var vp_height = DisplayServer.window_get_size().y
	var top  = TransitionHolder.top_node
	var bot  = TransitionHolder.bot_node

	var tween = TransitionHolder.create_tween().set_parallel(true)

	tween.tween_property(top, "position:y", top.position.y - vp_height, 0.5) \
		 .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	tween.tween_property(bot, "position:y", bot.position.y + vp_height, 0.5) \
		 .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await tween.finished

	# 5. Clean up the autoload nodes
	TransitionHolder.release()
