#@ascii_only
extends CanvasLayer
# Autload for Transition handler

var top_node: Node = null
var bot_node: Node = null

func hold(top: Node, bot: Node):
	top_node = top
	bot_node = bot
	top.reparent(self)
	bot.reparent(self)

func finish_transition(scene: PackedScene):
	get_tree().change_scene_to_packed(scene)
	# Now we wait a frame from HERE — the autoload is still alive
	await get_tree().process_frame
	_fly_apart()

func _fly_apart():
	var vp_height = get_viewport().size.y

	var tween = create_tween().set_parallel(true)

	tween.tween_property(top_node, "position:y", top_node.position.y - vp_height, 0.5) \
		 .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	tween.tween_property(bot_node, "position:y", bot_node.position.y + vp_height, 0.5) \
		 .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await tween.finished
	release()

func release():
	if top_node: top_node.queue_free()
	if bot_node: bot_node.queue_free()
	top_node = null
	bot_node = null
