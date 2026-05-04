# TitleScreen.gd
extends Node2D

@onready var top_image    		= $TopImage
@onready var bottom_image 		= $BottomImage

@onready var intro_anim    		= $BackgroundLayers/AnimationPlayer
@onready var label    			= $BackgroundLayers/Press

@onready var transition_anim    = $TransitionLayer/AnimationPlayer
@onready var frame_one  		= $TransitionLayer/ImpactFrames/Layer
@onready var frame_two  		= $TransitionLayer/ImpactFrames/Layer2
@onready var frame_three  		= $TransitionLayer/ImpactFrames/Layer3
@onready var frame_four  		= $TransitionLayer/ImpactFrames/Layer4
@onready var frame_five  		= $TransitionLayer/ImpactFrames/Layer5


# Preload so there's zero stall when we swap
var game_scene = preload("res://scenes/arena/arena.tscn")

var transitioning = false

func _ready():
	top_image.visible    = false
	bottom_image.visible = false
	frame_one.visible = false
	frame_two.visible = false
	frame_three.visible = false
	frame_four.visible = false
	frame_five.visible = false

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and not transitioning:
		transitioning = true
		if intro_anim.is_playing():
			var anim = intro_anim.get_animation(intro_anim.current_animation)
			anim.loop_mode = Animation.LOOP_NONE 
			await intro_anim.animation_finished
		intro_anim.play("intro")
		await intro_anim.animation_finished
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
